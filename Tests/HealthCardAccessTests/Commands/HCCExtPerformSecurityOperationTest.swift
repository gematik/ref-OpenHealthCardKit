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
import DataKit
import Foundation
import GemCommonsKit
@testable import HealthCardAccess
import Nimble
import Security
import XCTest

final class HCCExtPerformSecurityOperationTest: XCTestCase {
    // swiftlint:disable:previous type_body_length

    let dataLong = Data(repeating: 0xfa, count: 300)
    let bundle = Bundle(for: HCCExtPerformSecurityOperationTest.self)

    func testPsoChecksum_OptionDES() {
        let data = Data([0x1f, 0x2f, 0xff, 0xef])

        let expected = Data([0x0, 0x2a, 0x8e, 0x80, 0x4] + data + [0x0])
        expect {
            try HealthCardCommand.PsoChecksum.hashUsingDES(data: data).bytes
        } == expected

        let expectedLong = Data([0x0, 0x2a, 0x8e, 0x80, 0x0, 0x1, 0x2c] + dataLong + [0x0, 0x0])
        expect {
            try HealthCardCommand.PsoChecksum.hashUsingDES(data: self.dataLong).bytes
        } == expectedLong
    }

    func testPsoChecksum_AES() {
        let data = Data([0x1f, 0x2f, 0xff, 0xef])

        let expected = Data([0x0, 0x2a, 0x8e, 0x80, 0x5, 0x0] + data + [0x0])
        expect {
            try HealthCardCommand.PsoChecksum.hashUsingAES(incrementSSCmac: false, data: data)
                    .bytes
        } == expected

        let expectedLong = Data([0x0, 0x2a, 0x8e, 0x80, 0x0, 0x1, 0x2d, 0x1] + dataLong + [0x0, 0x0])
        expect {
            try HealthCardCommand.PsoChecksum.hashUsingAES(incrementSSCmac: true, data: self.dataLong)
                    .bytes
        } == expectedLong
    }

    func testPsoChecksumResponseStatus() {
        let data = Data([0x1f, 0x2f, 0xff, 0xef])

        expect {
            try HealthCardCommand.PsoChecksum.hashUsingAES(incrementSSCmac: false, data: data)
                    .responseStatuses.keys
        }.to(contain([0x6982, 0x6985, 0x6a81, 0x6a88, 0x9000]))
    }

    func testPsoDSA() {
        let data = Data([0x1f, 0x2f, 0xff, 0xef])

        let expected = Data([0x0, 0x2a, 0x9e, 0x9a, 0x4] + data + [0x0])
        expect {
            try HealthCardCommand.PsoDSA.sign(data).bytes
        } == expected

        let expectedLong = Data([0x0, 0x2a, 0x9e, 0x9a, 0x0, 0x1, 0x2c] + dataLong + [0x0, 0x0])
        expect {
            try HealthCardCommand.PsoDSA.sign(self.dataLong)
                    .bytes
        } == expectedLong
    }

    func testPsoDSAResponseStatus() {
        let data = Data([0x1f, 0x2f, 0xff, 0xef])
        expect {
            try HealthCardCommand.PsoDSA.sign(data).responseStatuses.keys
        }.to(contain([0x6400, 0x6982, 0x6985, 0x6a81, 0x6a88, 0x9000]))
    }

    func testPsoDecipher() {
        let data = Data([0x66])

        let expectedRsa = Data([0x0, 0x2a, 0x80, 0x86, 0x0, 0x0, 0x2, 0x0, 0x66, 0x0, 0x0])
        expect {
            try HealthCardCommand.PsoDecipher.decipherUsingRsa(cryptogram: data)
                    .bytes
        } == expectedRsa

        expect {
            try HealthCardCommand.PsoDecipher.decipherUsingRsa(cryptogram: self.dataLong)
                    .ne
        } == APDU.expectedLengthWildcardExtended

        let expectedElc = Data([0x0, 0x2a, 0x80, 0x86, 0x1, 0x66, 0x0])
        expect {
            try HealthCardCommand.PsoDecipher.decipherUsingElc(cryptogram: data)
                    .bytes
        } == expectedElc

        let expectedSymKey = Data([0x0, 0x2a, 0x80, 0x86, 0x2, 0x1, 0x66, 0x0])
        expect {
            try HealthCardCommand.PsoDecipher.decipherUsingSymmetricKey(cryptogram: data)
                    .bytes
        } == expectedSymKey

        expect {
            try HealthCardCommand.PsoDecipher.decipherUsingRsa(cryptogram: data)
                    .responseStatuses.keys
        }.to(contain(ResponseStatus.unsupportedFunction.code))
    }

