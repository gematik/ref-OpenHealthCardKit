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
import Foundation
@testable import HealthCardAccess
import Nimble
import Security
import XCTest

final class HCCExtPerformSecurityOperationTest: XCTestCase {
    // swiftlint:disable:previous type_body_length

    let dataLong = Data(repeating: 0xFA, count: 300)
    let bundle = Bundle(for: HCCExtPerformSecurityOperationTest.self)

    func testPsoChecksum_OptionDES() {
        let data = Data([0x1F, 0x2F, 0xFF, 0xEF])

        let expected = Data([0x0, 0x2A, 0x8E, 0x80, 0x4] + data + [0x0])
        expect {
            try HealthCardCommand.PsoChecksum.hashUsingDES(data: data).bytes
        } == expected

        let expectedLong = Data([0x0, 0x2A, 0x8E, 0x80, 0x0, 0x1, 0x2C] + dataLong + [0x0, 0x0])
        expect {
            try HealthCardCommand.PsoChecksum.hashUsingDES(data: self.dataLong).bytes
        } == expectedLong
    }

    func testPsoChecksum_AES() {
        let data = Data([0x1F, 0x2F, 0xFF, 0xEF])

        let expected = Data([0x0, 0x2A, 0x8E, 0x80, 0x5, 0x0] + data + [0x0])
        expect {
            try HealthCardCommand.PsoChecksum.hashUsingAES(incrementSSCmac: false, data: data)
                .bytes
        } == expected

        let expectedLong = Data([0x0, 0x2A, 0x8E, 0x80, 0x0, 0x1, 0x2D, 0x1] + dataLong + [0x0, 0x0])
        expect {
            try HealthCardCommand.PsoChecksum.hashUsingAES(incrementSSCmac: true, data: self.dataLong)
                .bytes
        } == expectedLong
    }

    func testPsoChecksumResponseStatus() throws {
        let data = Data([0x1F, 0x2F, 0xFF, 0xEF])
        let statusKeys = try HealthCardCommand.PsoChecksum.hashUsingAES(incrementSSCmac: false, data: data)
            .responseStatuses.keys

        expect(statusKeys).to(contain([0x6982, 0x6985, 0x6A81, 0x6A88, 0x9000]))
    }

    func testPsoDSA() {
        let data = Data([0x1F, 0x2F, 0xFF, 0xEF])

        let expected = Data([0x0, 0x2A, 0x9E, 0x9A, 0x4] + data + [0x0])
        expect {
            try HealthCardCommand.PsoDSA.sign(data).bytes
        } == expected

        let expectedLong = Data([0x0, 0x2A, 0x9E, 0x9A, 0x0, 0x1, 0x2C] + dataLong + [0x0, 0x0])
        expect {
            try HealthCardCommand.PsoDSA.sign(self.dataLong)
                .bytes
        } == expectedLong
    }

    func testPsoDSAResponseStatus() throws {
        let data = Data([0x1F, 0x2F, 0xFF, 0xEF])
        let statusKeys = try HealthCardCommand.PsoDSA.sign(data).responseStatuses.keys
        expect(statusKeys).to(contain([0x6400, 0x6982, 0x6985, 0x6A81, 0x6A88, 0x9000]))
    }

    func testPsoDecipher() {
        let data = Data([0x66])

        let expectedRsa = Data([0x0, 0x2A, 0x80, 0x86, 0x0, 0x0, 0x2, 0x0, 0x66, 0x0, 0x0])
        expect {
            try HealthCardCommand.PsoDecipher.decipherUsingRsa(cryptogram: data)
                .bytes
        } == expectedRsa

        expect {
            try HealthCardCommand.PsoDecipher.decipherUsingRsa(cryptogram: self.dataLong)
                .ne
        } == APDU.expectedLengthWildcardExtended

        let expectedElc = Data([0x0, 0x2A, 0x80, 0x86, 0x1, 0x66, 0x0])
        expect {
            try HealthCardCommand.PsoDecipher.decipherUsingElc(cryptogram: data)
                .bytes
        } == expectedElc

        let expectedSymKey = Data([0x0, 0x2A, 0x80, 0x86, 0x2, 0x1, 0x66, 0x0])
        expect {
            try HealthCardCommand.PsoDecipher.decipherUsingSymmetricKey(cryptogram: data)
                .bytes
        } == expectedSymKey

        expect {
            try HealthCardCommand.PsoDecipher.decipherUsingRsa(cryptogram: data)
                .responseStatuses.keys
        }.to(contain(ResponseStatus.unsupportedFunction.code))
    }

