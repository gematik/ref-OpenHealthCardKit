//
//  Copyright (c) 2023 gematik GmbH
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
import Helper
import NFCCardReaderProvider

public class NFCLoginController: LoginController {
    public enum Error: Swift.Error, LocalizedError {
        /// In case the PIN or CAN could not be constructed from input
        case cardError(NFCTagReaderSession.Error)
        case invalidCanOrPinFormat
        case wrongPin(retryCount: Int)
        case signatureFailure(ResponseStatus)
        case invalidAlgorithm(PSOAlgorithm)
        case passwordBlocked
        case verifyPinResponse

        public var errorDescription: String? {
            switch self {
            case let .cardError(error):
                return error.localizedDescription
            case .invalidCanOrPinFormat:
                return "invalid CAN or PIN format"
            case let .wrongPin(retryCount: retryCount):
                return "wrong pin with retry count \(retryCount)."
            case let .signatureFailure(status):
                return "signatureFailure with response status code: \(status.code)"
            case let .invalidAlgorithm(algorithm):
                return "SmartCard is not using a brainpoolP256r1 algorithm for signing. Uses: \(algorithm)"
            case .passwordBlocked:
                return "PIN usage counter exhausted"
            case .verifyPinResponse:
                return "Unexpected VerifyPinResponse"
            }
        }
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

    let messages = NFCTagReaderSession.Messages(
        discoveryMessage: NSLocalizedString("nfc_txt_discoveryMessage", comment: ""),
        connectMessage: NSLocalizedString("nfc_txt_connectMessage", comment: ""),
        noCardMessage: NSLocalizedString("nfc_txt_noCardMessage", comment: ""),
        multipleCardsMessage: NSLocalizedString("nfc_txt_multipleCardsMessage", comment: ""),
        unsupportedCardMessage: NSLocalizedString("nfc_txt_unsupportedCardMessage", comment: ""),
        connectionErrorMessage: NSLocalizedString("nfc_txt_connectionErrorMessage", comment: "")
    )

    // swiftlint:disable:next function_body_length
    func login(can: String, pin: String, checkBrainpoolAlgorithm: Bool) {
        if case .loading = pState { return }
        callOnMainThread {
            self.pState = .loading(nil)
        }
        let canData: CAN
        let format2Pin: Format2Pin
        do {
            canData = try CAN.from(Data(can.utf8))
            format2Pin = try Format2Pin(pincode: pin)
        } catch {
            callOnMainThread {
                self.pState = .error(Error.invalidCanOrPinFormat)
            }
            return
        }

        cancellable = NFCTagReaderSession.publisher(messages: messages)
            .mapError { Error.cardError($0) as Swift.Error }
            .flatMap { (session: NFCCardSession) -> AnyPublisher<ViewState<Bool, Swift.Error>, Swift.Error> in
                session.updateAlert(message: NSLocalizedString("nfc_txt_msg_secure_channel", comment: ""))
                return session.card // swiftlint:disable:this trailing_closure
                    .openSecureSession(can: canData, writeTimeout: 0, readTimeout: 0)
                    .userMessage(session: session, message: NSLocalizedString("nfc_txt_msg_verify_pin", comment: ""))
                    .verifyPin(pin: format2Pin, type: EgkFileSystem.Pin.mrpinHome, in: session)
                    .userMessage(session: session, message: NSLocalizedString("nfc_txt_msg_signing", comment: ""))
                    .sign(payload: "ABC".data(using: .utf8)!, // swiftlint:disable:this force_unwrapping
                          in: session,
                          checkAlgorithm: checkBrainpoolAlgorithm)
                    .map { _ in true }
                    .map(ViewState.value)
                    .handleEvents(receiveOutput: { state in
                        if let value = state.value, value == true {
                            session.updateAlert(message: NSLocalizedString("nfc_txt_msg_success", comment: ""))
                            session.invalidateSession(with: nil)
                        } else {
                            session.invalidateSession(
                                with: state.error?.localizedDescription ?? NSLocalizedString(
                                    "nfc_txt_msg_failure",
                                    comment: ""
                                )
                            )
                        }
                    })
                    .mapError { error in
                        session.invalidateSession(with: error.localizedDescription)
                        return error
                    }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    if case let .cardError(readerError) = error as? NFCLoginController.Error,
                       case let .nfcTag(error: tagError) = readerError,
                       case .userCanceled = tagError {
                        self?.pState = .idle
                    } else {
                        self?.pState = .error(error)
                    }
                } else {
                    self?.pState = .idle
                }
                self?.cancellable?.cancel()
            }, receiveValue: { [weak self] value in
                self?.pState = value
            })
    }
}

extension Publisher {
    func userMessage(session: NFCCardSession, message: String) -> AnyPublisher<Self.Output, Self.Failure> {
        handleEvents(receiveOutput: { _ in
            // swiftlint:disable:previous trailing_closure
            session.updateAlert(message: message)
        })
            .eraseToAnyPublisher()
    }
}

extension Publisher where Output == HealthCardType, Self.Failure == Swift.Error {
    func verifyPin(pin: Format2Pin,
                   type: EgkFileSystem.Pin,
                   in _: NFCCardSession) -> AnyPublisher<HealthCardType, Swift.Error> {
        flatMap { secureCard in
            secureCard.verify(pin: pin, type: type)
                .tryMap { response in
                    if case let VerifyPinResponse.wrongSecretWarning(retryCount: count) = response {
                        throw NFCLoginController.Error.wrongPin(retryCount: count)
                    }
                    if case VerifyPinResponse.passwordBlocked = response {
                        throw NFCLoginController.Error.passwordBlocked
                    }
                    if response != VerifyPinResponse.success {
                        throw NFCLoginController.Error.verifyPinResponse
                    }
                    return secureCard
                }
        }.eraseToAnyPublisher()
    }

    func sign(payload: Data, in _: NFCCardSession, checkAlgorithm: Bool) -> AnyPublisher<Data, Swift.Error> {
        flatMap { secureCard -> AnyPublisher<Data, Swift.Error> in
            secureCard
                .readAutCertificate()
                .flatMap { certificate -> AnyPublisher<Data, Swift.Error> in
                    // Check AutCertificateResponse here ...
                    if checkAlgorithm, !certificate.info.algorithm.isBp256r1 {
                        return Fail(error: NFCLoginController.Error.invalidAlgorithm(certificate.info.algorithm))
                            .eraseToAnyPublisher()
                    }

                    CommandLogger.commands.append(Command(message: "Sign payload with card", type: .description))
                    return secureCard.sign(data: payload)
                        .tryMap { response in
                            if response.responseStatus == ResponseStatus.success, let signature = response.data {
                                Swift.print("SIGNATURE: \(signature.hexString())")
                                return signature
                            } else {
                                throw NFCLoginController.Error.signatureFailure(response.responseStatus)
                            }
                        }
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}

extension PSOAlgorithm {
    // [REQ:gemSpec_Krypt:A_17207] Assure only brainpoolP256r1 is used
    var isBp256r1: Bool {
        if case .signECDSA = self {
            return true
        }
        return false
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