    func testPsoEncipher_usingTransmittedRsaKey() {
        let dataToBeEnciphered = Data([0x66])
        let pubKeyData = "rsa_pub_key.der".loadAsResource(at: "PSO", bundle: bundle)
        var createError: Unmanaged<CFError>?
        guard let publicKey = SecKeyCreateWithData(pubKeyData as NSData,
                [kSecAttrKeyType: kSecAttrKeyTypeRSA,
                 kSecAttrKeyClass: kSecAttrKeyClassPublic
                ] as NSDictionary,
                &createError) else {
            Nimble.fail("Could not create public key with provided data")
            return
        }

        let apduEncipherRsaPkcs1v15 = "apduEncipherRsaPkcs1v15.dat".loadAsResource(at: "PSO", bundle: bundle)
        expect {
            try HealthCardCommand.PsoEncipher
                    .encipherUsingTransmittedRsaKeyPkcs1_v1_5(rsaPublicKey: publicKey,
                    data: dataToBeEnciphered)
                    .bytes
        } == apduEncipherRsaPkcs1v15

        // using transmitted RSA Oaep key
        let apduEncipherRsaOaep = "apduEncipherRsaOaep.dat".loadAsResource(at: "PSO", bundle: bundle)
        expect {
            try HealthCardCommand.PsoEncipher
                    .encipherUsingTransmittedRsaKeyOaep(rsaPublicKey: publicKey,
                    data: dataToBeEnciphered)
                    .bytes
        } == apduEncipherRsaOaep

        // test statuses
        expect {
            try HealthCardCommand.PsoEncipher
                    .encipherUsingTransmittedRsaKeyPkcs1_v1_5(rsaPublicKey: publicKey,
                    data: dataToBeEnciphered)
                    .responseStatuses.keys
        }.to(contain([0x9000, 0x6400, 0x6982, 0x6a81, 0x6a88]))
    }

    func testPsoEncipher_usingTransmittedElcKey() {
        let dataToBeEnciphered = Data([0x66])
        let pubKeyData = "elc_pub_key.der".loadAsResource(at: "PSO", bundle: bundle)
        var createError: Unmanaged<CFError>?
        guard let publicKey = SecKeyCreateWithData(pubKeyData as NSData,
                [kSecAttrKeyType: kSecAttrKeyTypeEC,
                 kSecAttrKeyClass: kSecAttrKeyClassPublic
                ] as NSDictionary,
                &createError) else {
            Nimble.fail("Could not create public key with provided data")
            return
        }

        let apduEncipherElc = "apduEncipherElc.dat".loadAsResource(at: "PSO", bundle: bundle)

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
        } == Data([0x0, 0x2a, 0x86, 0x80, 0x0, 0x0, 0x1, 0x66, 0x0, 0x0])
        expect {
            try HealthCardCommand.PsoEncipher.encipherUsingRsaKeyOnCard(data: self.dataLong)
                    .bytes
        } == Data([0x0, 0x2a, 0x86, 0x80, 0x0, 0x1, 0x2c] + dataLong + [0x0, 0x0])

        expect {
            try HealthCardCommand.PsoEncipher.encipherUsingElcKeyOnCard(data: dataToBeEnciphered)
                    .bytes
        } == Data([0x0, 0x2a, 0x86, 0x80, 0x1, 0x66, 0x0])
        expect {
            try HealthCardCommand.PsoEncipher.encipherUsingElcKeyOnCard(data: self.dataLong)
                    .bytes
        } == Data([0x0, 0x2a, 0x86, 0x80, 0x0, 0x1, 0x2c] + dataLong + [0x0, 0x0])

