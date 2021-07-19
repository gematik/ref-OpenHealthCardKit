//
//  Copyright (c) 2021 gematik GmbH
//  
//  Licensed under the Apache License, Version 2.0 (the License);
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//      http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an 'AS IS' BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import CardReaderProviderApi
import Combine
import CoreNFC
import Foundation
import HealthCardAccess
import HealthCardControl
import NFCCardReaderProvider

class NFCLoginController: LoginController {
    enum Error: Swift.Error {
        /// In case the PIN or CAN could not be constructed from input
        case invalidCanOrPinFormat
        case wrongPin(retryCount: Int)
        case signatureFailure
    }

    @Published
    private var pState: ViewState<Bool, Swift.Error> = .idle
    var state: Published<ViewState<Bool, Swift.Error>>.Publisher {
        $pState
    }

    var cancellable: AnyCancellable?

    func dismissError() {
        if pState.error != nil {
            callOnMainThread {
                self.pState = .idle
            }
        }
    }

    func login(can: String, pin: String) {
        if case .loading = pState {
            return
        }
        callOnMainThread {
            self.pState = .loading(nil)
        }

        cancellable = NFCTagReaderSession.publisher(messages: NFCTagReaderSession.Messages(
            discoveryMessage: "Please tap your eGK to your iPhone",
            connectMessage: "Connecting",
            noCardMessage: "No Card Found",
            multipleCardsMessage: "Multiple cards found",
            unsupportedCardMessage: "Unsupported card",
            connectionErrorMessage: "NFC Communication error"
        ))
            .mapError { $0 as Swift.Error }
            .flatMap { (session: NFCCardSession) -> AnyPublisher<ViewState<Bool, Swift.Error>, Swift.Error> in
                let canData: CAN
                let format2Pin: Format2Pin
                do {
                    canData = try CAN.from(Data(can.utf8))
                    format2Pin = try Format2Pin(pincode: pin)
                } catch {
                    return Fail(error: Error.invalidCanOrPinFormat as Swift.Error)
                        .eraseToAnyPublisher()
                }
                return session.card // swiftlint:disable:this trailing_closure
                    .openSecureSession(can: canData, writeTimeout: 0, readTimeout: 0)
                    .map { $0 as HealthCardType }
                    .verifyPin(pin: format2Pin, type: EgkFileSystem.Pin.mrpinHome, in: session)
                    .sign(payload: "ABC".data(using: .utf8)!) // swiftlint:disable:this force_unwrapping
                    .map { _ in return true }
                    .map(ViewState.value)
                    .handleEvents(receiveOutput: { state in
                        session.invalidateSession(with: state.value?.asPinVerifyErrorMessage)
                    })
                    .eraseToAnyPublisher()
            }
            .catch { (error: Swift.Error) in
                Just(.error(error))
            }
            .subscribe(on: DispatchQueue.global(qos: .userInteractive))
            .receive(on: DispatchQueue.main)
            .assign(to: \.pState, on: self)
    }
}

extension Publisher where Output == HealthCardType, Self.Failure == Swift.Error {
    func verifyPin(pin: Format2Pin,
                   type: EgkFileSystem.Pin,
                   in session: NFCCardSession
    ) -> AnyPublisher<HealthCardType, Swift.Error> {
        flatMap { secureCard in
            secureCard.verify(pin: pin, type: type) // swiftlint:disable:this trailing_closure
                .tryMap { response in
                    if case let VerifyPinResponse.failed(retryCount: count) = response {
                        throw NFCLoginController.Error.wrongPin(retryCount: count)
                    }
                    return secureCard
                }
                .handleEvents(receiveSubscription: { _ in
                    session.updateAlert(message: "Verifying pin...")
                })
        }.eraseToAnyPublisher()
    }

    func sign(payload: Data) -> AnyPublisher<Data, Swift.Error> {
        flatMap { secureCard -> AnyPublisher<Data, Swift.Error> in
            secureCard
                .readAutCertificate()
                .flatMap { _ -> AnyPublisher<Data, Swift.Error> in
                    // Check AutCertificateResponse here ...
                     secureCard.sign(data: payload)
                        .tryMap { response in
                            if response.responseStatus == ResponseStatus.success, let signature = response.data {
                                Swift.print("SIGNATURE: \(signature.utf8string ?? "<NO SIGNATURE>")")
                                return signature
                            } else {
                                throw NFCLoginController.Error.signatureFailure
                            }
                        }
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}

extension Bool {
    var asPinVerifyErrorMessage: String? {
        if self {
            return nil
        } else {
            return "False pincode (or blocked card)"
        }
    }
}
