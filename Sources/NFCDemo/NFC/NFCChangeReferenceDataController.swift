//
// Copyright (Change Date see Readme), gematik GmbH
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// *******
//
// For additional notes and disclaimer from gematik and in case of changes by gematik find details in the "Readme" file.
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
        case cardError(NFCTagReaderSession.Error)
        /// In case the PIN, PUK or CAN could not be constructed from input
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

    @MainActor
    @Published
    private var pState: ViewState<Bool, Swift.Error> = .idle
    var state: Published<ViewState<Bool, Swift.Error>>.Publisher {
        $pState
    }

    var cancellable: AnyCancellable?

    @MainActor
    func dismissError() async {
        if pState.error != nil {
            pState = .idle
        }
    }

    let messages = NFCHealthCardSession<ChangeReferenceDataResponse>.Messages(
        discoveryMessage: NSLocalizedString("nfc_txt_discoveryMessage", comment: ""),
        connectMessage: NSLocalizedString("nfc_txt_connectMessage", comment: ""),
        secureChannelMessage: NSLocalizedString("nfc_txt_secureChannel", comment: ""),
        wrongCardAccessNumberMessage: NSLocalizedString("nfc_txt_wrongCANMessage", comment: ""),
        noCardMessage: NSLocalizedString("nfc_txt_noCardMessage", comment: ""),
        multipleCardsMessage: NSLocalizedString("nfc_txt_multipleCardsMessage", comment: ""),
        unsupportedCardMessage: NSLocalizedString("nfc_txt_unsupportedCardMessage", comment: ""),
        connectionErrorMessage: NSLocalizedString("nfc_txt_connectionErrorMessage", comment: "")
    )

    // swiftlint:disable:next function_body_length
    func changeReferenceDataSetNewPin(can: String, oldPin: String, newPin: String) async {
        if case .loading = await pState { return }
        Task { @MainActor in
            self.pState = .loading(nil)
        }
        let format2OldPin: Format2Pin
        let format2NewPin: Format2Pin
        do {
            format2OldPin = try Format2Pin(pincode: oldPin)
            format2NewPin = try Format2Pin(pincode: newPin)
        } catch {
            Task { @MainActor in
                self.pState = .error(Error.invalidCanOrPinFormat)
            }
            return
        }

        guard let nfcHealthCardSession = NFCHealthCardSession(messages: messages, can: can, operation: { session in
            session.updateAlert(message: NSLocalizedString("nfc_txt_msg_reset_withNewPin", comment: ""))
            let changeReferenceDataResponse = try await session.card.changeReferenceDataSetNewPin(
                old: format2OldPin,
                new: format2NewPin,
                type: EgkFileSystem.Pin.mrpinHome,
                dfSpecific: false
            )
            if case ChangeReferenceDataResponse.success = changeReferenceDataResponse {
                session.updateAlert(message: NSLocalizedString("nfc_txt_msg_reset_success", comment: ""))
                return changeReferenceDataResponse
            } else {
                session.updateAlert(message: NSLocalizedString("nfc_txt_msg_reset_failure", comment: ""))
                if case let ChangeReferenceDataResponse
                    .wrongSecretWarning(retryCount: count) = changeReferenceDataResponse {
                    throw NFCChangeReferenceDataController.Error.wrongPin(retryCount: count)
                }
                if case ChangeReferenceDataResponse.commandBlocked = changeReferenceDataResponse {
                    throw NFCChangeReferenceDataController.Error.commandBlocked
                }
                // else
                throw NFCChangeReferenceDataController.Error.otherError
            }
        })
        else {
            Task { @MainActor in self.pState = .error(NFCTagReaderSession.Error.couldNotInitializeSession) }
            return
        }

        do {
            _ = try await nfcHealthCardSession.executeOperation()
            Task { @MainActor in self.pState = .value(true) }
        } catch NFCHealthCardSessionError.coreNFC(.userCanceled) {
            nfcHealthCardSession.invalidateSession(with: nil)
            Task { @MainActor in self.pState = .idle }
            return
        } catch {
            nfcHealthCardSession.invalidateSession(with: error.localizedDescription)
            Task { @MainActor in self.pState = .error(error) }
            return
        }
    }
}
