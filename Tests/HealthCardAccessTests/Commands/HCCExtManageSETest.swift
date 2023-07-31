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

import ASN1Kit
import Foundation
@testable import HealthCardAccess
import Nimble
import XCTest

class HCCExtManageSETest: XCTestCase {
    // swiftlint:disable:previous type_body_length
    func testManageSEsetEnvironment() {
        let expected = Data([0x0, 0x22, 0xF3, 0x1])
        let responseCodes: [UInt16] = [0x9000, 0x6A81, 0x6A88]

        let command = try? HealthCardCommand.ManageSE.setEnvironment(number: 1)
        expect {
            command?.bytes
        } == expected

        expect {
            command?.responseStatuses.keys
        }.to(contain(responseCodes))

        expect {
            try HealthCardCommand.ManageSE.setEnvironment(number: 5)
        }.to(throwError(HealthCardCommandBuilder.InvalidArgument.illegalValue(5, for: "SE", expected: 1 ..< 5)))
    }

    func testManageSEselectInternalSymmetricKey() {
        let dfSpecific = true
        guard let key = try? Key(0x8) else {
            Nimble.fail("Invalid key reference")
            return
        }
        let algorithm: PSOAlgorithm = .aesSessionKey4TC
        let expected = Data([0x0, 0x22, 0x41, 0xA4, 0x6, 0x83, 0x1,
                             key.calculateKeyReference(dfSpecific: dfSpecific), 0x80, 0x1, 0x74])
        let responseCodes: [UInt16] = [0x9000, 0x6A81, 0x6A88]

        let command = try? HealthCardCommand.ManageSE.selectInternal(
            symmetricKey: key,
            dfSpecific: dfSpecific,
            algorithm: algorithm
        )
        expect {
            command?.bytes
        } == expected

        expect {
            command?.responseStatuses.keys
        }.to(contain(responseCodes))
    }

    func testManageSEselectInternalAsymmetricKey() {
        let dfSpecific = true
        guard let key = try? Key(0x8) else {
            Nimble.fail("Invalid key reference")
            return
        }
        let algorithm: PSOAlgorithm = .elcAsyncAdmin
        let expected = Data([0x0, 0x22, 0x41, 0xA4, 0x6, 0x84, 0x1,
                             key.calculateKeyReference(dfSpecific: dfSpecific), 0x80, 0x1, 0xF4])
        let responseCodes: [UInt16] = [0x9000, 0x6A81, 0x6A88]

        let command = try? HealthCardCommand.ManageSE.selectInternal(
            asymmetricKey: key,
            dfSpecific: dfSpecific,
            algorithm: algorithm
        )
        expect {
            command?.bytes
        } == expected

        expect {
            command?.responseStatuses.keys
        }.to(contain(responseCodes))
    }

    func testManageSEselectExternalSymmetricKey() {
        let dfSpecific = true
        guard let key = try? Key(0x8) else {
            Nimble.fail("Invalid key reference")
            return
        }
        let algorithm: PSOAlgorithm = .aesSessionKey4TC
        let expected = Data([0x0, 0x22, 0x81, 0xA4, 0x6, 0x83, 0x1,
                             key.calculateKeyReference(dfSpecific: dfSpecific), 0x80, 0x1, 0x74])
        let responseCodes: [UInt16] = [0x9000, 0x6A81, 0x6A88]

        let command = try? HealthCardCommand.ManageSE.selectExternal(
            symmetricKey: key,
            dfSpecific: dfSpecific,
            algorithm: algorithm
        )
        expect {
            command?.bytes
        } == expected

        expect {
            command?.responseStatuses.keys
        }.to(contain(responseCodes))
    }

