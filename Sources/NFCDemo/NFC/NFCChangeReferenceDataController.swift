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

public class NFCChangeReferenceDataController: ChangeReferenceData {
    public enum Error: Swift.Error, LocalizedError {
        /// In case the PIN, PUK or CAN could not be constructed from input
        case cardError(NFCTagReaderSession.Error)
        case invalidCanOrPinFormat
        case wrongPin(retryCount: Int)
        case commandBlocked
        case otherError

        public var errorDescription: String? {
            switch self {
            case let .cardError(error):
                return error.localizedDescription
            case .invalidCanOrPinFormat:
                return "Invalid CAN or PIN format"
            case let .wrongPin(retryCount: retryCount):
                return "Wrong PIN with retry count \(retryCount)."
            case .commandBlocked:
                return "PIN usage counter exhausted"
            case .otherError:
                return "An unexpected error occurred."
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
    func changeReferenceDataSetNewPin(can: String, oldPin: String, newPin: String) {
        if case .loading = pState { return }
        callOnMainThread {
            self.pState = .loading(nil)
        }
        let canData: CAN
        let format2OldPin: Format2Pin
        let format2NewPin: Format2Pin
        do {
            canData = try CAN.from(Data(can.utf8))
            format2OldPin = try Format2Pin(pincode: oldPin)
            format2NewPin = try Format2Pin(pincode: newPin)
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
                    .userMessage(
                        session: session,
                        message: NSLocalizedString("nfc_txt_msg_reset_withNewPin", comment: "")
                    )
                    .changeReferenceDataSetNewPin(
                        oldPin: format2OldPin,
                        newPin: format2NewPin,
                        type: EgkFileSystem.Pin.mrpinHome,
                        dfSpecific: false
                    )

                    .map { _ in true }
                    .map(ViewState.value)
                    .handleEvents(receiveOutput: { state in
                        if let value = state.value, value == true {
                            session
                                .updateAlert(message: NSLocalizedString("nfc_txt_msg_reset_success",
                                                                        comment: ""))
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
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case let .failure(error) = completion {
                        if case let .cardError(readerError) = error as? NFCChangeReferenceDataController.Error,
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
                },
                receiveValue: { [weak self] value in
                    self?.pState = value
                }
            )
    }
}

extension Publisher where Output == HealthCardType, Self.Failure == Swift.Error {
    func changeReferenceDataSetNewPin(
        oldPin: Format2Pin,
        newPin: Format2Pin,
        type: EgkFileSystem.Pin,
        dfSpecific: Bool
    ) -> AnyPublisher<HealthCardType, Swift.Error> {
        flatMap { secureCard in
            secureCard.changeReferenceDataSetNewPin(
                old: oldPin,
                new: newPin,
                type: type,
                dfSpecific: dfSpecific
            )
            .tryMap { response in
                if case ChangeReferenceDataResponse.success = response {
                    return secureCard
                }
                if case let ChangeReferenceDataResponse.wrongSecretWarning(retryCount: count) = response {
                    throw NFCChangeReferenceDataController.Error.wrongPin(retryCount: count)
                }
                if case ChangeReferenceDataResponse.commandBlocked = response {
                    throw NFCChangeReferenceDataController.Error.commandBlocked
                }
                // else
                throw NFCChangeReferenceDataController.Error.otherError
            }
        }
        .eraseToAnyPublisher()
    }
}
