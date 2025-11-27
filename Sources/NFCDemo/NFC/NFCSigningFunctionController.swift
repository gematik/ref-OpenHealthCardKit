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
import OSLog

public class NFCSigningFunctionController: SigningFunctionController {
    public enum Error: Swift.Error, LocalizedError {
        /// In case the PIN or CAN could not be constructed from input
        case cardError(NFCHealthCardSessionError)
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

    let messages = NFCHealthCardSession<Data>.Messages(
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
    func signingFunction(can: String, pin: String, checkBrainpoolAlgorithm: Bool) async {
        if case .loading = await pState { return }
        Task { @MainActor in
            self.pState = .loading(nil)
        }
        let format2Pin: Format2Pin
        do {
            format2Pin = try Format2Pin(pincode: pin)
        } catch {
            Task { @MainActor in
                self.pState = .error(Error.invalidCanOrPinFormat)
            }
            return
        }

        // tag::nfcHealthCardSession_init[]
        guard let nfcHealthCardSession = NFCHealthCardSession(messages: messages, can: can, operation: { session in
            session.updateAlert(message: NSLocalizedString("nfc_txt_msg_verify_pin", comment: ""))
            let verifyPinResponse = try await session.card.verifyAsync(
                pin: format2Pin,
                type: EgkFileSystem.Pin.mrpinHome
            )
            if case let VerifyPinResponse.wrongSecretWarning(retryCount: count) = verifyPinResponse {
                throw NFCSigningFunctionController.Error.wrongPin(retryCount: count)
            } else if case VerifyPinResponse.passwordBlocked = verifyPinResponse {
                throw NFCSigningFunctionController.Error.passwordBlocked
            } else if VerifyPinResponse.success != verifyPinResponse {
                throw NFCSigningFunctionController.Error.verifyPinResponse
            }

            session.updateAlert(message: NSLocalizedString("nfc_txt_msg_signing", comment: ""))
            let outcome = try await session.card.sign(
                payload: "ABC".data(using: .utf8)!, // swiftlint:disable:this force_unwrapping
                checkAlgorithm: checkBrainpoolAlgorithm
            )

            session.updateAlert(message: NSLocalizedString("nfc_txt_msg_success", comment: ""))
            return outcome
        })
        else {
            // handle the case the Session could not be initialized
            // end::nfcHealthCardSession_init[]
            Task { @MainActor in self.pState = .error(NFCHealthCardSessionError.couldNotInitializeSession) }
            return
        }

        let signedData: Data
        do {
            // tag::nfcHealthCardSession_execute[]
            signedData = try await nfcHealthCardSession.executeOperation()
            // end::nfcHealthCardSession_execute[]

            Task { @MainActor in self.pState = .value(true) }
            // tag::nfcHealthCardSession_errorHandling[]
        } catch NFCHealthCardSessionError.coreNFC(.userCanceled) {
            // error type is always `NFCHealthCardSessionError`
            // here we especially handle when the user canceled the session
            Task { @MainActor in self.pState = .idle } // Do some view-property update
            // Calling .invalidateSession() is not strictly necessary
            //  since nfcHealthCardSession does it while it's de-initializing.
            nfcHealthCardSession.invalidateSession(with: nil)
            return
        } catch {
            Task { @MainActor in self.pState = .error(error) }
            nfcHealthCardSession.invalidateSession(with: error.localizedDescription)
            return
        }
        // end::nfcHealthCardSession_errorHandling[]
        Logger.nfcDemo.debug("Signed Data: \(signedData)")
    }
}

extension HealthCardType {
    func sign(payload: Data, checkAlgorithm: Bool) async throws -> Data {
        let certificate = try await readAutCertificateAsync()
        if checkAlgorithm, !certificate.info.algorithm.isBp256r1 {
            throw NFCSigningFunctionController.Error.invalidAlgorithm(certificate.info.algorithm)
        }

        CommandLogger.commands.append(Command(message: "Sign payload with card", type: .description))
        let response = try await signAsync(data: payload)
        guard response.responseStatus == ResponseStatus.success, let signature = response.data
        else {
            throw NFCSigningFunctionController.Error.signatureFailure(response.responseStatus)
        }
        Swift.print("SIGNATURE: \(signature.hexString())")
        return signature
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
