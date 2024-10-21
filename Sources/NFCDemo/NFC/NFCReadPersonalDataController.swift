//
//  Copyright (c) 2024 gematik GmbH
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
import Gzip
import HealthCardAccess
import HealthCardControl
import Helper
import NFCCardReaderProvider
import SwiftyXMLParser
public class NFCReadPersonalDataController: ReadPersonalData {
    public enum Error: Swift.Error, LocalizedError {
        /// In case the PIN, PUK or CAN could not be constructed from input
        case cardError(NFCTagReaderSession.Error)
        case invalidCanOrPinFormat
        case commandBlocked
        case otherError

        public var errorDescription: String? {
            switch self {
            case let .cardError(error):
                return error.localizedDescription
            case .invalidCanOrPinFormat:
                return "Invalid CAN, PUK or PIN format"
            case .commandBlocked:
                return "PUK cannot be used anymore! \n (PUK usage counter exhausted)"
            case .otherError:
                return "An unexpected error occurred."
            }
        }
    }

    @MainActor
    @Published
    private var pState: ViewState<PersonalData, Swift.Error> = .idle
    var state: Published<ViewState<PersonalData, Swift.Error>>.Publisher {
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
        noCardMessage: NSLocalizedString("nfc_txt_noCardMessage", comment: ""),
        multipleCardsMessage: NSLocalizedString("nfc_txt_multipleCardsMessage", comment: ""),
        unsupportedCardMessage: NSLocalizedString("nfc_txt_unsupportedCardMessage", comment: ""),
        connectionErrorMessage: NSLocalizedString("nfc_txt_connectionErrorMessage", comment: "")
    )

    // swiftlint:disable:next function_body_length
    func readPersonalData(can: String) async {
        if case .loading = await pState { return }
        Task { @MainActor in
            self.pState = .loading(nil)
        }

        guard let nfcHealthCardSession = NFCHealthCardSession(messages: messages, can: can, operation: { session in
            session.updateAlert(message: NSLocalizedString("nfc_txt_meg_reading_personal_data", comment: ""))
            let hcaApplicationIdentifier = EgkFileSystem.DF.HCA.aid

            let hcaPdFileIdentifier = EgkFileSystem.EF.hcaPD.fid

            _ = try await session.card
                .selectDedicatedAsync(file: DedicatedFile(aid: hcaApplicationIdentifier, fid: hcaPdFileIdentifier))

            let data = try await session.card.readSelectedFileAsync(
                expected: nil,
                failOnEndOfFileWarning: false,
                offset: 0
            )

            return data
        })
        else {
            Task { @MainActor in self.pState = .error(NFCTagReaderSession.Error.couldNotInitializeSession) }
            return
        }

        do {
            let personalDataData = try await nfcHealthCardSession.executeOperation()

            // Personal data is compressed with gzip
            // first 2 bytes indicate the length of the compressed data
            // refer to https://gemspec.gematik.de/docs/gemSpec/gemSpec_eGK_Fach_VSDM/gemSpec_eGK_Fach_VSDM_V1.2.1/#2.4
            let lengthBytes = personalDataData.prefix(2)
            let length = UInt16(lengthBytes.withUnsafeBytes { $0.load(as: UInt16.self) })
            let personalDataGzip = personalDataData.suffix(from: 2).prefix(Int(length))

            let decompressedData: Data
            if personalDataGzip.isGzipped {
                decompressedData = try personalDataGzip.gunzipped()
            } else {
                decompressedData = personalDataGzip
            }

            // Data is now in xml format
            // refer to xml schema definition file UC_PersoenlicheVersichertendatenXML.xsd in
            // https://fachportal.gematik.de/schnelleinstieg/downloadcenter/schemadateien-wsdl-und-andere-dateien
            // -> Schnittstellen­definitionen im XSD- und WSDL-Format für den PTV3-Konnektor
            let personalData: PersonalData
            let xml = XML.parse(decompressedData)
            let insurantAccessor = xml["UC_PersoenlicheVersichertendatenXML"]["Versicherter"]
            if let versichertenId = insurantAccessor["Versicherten_ID"].element?.text,
               let firstName = insurantAccessor["Person"]["Vorname"].element?.text,
               let surname = insurantAccessor["Person"]["Nachname"].element?.text,
               let address = insurantAccessor["Person"]["StrassenAdresse"]["Ort"].element?.text {
                personalData = PersonalData(
                    name: surname,
                    firstName: firstName,
                    address: address,
                    insuranceNumber: versichertenId
                )
            } else {
                personalData = PersonalData.dummy
            }

            Task { @MainActor in self.pState = .value(personalData) }
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