        expect {
            try HealthCardCommand.PsoEncipher.encipherUsingSymmetricKeyOnCard(data:
            dataToBeEnciphered)
                    .bytes
        } == Data([0x0, 0x2a, 0x86, 0x80, 0x1, 0x66, 0x0])
        expect {
            try HealthCardCommand.PsoEncipher.encipherUsingSymmetricKeyOnCard(data:
            self.dataLong)
                    .bytes
        } == Data([0x0, 0x2a, 0x86, 0x80, 0x0, 0x1, 0x2c] + dataLong + [0x0, 0x0])
    }

    func testPsoVerifyGemCvCertificate() {
        let filename = "CVC/GemCVC.der"
        let certPath = bundle.testResourceFilePath(in: "Resources", for: filename)
        guard let certData = try? certPath.readFileContents() else {
            Nimble.fail("Could not read: [\(filename)]")
            return
        }

        let expectedAPDU = Data([0x0, 0x2a, 0x0, 0xBE, 0xdc] + certData)
        expect {
            try HealthCardCommand.PsoCertificate.verify(cvc: try GemCvCertificate.from(data: certData))
                    .bytes
        } == expectedAPDU

        expect {
            try HealthCardCommand.PsoCertificate.verify(cvc: try GemCvCertificate.from(data: certData))
                    .responseStatuses.keys
        }.to(contain([0x63c0, 0x63c1, 0x63c2, 0x63c3, 0x63c4, 0x63c5, 0x63c6, 0x63c7, 0x63c8, 0x63c9, 0x63ca, 0x63cb,
                      0x63cc, 0x63cd, 0x63ce, 0x63cf, 0x9000, 0x6581, 0x6982, 0x6983, 0x6985, 0x6a80, 0x6a88]))
    }

    func testPsoVerifyChecksum() {
        let data = Data([0x1f, 0x2f, 0xff, 0xef])
        let mac = data + data
        let expectedAPDU = Data([0x0, 0x2a, 0x0, 0xa2, 0x10, 0x80, 0x4] + data + [0x8e, 0x8] + mac)

        expect {
            try HealthCardCommand.PsoChecksum.verify(data: data, mac: mac).bytes
        } == expectedAPDU

        expect {
            try HealthCardCommand.PsoChecksum.verify(data: data, mac: mac).responseStatuses.keys
        }.to(contain([0x9000, 0x6982, 0x6985, 0x6a80, 0x6a81, 0x6a88]))

        let expectedLong = Data([0x0, 0x2a, 0x0, 0xa2, 0x0, 0x1, 0x3a, 0x80, 0x82, 0x1, 0x2c] +
        dataLong + [0x8e, 0x8] + mac)
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
        (test: "ansix9p256r1", hash: "ansix9p256r1_hash.dat", normalized: "ansix9p256r1_signature_normalized.dat",
                key: "ansix9p256r1_ecpubkey.dat", expected: "ansix9p256r1_expected_apdu.dat", pass: true, throw: false),
        (test: "ansix9p384r1", hash: "ansix9p384r1_hash.dat", normalized: "ansix9p384r1_signature_normalized.dat",
                key: "ansix9p384r1_ecpubkey.dat", expected: "ansix9p384r1_expected_apdu.dat", pass: true, throw: false),
        (test: "brainpoolP256r1", hash: "brainpoolP256r1_hash.dat",
                normalized: "brainpoolP256r1_signature_normalized.dat", key: "brainpoolP256r1_ecpubkey.dat",
                expected: "brainpoolP256r1_expected_apdu.dat", pass: false, throw: false),
        (test: "brainpoolP384r1", hash: "brainpoolP384r1_hash.dat",
                normalized: "brainpoolP384r1_signature_normalized.dat", key: "brainpoolP384r1_ecpubkey.dat",
                expected: "brainpoolP384r1_expected_apdu.dat", pass: false, throw: false),
        (test: "brainpoolP512r1", hash: "brainpoolP512r1_hash.dat",
                normalized: "brainpoolP512r1_signature_normalized.dat", key: "brainpoolP512r1_ecpubkey.dat",
                expected: "brainpoolP512r1_expected_apdu.dat", pass: false, throw: true)
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

    func dasVerificationTest(_ testCase: DSATestParameter) {
        let hash = testCase.hash
        let signature = testCase.normalized
        let publicKey = testCase.key
        let expected = testCase.expected
        let pass = testCase.pass
        let `throw` = testCase.throw

        let path = "DSA"
        let hashData = hash.loadAsResource(at: path, bundle: bundle)
        let normalizedSignature = signature.loadAsResource(at: path, bundle: bundle)
        let publicKeyData = publicKey.loadAsResource(at: path, bundle: bundle)

        let expectedAPDU = expected.loadAsResource(at: path, bundle: self.bundle)
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

    func testPsoVerifyDSA_ansix9p256r1_generated() {
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

        guard let info = try? ECCurveInfo.parse(publicKey: publicKey) else {
            Nimble.fail("Could not parseECCurveInfo")
            return
        }
        guard let signatureBody = try? HealthCardCommand.PsoDSA.formatSignatureTemplate(
                signature: normalizedSignature, hash: hashData, curve: info) else {
            Nimble.fail("Failed to create signature template body")
            return
        }
        let expected = Data([0x0, 0x2a, 0x0, 0xa8, 0xb6] + signatureBody)

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
        expect {
            try HealthCardCommand.PsoDSA.verify(
                    signature: normalizedSignature,
                    hash: hashData,
                    publicKey: publicKey
            )
                    .responseStatuses.keys
        }.to(contain([0x9000, 0x6a80]))
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
                signature: normalizedSignature, hash: hashData, curve: info) else {
            Nimble.fail("Failed to create signature template body")
            return
        }
        let expected = Data([0x0, 0x2a, 0x0, 0xa8, 0x0, 0x1, 0x3] + signatureBody)

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
        let filename = "ec_pub_key.dat"
        let ecKeyData = filename.loadAsResource(at: "EC", bundle: bundle)

        let signature = Data([UInt8](repeating: 0xf0, count: 64))
        let hash = Data([UInt8](repeating: 0xef, count: 30))

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
        }.to(throwError(HealthCardCommandBuilder.InvalidArgument.wrongHashLength(30, expected: 32)))
    }

    func testPsoVerifyDSA_wrong_signaturesize() {
        let filename = "ec_pub_key.dat"
        let ecKeyData = filename.loadAsResource(at: "EC", bundle: bundle)

        let signature = Data([UInt8](repeating: 0xf0, count: 66))
        let hash = Data([UInt8](repeating: 0xef, count: 32))

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

    static let allTests = [
        ("testPsoChecksum_OptionDES", testPsoChecksum_OptionDES),
        ("testPsoChecksum_AES", testPsoChecksum_AES),
        ("testPsoChecksumResponseStatus", testPsoChecksumResponseStatus),
        ("testPsoDSA", testPsoDSA),
        ("testPsoDSAResponseStatus", testPsoDSAResponseStatus),
        ("testPsoDecipher", testPsoDecipher),
        ("testPsoEncipher_usingTransmittedRsaKey", testPsoEncipher_usingTransmittedRsaKey),
        ("testPsoEncipher_usingTransmittedElcKey", testPsoEncipher_usingTransmittedElcKey),
        ("testPsoEncipher_usingKeysOnCard", testPsoEncipher_usingKeysOnCard),
        ("testPsoVerifyGemCvCertificate", testPsoVerifyGemCvCertificate),
        ("testPsoVerifyChecksum", testPsoVerifyChecksum),
        ("testPsoVerifyDSA_parameterized", testPsoVerifyDSA_parameterized),
        ("testPsoVerifyDSA_ansix9p256r1_generated", testPsoVerifyDSA_ansix9p256r1_generated),
        ("testPsoVerifyDSA_ansix9p384r1_generated", testPsoVerifyDSA_ansix9p384r1_generated),
        ("testPsoVerifyDSA_wrong_hashsize", testPsoVerifyDSA_wrong_hashsize),
        ("testPsoVerifyDSA_wrong_signaturesize", testPsoVerifyDSA_wrong_signaturesize)
    ]

}

func throwError<T>() -> Predicate<T> {
    return Predicate { actualExpression in
        var actualError: Error?
        do {
            _ = try actualExpression.evaluate()
        } catch {
            actualError = error
        }

        if let actualError = actualError {
            return PredicateResult(bool: true, message: .expectedCustomValueTo("throw any error", "<\(actualError)>"))
        } else {
            return PredicateResult(bool: false, message: .expectedCustomValueTo("throw any error", "no error"))
        }
    }
}

extension String: Error {
}

// swiftlint:disable:this file_length