    func testPsoEncipher_usingTransmittedRsaKey() throws {
        let dataToBeEnciphered = Data([0x66])
        let pubKeyData = ResourceLoader.loadResourceAsData(
            resource: "rsa_pub_key",
            withExtension: "der",
            directory: "PSO"
        )
        var createError: Unmanaged<CFError>?
        guard let publicKey = SecKeyCreateWithData(pubKeyData as NSData,
                                                   [kSecAttrKeyType: kSecAttrKeyTypeRSA,
                                                    kSecAttrKeyClass: kSecAttrKeyClassPublic] as NSDictionary,
                                                   &createError) else {
            Nimble.fail("Could not create public key with provided data")
            return
        }

        let apduEncipherRsaPkcs1v15 = ResourceLoader.loadResourceAsData(
            resource: "apduEncipherRsaPkcs1v15",
            withExtension: "dat",
            directory: "PSO"
        )
        expect {
            try HealthCardCommand.PsoEncipher
                .encipherUsingTransmittedRsaKeyPkcs1_v1_5(rsaPublicKey: publicKey,
                                                          data: dataToBeEnciphered)
                .bytes
        } == apduEncipherRsaPkcs1v15

        // using transmitted RSA Oaep key
        let apduEncipherRsaOaep = ResourceLoader.loadResourceAsData(
            resource: "apduEncipherRsaOaep",
            withExtension: "dat",
            directory: "PSO"
        )
        expect {
            try HealthCardCommand.PsoEncipher
                .encipherUsingTransmittedRsaKeyOaep(rsaPublicKey: publicKey,
                                                    data: dataToBeEnciphered)
                .bytes
        } == apduEncipherRsaOaep

        // test statuses
        let statusKeys = try HealthCardCommand.PsoEncipher
            .encipherUsingTransmittedRsaKeyPkcs1_v1_5(rsaPublicKey: publicKey,
                                                      data: dataToBeEnciphered)
            .responseStatuses.keys
        expect(statusKeys).to(contain([0x9000, 0x6400, 0x6982, 0x6A81, 0x6A88]))
    }

    func testPsoEncipher_usingTransmittedElcKey() {
        let dataToBeEnciphered = Data([0x66])
        let pubKeyData = ResourceLoader.loadResourceAsData(
            resource: "elc_pub_key",
            withExtension: "der",
            directory: "PSO"
        )
        var createError: Unmanaged<CFError>?
        guard let publicKey = SecKeyCreateWithData(pubKeyData as NSData,
                                                   [kSecAttrKeyType: kSecAttrKeyTypeEC,
                                                    kSecAttrKeyClass: kSecAttrKeyClassPublic] as NSDictionary,
                                                   &createError) else {
            Nimble.fail("Could not create public key with provided data")
            return
        }

        let apduEncipherElc = ResourceLoader.loadResourceAsData(
            resource: "apduEncipherElc",
            withExtension: "dat",
            directory: "PSO"
        )

        expect {
            try HealthCardCommand.PsoEncipher
                .encipherUsingTransmittedElcKey(elcPublicKey: publicKey, data: dataToBeEnciphered)
                .bytes
        } == apduEncipherElc
    }