    func testManageSEselectExternalAsymmetricKey() {
        guard let key = try? Data(hex: "000680276883110000205690") else {
            Nimble.fail("Invalid key reference")
            return
        }
        let algorithm: PSOAlgorithm = .elcRoleCheck
        let expected = Data([0x0, 0x22, 0x81, 0xA4, 0x11, 0x83, 0xC] + key + [0x80, 0x1, 0x0])
        let responseCodes: [UInt16] = [0x9000, 0x6A81, 0x6A88]

        let command = try? HealthCardCommand.ManageSE.selectExternal(
            referenceKey: key,
            algorithm: algorithm
        )
        expect {
            command?.bytes
        } == expected

        expect {
            command?.responseStatuses.keys
        }.to(contain(responseCodes))
    }

    func testManageSEselectMutualSymmetricKey() {
        let dfSpecific = true
        guard let key = try? Key(0x8) else {
            Nimble.fail("Invalid key reference")
            return
        }
        let algorithm: PSOAlgorithm = .aesSessionKey4SM
        let expected = Data([0x0, 0x22, 0x81, 0xA4, 0x6, 0x83, 0x1,
                             key.calculateKeyReference(dfSpecific: dfSpecific), 0x80, 0x1, 0x54])
        let responseCodes: [UInt16] = [0x9000, 0x6A81, 0x6A88]

        let command = try? HealthCardCommand.ManageSE.selectMutual(symmetricKey: key,
                                                                   dfSpecific: dfSpecific,
                                                                   algorithm: algorithm)
        expect {
            command?.bytes
        } == expected

        expect {
            command?.responseStatuses.keys
        }.to(contain(responseCodes))
    }

    func testManageSEselectPACEsymmetricKey() {
        let dfSpecific = true
        guard let key = try? Key(0x8) else {
            Nimble.fail("Invalid key reference")
            return
        }
        guard let oid = try? ObjectIdentifier.from(string: "1.2.345"),
              let asn1obj = try? oid.asn1encode(tag: nil),
              let oidSerialized = asn1obj.data.primitive else {
            Nimble.fail("Invalid OID")
            return
        }
        let expected = Data([0x0, 0x22, 0xC1, 0xA4, 0x5 + UInt8(oidSerialized.count), 0x80, UInt8(oidSerialized.count)]
            + oidSerialized + [0x83, 0x1, key.calculateKeyReference(dfSpecific: dfSpecific)])
        let responseCodes: [UInt16] = [0x9000, 0x6A81, 0x6A88]

        let command = try? HealthCardCommand.ManageSE.selectPACE(symmetricKey: key,
                                                                 dfSpecific: dfSpecific,
                                                                 oid: oid)
        expect {
            command?.bytes
        } == expected

        expect {
            command?.responseStatuses.keys
        }.to(contain(responseCodes))
    }

    func testManageSEselectPACEwithDomainSymmetricKey() {
        let dfSpecific = true
        guard let key = try? Key(0x8) else {
            Nimble.fail("Invalid key reference")
            return
        }
        guard let oid = try? ObjectIdentifier.from(string: "1.2.345"),
              let asn1obj = try? oid.asn1encode(tag: nil),
              let oidSerialized = asn1obj.data.primitive else {
            Nimble.fail("Invalid OID")
            return
        }
        let expected = Data([0x0, 0x22, 0xC1, 0xA4, 0x8 + UInt8(oidSerialized.count), 0x80, UInt8(oidSerialized.count)]
            + oidSerialized + [0x83, 0x1, key.calculateKeyReference(dfSpecific: dfSpecific)] + [0x84, 0x1, 0x10])
        let responseCodes: [UInt16] = [0x9000, 0x6A81, 0x6A88]

        let command = try? HealthCardCommand.ManageSE.selectPACE(symmetricKey: key,
                                                                 dfSpecific: dfSpecific,
                                                                 oid: oid,
                                                                 domain: .brainpoolP384r1)
        expect {
            command?.bytes
        } == expected

        expect {
            command?.responseStatuses.keys
        }.to(contain(responseCodes))
    }

