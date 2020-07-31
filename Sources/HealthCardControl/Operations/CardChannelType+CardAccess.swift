//
//  Copyright (c) 2020 gematik GmbH
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//     http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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
        return EgkFileSystem.EF.cardAccess.sfid!
    }
}
extension CardChannelType {
    func readKeyAgreementAlgorithm(
            cardAid: CardAid? = nil,
            writeTimeout: TimeInterval = 30.0,
            readTimeout: TimeInterval = 30.0
    ) -> AnyPublisher<KeyAgreement.Algorithm, Error> {
        let channel = self

        let cardAidPublisher: AnyPublisher<CardAid, Error>
        if let cardAid = cardAid {
            cardAidPublisher = Just(cardAid)
                    .mapError { $0 as Error }
                    .eraseToAnyPublisher()
        } else {
            cardAidPublisher = channel.determineCardAid()
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
}

extension ASN1Kit.ObjectIdentifier {
    // swiftlint:disable:next strict_fileprivate
    fileprivate var keyAgreementAlgorithm: KeyAgreement.Algorithm? {
        if self.rawValue == KeyAgreement.Algorithm.idPaceEcdhGmAesCbcCmac128.protocolIdentifier {
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