    func testPsoEncipher_usingKeysOnCard() {
        let dataToBeEnciphered = Data([0x66])
        expect {
            try HealthCardCommand.PsoEncipher.encipherUsingRsaKeyOnCard(data: dataToBeEnciphered)
                .bytes
        } == Data([0x0, 0x2A, 0x86, 0x80, 0x0, 0x0, 0x1, 0x66, 0x0, 0x0])
        expect {
            try HealthCardCommand.PsoEncipher.encipherUsingRsaKeyOnCard(data: self.dataLong)
                .bytes
        } == Data([0x0, 0x2A, 0x86, 0x80, 0x0, 0x1, 0x2C] + dataLong + [0x0, 0x0])

        expect {
            try HealthCardCommand.PsoEncipher.encipherUsingElcKeyOnCard(data: dataToBeEnciphered)
                .bytes
        } == Data([0x0, 0x2A, 0x86, 0x80, 0x1, 0x66, 0x0])
        expect {
            try HealthCardCommand.PsoEncipher.encipherUsingElcKeyOnCard(data: self.dataLong)
                .bytes
        } == Data([0x0, 0x2A, 0x86, 0x80, 0x0, 0x1, 0x2C] + dataLong + [0x0, 0x0])

        expect {
            try HealthCardCommand.PsoEncipher.encipherUsingSymmetricKeyOnCard(data:
                dataToBeEnciphered)
                .bytes
        } == Data([0x0, 0x2A, 0x86, 0x80, 0x1, 0x66, 0x0])
        expect {
            try HealthCardCommand.PsoEncipher.encipherUsingSymmetricKeyOnCard(data:
                self.dataLong)
                .bytes
        } == Data([0x0, 0x2A, 0x86, 0x80, 0x0, 0x1, 0x2C] + dataLong + [0x0, 0x0])
    }

    func testPsoVerifyGemCvCertificate() throws {
        let certData = ResourceLoader.loadResourceAsData(
            resource: "GemCVC",
            withExtension: "der",
            directory: "CVC"
        )

        let expectedAPDU = Data([0x0, 0x2A, 0x0, 0xBE, 0xDC] + certData)
        expect {
            try HealthCardCommand.PsoCertificate.verify(cvc: try GemCvCertificate.from(data: certData))
                .bytes
        } == expectedAPDU

        let statusKeys = try HealthCardCommand.PsoCertificate.verify(cvc: try GemCvCertificate.from(data: certData))
            .responseStatuses.keys
        expect(statusKeys).to(contain(
            [0x63C0, 0x63C1, 0x63C2, 0x63C3, 0x63C4, 0x63C5, 0x63C6, 0x63C7, 0x63C8, 0x63C9, 0x63CA, 0x63CB,
             0x63CC, 0x63CD, 0x63CE, 0x63CF, 0x9000, 0x6581, 0x6982, 0x6983, 0x6985, 0x6A80, 0x6A88]
        ))
    }

    func testPsoVerifyChecksum() throws {
        let data = Data([0x1F, 0x2F, 0xFF, 0xEF])
        let mac = data + data
        let expectedAPDU = Data([0x0, 0x2A, 0x0, 0xA2, 0x10, 0x80, 0x4] + data + [0x8E, 0x8] + mac)

        expect {
            try HealthCardCommand.PsoChecksum.verify(data: data, mac: mac).bytes
        } == expectedAPDU

        let statusKeys = try HealthCardCommand.PsoChecksum.verify(data: data, mac: mac).responseStatuses.keys
        expect(statusKeys).to(contain([0x9000, 0x6982, 0x6985, 0x6A80, 0x6A81, 0x6A88]))

        let expectedLong = Data([0x0, 0x2A, 0x0, 0xA2, 0x0, 0x1, 0x3A, 0x80, 0x82, 0x1, 0x2C] +
            dataLong + [0x8E, 0x8] + mac)
        expect {
            try HealthCardCommand.PsoChecksum.verify(data: self.dataLong, mac: mac).bytes
        } == expectedLong

        expect {
            try HealthCardCommand.PsoChecksum.verify(data: data, mac: Data([0x0])).bytes
        }.to(throwError(HealthCardCommandBuilder.InvalidArgument.wrongMACLength(1)))
    }