    func testManageSEselectSigningKey() {
        let dfSpecific = true
        guard let key = try? Key(0x8) else {
            Nimble.fail("Invalid key reference")
            return
        }
        let algorithm: PSOAlgorithm = .signPSS
        let expected = Data([0x0, 0x22, 0x41, 0xB6, 0x6, 0x84, 0x1,
                             key.calculateKeyReference(dfSpecific: dfSpecific), 0x80, 0x1, 0x5])
        let responseCodes: [UInt16] = [0x9000, 0x6A81, 0x6A88]

        let command = try? HealthCardCommand.ManageSE.selectSigning(key: key,
                                                                    dfSpecific: dfSpecific,
                                                                    algorithm: algorithm)
        expect {
            command?.bytes
        } == expected

        expect {
            command?.responseStatuses.keys
        }.to(contain(responseCodes))
    }

    func testManageSEselectCVC() {
        guard let cvcRef = try? Data(hex: "4445475858100218") else {
            Nimble.fail("Invalid CVC Key reference")
            return
        }

        let expected = Data([0x0, 0x22, 0x81, 0xB6, 0xA, 0x83, 0x8] + cvcRef)
        let responseCodes: [UInt16] = [0x9000, 0x6A81, 0x6A88]

        let command = try? HealthCardCommand.ManageSE.selectCVC(referenceKey: cvcRef)
        expect {
            command?.bytes
        } == expected

        expect {
            command?.responseStatuses.keys
        }.to(contain(responseCodes))
    }

    func testManageSEselectDecipherKey() {
        let dfSpecific = true
        guard let key = try? Key(0x8) else {
            Nimble.fail("Invalid key reference")
            return
        }
        let algorithm: PSOAlgorithm = .elcSharedSecretCalculation // 0xb
        let expected = Data([0x0, 0x22, 0x41, 0xB8, 0x6, 0x84, 0x1,
                             key.calculateKeyReference(dfSpecific: dfSpecific), 0x80, 0x1, 0xB])
        let responseCodes: [UInt16] = [0x9000, 0x6A81, 0x6A88]

        let command = try? HealthCardCommand.ManageSE.selectDecipher(key: key,
                                                                     dfSpecific: dfSpecific,
                                                                     algorithm: algorithm)
        expect {
            command?.bytes
        } == expected

        expect {
            command?.responseStatuses.keys
        }.to(contain(responseCodes))
    }

    func testManageSEselectEncipherKey() {
        guard let encipherKey = try? Data(hex: "4445475858100218EFFF0102") else {
            Nimble.fail("Invalid encipher Key reference")
            return
        }
        let algorithm: PSOAlgorithm = .rsaEncipherOAEP // 0x5
        let expected = Data([0x0, 0x22, 0x81, 0xB8, 0x11, 0x83, 0xC] + encipherKey + [0x80, 0x1, 0x5])
        let responseCodes: [UInt16] = [0x9000, 0x6A81, 0x6A88]

        let command = try? HealthCardCommand.ManageSE.selectEncipher(key: encipherKey, algorithm: algorithm)
        expect {
            command?.bytes
        } == expected

        expect {
            command?.responseStatuses.keys
        }.to(contain(responseCodes))
    }

    static let allTests = [
        ("testManageSEsetEnvironment", testManageSEsetEnvironment),
        ("testManageSEselectInternalSymmetricKey", testManageSEselectInternalSymmetricKey),
        ("testManageSEselectInternalAsymmetricKey", testManageSEselectInternalAsymmetricKey),
        ("testManageSEselectExternalSymmetricKey", testManageSEselectExternalSymmetricKey),
        ("testManageSEselectExternalAsymmetricKey", testManageSEselectExternalAsymmetricKey),
        ("testManageSEselectMutualSymmetricKey", testManageSEselectMutualSymmetricKey),
        ("testManageSEselectPACEsymmetricKey", testManageSEselectPACEsymmetricKey),
        ("testManageSEselectPACEwithDomainSymmetricKey", testManageSEselectPACEwithDomainSymmetricKey),
        ("testManageSEselectSigningKey", testManageSEselectSigningKey),
        ("testManageSEselectCVC", testManageSEselectCVC),
        ("testManageSEselectDecipherKey", testManageSEselectDecipherKey),
        ("testManageSEselectEncipherKey", testManageSEselectEncipherKey),
    ]
}
