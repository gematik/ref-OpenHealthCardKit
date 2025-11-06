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

import ASN1Kit
import CardReaderProviderApi
import Combine
import Foundation
import HealthCardAccess

extension CardAid {
    /// 5.3.2 MF / EF.CardAccess (eGK)
    /// 5.3.2 MF / EF.CardAccess (HBA)
    /// - Note: for both the shortFileIdentifier is the same
    var efCardAccess: ShortFileIdentifier {
        // swiftlint:disable:next force_unwrapping
        EgkFileSystem.EF.cardAccess.sfid!
    }
}

extension CardChannelType {
    @available(*, deprecated, message: "Use structured concurrency version instead")
    func readKeyAgreementAlgorithm(
        cardAid: CardAid? = nil,
        writeTimeout: TimeInterval = 30.0,
        readTimeout: TimeInterval = 30.0
    ) -> AnyPublisher<KeyAgreement.Algorithm, Error> {
        let channel = self

        let cardAidPublisher: AnyPublisher<CardAid, Error>
        if let cardAid = cardAid {
            cardAidPublisher = Just(cardAid)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            cardAidPublisher = channel.determineCardAidPublisher()
        }
        return cardAidPublisher
            .flatMap { (cardAid: CardAid) in
                HealthCardCommand.Select.selectFile(with: cardAid.rawValue)
                    .publisher(for: channel, writeTimeout: writeTimeout, readTimeout: readTimeout)
                    .tryMap { _ in
                        try HealthCardCommand.Read.readFileCommand(with: cardAid.efCardAccess,
                                                                   ne: APDU.expectedLengthWildcardShort)
                    }
                    .flatMap {
                        $0.publisher(for: channel, writeTimeout: writeTimeout, readTimeout: readTimeout)
                    }
                    .tryMap { response in
                        guard let data = response.data else {
                            throw KeyAgreement.Error.unexpectedFormedAnswerFromCard
                        }
                        let protocolOid = try ASN1Kit.ObjectIdentifier.protocolOid(from: data)
                        guard let keyAgreementAlgorithm = protocolOid.keyAgreementAlgorithm else {
                            throw KeyAgreement.Error.unsupportedKeyAgreementAlgorithm(protocolOid)
                        }
                        return keyAgreementAlgorithm
                    }
            }
            .eraseToAnyPublisher()
    }

    func readKeyAgreementAlgorithmAsync(
        cardAid: CardAid? = nil,
        writeTimeout: TimeInterval = 30.0,
        readTimeout: TimeInterval = 30.0
    ) async throws -> KeyAgreement.Algorithm {
        let channel = self

        let determinedCardAid: CardAid
        if let cardAid = cardAid {
            determinedCardAid = cardAid
        } else {
            determinedCardAid = try await channel.determineCardAidAsync()
        }

        let selectCommand = HealthCardCommand.Select.selectFile(with: determinedCardAid.rawValue)
        let selectResponse = try await selectCommand.transmit(
            on: channel,
            writeTimeout: writeTimeout,
            readTimeout: readTimeout
        )
        guard selectResponse.responseStatus == ResponseStatus.success
        else {
            throw HealthCard.Error.unexpectedResponse(actual: selectResponse.responseStatus, expected: .success)
        }
        let readCommand = try HealthCardCommand.Read.readFileCommand(
            with: determinedCardAid.efCardAccess,
            ne: APDU.expectedLengthWildcardShort
        )
        let readResponse = try await readCommand.transmit(
            on: channel,
            writeTimeout: writeTimeout,
            readTimeout: readTimeout
        )

        guard let data = readResponse.data else {
            throw KeyAgreement.Error.unexpectedFormedAnswerFromCard
        }
        let protocolOid = try ASN1Kit.ObjectIdentifier.protocolOid(from: data)
        guard let keyAgreementAlgorithm = protocolOid.keyAgreementAlgorithm else {
            throw KeyAgreement.Error.unsupportedKeyAgreementAlgorithm(protocolOid)
        }
        return keyAgreementAlgorithm
    }
}

extension ASN1Kit.ObjectIdentifier {
    // swiftlint:disable:next strict_fileprivate
    fileprivate var keyAgreementAlgorithm: KeyAgreement.Algorithm? {
        if rawValue == KeyAgreement.Algorithm.idPaceEcdhGmAesCbcCmac128.protocolIdentifier {
            return .idPaceEcdhGmAesCbcCmac128
        }
        return nil
    }

    // swiftlint:disable:next strict_fileprivate
    fileprivate static func protocolOid(from readEfCardAccessResponse: Data) throws -> ASN1Kit.ObjectIdentifier {
        guard let asn1 = try? ASN1Decoder.decode(asn1: readEfCardAccessResponse),
              let asn1FirstSet = asn1.data.items?.first,
              let asn1Oid = asn1FirstSet.data.items?.first else {
            throw KeyAgreement.Error.unexpectedFormedAnswerFromCard
        }
        return try ObjectIdentifier(from: asn1Oid)
    }
}