    /// Pso DSA verify Test-case parameters
    /// - Parameters:
    ///     - test: Name of the test-case
    ///     - hash: filename of the hash data
    ///     - normalized: filename of the normalized signature file
    ///     - key: filename of the EC Public Key DER file
    ///     - expected: filename of the expected APDU file
    ///     - pass: whether the test should pass
    ///     - throw: whether the test should throw
    typealias DSATestParameter = (test: String, hash: String, normalized: String, key: String, expected: String,
                                  pass: Bool, throw: Bool)
    let dsaVerifyTests: [DSATestParameter] = [
        (test: "ansix9p256r1", hash: "ansix9p256r1_hash", normalized: "ansix9p256r1_signature_normalized",
         key: "ansix9p256r1_ecpubkey", expected: "ansix9p256r1_expected_apdu", pass: true, throw: false),
        (test: "ansix9p384r1", hash: "ansix9p384r1_hash", normalized: "ansix9p384r1_signature_normalized",
         key: "ansix9p384r1_ecpubkey", expected: "ansix9p384r1_expected_apdu", pass: true, throw: false),
        (test: "brainpoolP512r1", hash: "brainpoolP512r1_hash",
         normalized: "brainpoolP512r1_signature_normalized", key: "brainpoolP512r1_ecpubkey",
         expected: "brainpoolP512r1_expected_apdu", pass: false, throw: true),
    ]

    func testPsoVerifyDSA_parameterized() {
        dsaVerifyTests.forEach { (testCase: DSATestParameter) in
            let testName = testCase.test
            let errors = Nimble.gatherFailingExpectations(silently: true) {
                dasVerificationTest(testCase)
            }
            if !errors.isEmpty {
                Nimble.fail("Test (DSA-Verify): [\(testName)] failed!")
                errors.forEach { assertion in
                    Nimble.fail(String(describing: assertion))
                }
            }
        }
    }

    // swiftlint:disable:next function_body_length
    func dasVerificationTest(_ testCase: DSATestParameter) {
        let hash = testCase.hash
        let signature = testCase.normalized
        let publicKey = testCase.key
        let expected = testCase.expected
        let pass = testCase.pass
        let `throw` = testCase.throw

        let path = "DSA"
        let hashData = ResourceLoader.loadResourceAsData(
            resource: hash,
            withExtension: "dat",
            directory: "DSA"
        )
        let normalizedSignature = ResourceLoader.loadResourceAsData(
            resource: signature,
            withExtension: "dat",
            directory: "DSA"
        )
        let publicKeyData = ResourceLoader.loadResourceAsData(
            resource: publicKey,
            withExtension: "dat",
            directory: "DSA"
        )

        let expectedAPDU = ResourceLoader.loadResourceAsData(
            resource: expected,
            withExtension: "dat",
            directory: "DSA"
        )
        let expectation = expect { () throws -> Data in
            var error: Unmanaged<CFError>?
            guard let publicKey = SecKeyCreateWithData(
                publicKeyData as CFData,
                [kSecAttrKeyType: kSecAttrKeyTypeEC, kSecAttrKeyClass: kSecAttrKeyClassPublic] as CFDictionary,
                &error
            ) else {
                throw "Could not initialize ECPublicKey"
            }

            return try HealthCardCommand.PsoDSA.verify(
                signature: normalizedSignature,
                hash: hashData,
                publicKey: publicKey
            )
            .bytes
        }
        if pass {
            expectation == expectedAPDU
        } else if `throw` {
            expectation.to(throwError())
        } else {
            expectation != expectedAPDU
        }
    }

    func testPsoVerifyDSA_ansix9p256r1_generated() throws {
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateRandomKey([kSecAttrKeyType: kSecAttrKeyTypeEC,
                                               kSecAttrKeyClass: kSecAttrKeyClassPublic,
                                               kSecAttrKeySizeInBits: 256] as CFDictionary, &error),
            let publicKey = SecKeyCopyPublicKey(key) else {
            Nimble.fail("Could not generate EC Key pair [256]")
            return
        }

        let hashData = Data([UInt8](repeating: 0x0, count: 32))
        let normalizedSignature = Data([UInt8](repeating: 0x0, count: 64))

        let info = try ECCurveInfo.parse(publicKey: publicKey)
        let signatureBody = try HealthCardCommand.PsoDSA.formatSignatureTemplate(
            signature: normalizedSignature, hash: hashData, curve: info
        )
        let expected = Data([0x0, 0x2A, 0x0, 0xA8, 0xB6] + signatureBody)

        expect {
            try HealthCardCommand.PsoDSA.verify(
                signature: normalizedSignature,
                hash: hashData,
                publicKey: publicKey
            )
            .bytes
        } == expected

        //
        // Check response codes
        let statusKeys = try HealthCardCommand.PsoDSA.verify(
            signature: normalizedSignature,
            hash: hashData,
            publicKey: publicKey
        )
        .responseStatuses.keys
        expect(statusKeys).to(contain([0x9000, 0x6A80]))
    }

