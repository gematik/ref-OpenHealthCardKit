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
import Foundation
import HealthCardAccess

extension HealthCardType {

    func determineKeyAgreementAlgorithm(writeTimeout: TimeInterval, readTimeout: TimeInterval) throws
                    -> Executable<KeyAgreement.Algorithm> {

        let selectMf = HealthCardCommand.Select.selectRoot()
        let selectEfCardAccess: HealthCardCommand
        let read = try HealthCardCommand.Read.readFileCommand(ne: APDU.expectedLengthWildcardShort)

        if case let .valid(cardType: .some(healthCardPropertyType)) = self.status {
            switch healthCardPropertyType {
            case .egk:
                selectEfCardAccess = HealthCardCommand.Select.selectEf(with: EgkFileSystem.EF.cardAccess.fid)
            case .hba:
                // TODO use EgkFileSystem.EF.cardAccess.fid when available swiftlint:disable:this todo
                selectEfCardAccess = HealthCardCommand.Select.selectEf(with: try FileIdentifier(hex: "011C"))
            case .smcb:
                throw KeyAgreement.Error.efCardAccessNotAvailable
            }
        } else {
            throw KeyAgreement.Error.noValidHealthCardStatus
        }

        return selectMf.execute(on: self, writeTimeout: writeTimeout, readTimeout: readTimeout)
                .flatMap { _ in
                    selectEfCardAccess.execute(on: self, writeTimeout: writeTimeout, readTimeout: readTimeout)
                }
                .flatMap { _ in
                    read.execute(on: self, writeTimeout: writeTimeout, readTimeout: readTimeout)
                }
                .map { response in
                    guard let data = response.data else {
                        throw KeyAgreement.Error.unexpectedFormedAnswerFromCard
                    }
                    let protocolOid = try HealthCard.extractProtocolOid(from: data)
                    guard let result = protocolOid.keyAgreementAlgorithm else {
                        throw KeyAgreement.Error.unsupportedKeyAgreementAlgorithm(protocolOid)
                    }
                    return result
                }
    }

    private static func extractProtocolOid(from efAccessResponse: Data) throws -> ASN1Kit.ObjectIdentifier {
        guard let asn1 = try? ASN1Decoder.decode(asn1: efAccessResponse),
              let asn1FirstSet = asn1.data.items?.first,
              let asn1Oid = asn1FirstSet.data.items?.first else {
            throw KeyAgreement.Error.unexpectedFormedAnswerFromCard
        }
        return try ObjectIdentifier(from: asn1Oid)
    }
}

extension ASN1Kit.ObjectIdentifier {
    var keyAgreementAlgorithm: KeyAgreement.Algorithm? {
        if self.rawValue == KeyAgreement.Algorithm.idPaceEcdhGmAesCbcCmac128.protocolIdentifier {
            return .idPaceEcdhGmAesCbcCmac128
        }
        return nil
    }
}