    func testPsoVerifyDSA_ansix9p384r1_generated() {
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateRandomKey([kSecAttrKeyType: kSecAttrKeyTypeEC,
                                               kSecAttrKeyClass: kSecAttrKeyClassPublic,
                                               kSecAttrKeySizeInBits: 384] as CFDictionary, &error),
            let publicKey = SecKeyCopyPublicKey(key) else {
            Nimble.fail("Could not generate EC Key pair [384]")
            return
        }

        let hashData = Data([UInt8](repeating: 0x0, count: 48))
        let normalizedSignature = Data([UInt8](repeating: 0x0, count: 96))

        guard let info = try? ECCurveInfo.parse(publicKey: publicKey) else {
            Nimble.fail("Could not parseECCurveInfo")
            return
        }
        guard let signatureBody = try? HealthCardCommand.PsoDSA.formatSignatureTemplate(
            signature: normalizedSignature, hash: hashData, curve: info
        ) else {
            Nimble.fail("Failed to create signature template body")
            return
        }
        let expected = Data([0x0, 0x2A, 0x0, 0xA8, 0x0, 0x1, 0x3] + signatureBody)

        expect {
            try HealthCardCommand.PsoDSA.verify(
                signature: normalizedSignature,
                hash: hashData,
                publicKey: publicKey
            )
            .bytes
        } == expected
    }

    func testPsoVerifyDSA_wrong_hashsize() {
        let ecKeyData = ResourceLoader.loadResourceAsData(
            resource: "ansix9p256r1_ecpubkey",
            withExtension: "dat",
            directory: "DSA"
        )

        let signature = Data([UInt8](repeating: 0xF0, count: 64))
        let hash = Data([UInt8](repeating: 0xEF, count: 30))

        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(
            ecKeyData as CFData,
            [
                kSecAttrKeyType: kSecAttrKeyTypeEC,
                kSecAttrKeyClass: kSecAttrKeyClassPublic,
            ] as CFDictionary,
            &error
        ) else {
            Nimble.fail("Could not initialize ECPublicKey")
            return
        }

        expect {
            try HealthCardCommand.PsoDSA.verify(signature: signature, hash: hash, publicKey: key).bytes
        }.to(throwError(HealthCardCommandBuilder.InvalidArgument.wrongHashLength(30, expected: 32)))
    }

    func testPsoVerifyDSA_wrong_signaturesize() {
        let ecKeyData = ResourceLoader.loadResourceAsData(
            resource: "ansix9p256r1_ecpubkey",
            withExtension: "dat",
            directory: "DSA"
        )

        let signature = Data([UInt8](repeating: 0xF0, count: 66))
        let hash = Data([UInt8](repeating: 0xEF, count: 32))

        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(
            ecKeyData as CFData,
            [kSecAttrKeyType: kSecAttrKeyTypeEC, kSecAttrKeyClass: kSecAttrKeyClassPublic] as CFDictionary,
            &error
        ) else {
            Nimble.fail("Could not initialize ECPublicKey")
            return
        }

        expect {
            try HealthCardCommand.PsoDSA.verify(signature: signature, hash: hash, publicKey: key).bytes
        }.to(throwError(HealthCardCommandBuilder.InvalidArgument.wrongSignatureLength(66, expected: 64)))
    }
}

func throwError<T>() -> Nimble.Predicate<T> {
    Nimble.Predicate { actualExpression in
        var actualError: Error?
        do {
            _ = try actualExpression.evaluate()
        } catch {
            actualError = error
        }

        if let actualError = actualError {
            return PredicateResult(bool: true,
                                   message: ExpectationMessage.expectedCustomValueTo(
                                       "throw any error",
                                       actual: "<\(actualError)>"
                                   ))
        } else {
            return PredicateResult(bool: false,
                                   message: ExpectationMessage.expectedCustomValueTo(
                                       "throw any error",
                                       actual: "no error"
                                   ))
        }
    }
}

// swiftlint:disable:next file_length
extension String: @retroactive Error {}
