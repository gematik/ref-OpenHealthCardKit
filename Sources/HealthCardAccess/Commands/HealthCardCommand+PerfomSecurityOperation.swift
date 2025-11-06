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
import Security

/// These commands represent the Perform Security Commands (PSO) in gemSpec_COS#14.8 "Kryptoboxkommandos".
extension HealthCardCommand {
    /// Expected length wildcard, short or extended
    public static let expectedLengthWildcard = 0

    /// Builder representing Compute Cryptographic Checksum in gemSpec_COS#14.8.1
    public enum PsoChecksum {
        static let cla: UInt8 = 0x0
        static let ins: UInt8 = 0x2A
        static let p1: UInt8 = 0x8E // swiftlint:disable:this identifier_name
        static let p2: UInt8 = 0x80 // swiftlint:disable:this identifier_name

        /// Use case Compute Cryptographic Checksum gemSpec_COS#14.8.1
        /// - Parameters:
        ///     - flag: specify whether the SSC mac should increment
        ///     - data: The data to protect
        /// - Returns: The Checksum Command
        public static func hashUsingAES(incrementSSCmac flag: Bool, data: Data) throws -> HealthCardCommand {
            let body = Data([flag ? 0x1 : 0x0]) + data

            return try builder()
                .set(data: body)
                .set(responseStatuses: responseMessages)
                .set(ne: expectedLengthWildcard) // Wildcard short/extended
                .build()
        }

        /// Use case Compute Cryptographic Checksum gemSpec_COS#14.8.1
        /// - Parameters:
        ///     - data: The data to protect
        /// - Returns: The Checksum command
        public static func hashUsingDES(data: Data) throws -> HealthCardCommand {
            try builder()
                .set(data: data)
                .set(responseStatuses: responseMessages)
                .set(ne: expectedLengthWildcard) // Wildcard short/extended
                .build()
        }

        /// Use case Verify Cryptographic Checksum gemSpec_COS#14.8.8
        /// - Parameters:
        ///     - data: The (mac-protected) message to verify
        ///     - hash: The MAC hash 8-Octets
        /// - Throws: When hash is not 8-Octets long
        /// - Returns: The Verify Checksum command
        public static func verify(data: Data, mac hash: Data) throws -> HealthCardCommand {
            guard hash.count == 8 else {
                throw HealthCardCommandBuilder.InvalidArgument.wrongMACLength(hash.count)
            }
            let inputTemplate = try data.asn1encode(tag: .taggedTag(0)).serialize() +
                hash.asn1encode(tag: .taggedTag(0xE)).serialize()
            return try builder()
                .set(p1: 0x0)
                .set(p2: 0xA2)
                .set(data: inputTemplate)
                .set(ne: nil)
                .build()
        }

        static func builder() -> HealthCardCommandBuilder {
            HealthCardCommandBuilder()
                .set(cla: cla)
                .set(ins: ins)
                .set(p1: p1)
                .set(p2: p2)
                .set(responseStatuses: responseMessages)
        }

        static let responseMessages: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
            ResponseStatus.noKeyReference.code: .noKeyReference,
            ResponseStatus.unsupportedFunction.code: .unsupportedFunction,
            ResponseStatus.keyNotFound.code: .keyNotFound,
            ResponseStatus.verificationError.code: .verificationError,
        ]
    }

    /// Builder representing Compute Digital Signature in gemSpec_COS#14.8.2
    /// And Verify Digital Signature in gemSpec_COS#14.8.9
    public enum PsoDSA {
        static let cla: UInt8 = 0x0
        static let ins: UInt8 = 0x2A
        static let p1: UInt8 = 0x9E // swiftlint:disable:this identifier_name
        static let p2: UInt8 = 0x9A // swiftlint:disable:this identifier_name

        /// Use case compute a digital signature without "message recovery" gemSpec_COS#14.8.2.1
        ///
        /// - Parameter data: the value to sign
        /// - Returns: PSO Compute Digital Signature Command
        public static func sign(_ data: Data) throws -> HealthCardCommand {
            try HealthCardCommandBuilder()
                .set(cla: cla)
                .set(ins: ins)
                .set(p1: p1)
                .set(p2: p2)
                .set(data: data)
                .set(ne: expectedLengthWildcard) // Wildcard short/extended
                .set(responseStatuses: responseMessages)
                .build()
        }

        /// Use case verify an ELC signature gemSpec_COS#14.8.9.1
        /// - Parameters:
        ///     - signature: (normalized) signature hash to verify
        ///     - hash: the signed hash value
        ///     - publicKey: a Public SecKey
        /// - Note: that (only) ansix9p256r1, ansix9p384r1 curves are supported
        /// - Throws: `HealthCardCommandBuilder.InvalidArgument`
        ///             or `ECCurveInfo.InvalidArgument` when wrong signature, hash or SecKey is passed
        /// - Returns: Verify EC DSA command
        public static func verify(signature: Data, hash: Data, publicKey: SecKey) throws -> HealthCardCommand {
            let curve = try ECCurveInfo.parse(publicKey: publicKey)

            // Validate Hash and Signature length to be plausible for the ECCurveInfo found through the algId
            guard curve.info.validate(hash: hash) else {
                throw HealthCardCommandBuilder.InvalidArgument.wrongHashLength(hash.count,
                                                                               expected: curve.info.hashSize)
            }
            guard curve.info.validate(signature: signature) else {
                throw HealthCardCommandBuilder.InvalidArgument.wrongSignatureLength(signature.count,
                                                                                    expected: curve.info.signatureSize)
            }

            let signatureTemplate = try formatSignatureTemplate(signature: signature, hash: hash, curve: curve)

            return try HealthCardCommandBuilder()
                .set(cla: cla)
                .set(ins: ins)
                .set(p1: 0x0)
                .set(p2: 0xA8)
                .set(data: signatureTemplate)
                .set(ne: nil)
                .set(responseStatuses: responseMessages)
                .build()
        }

        static func formatSignatureTemplate(signature: Data, hash: Data, curve: ECCurve) throws -> Data {
            let encodedHash = try ASN1Kit.create(tag: .taggedTag(16), data: .primitive(hash)).serialize()
            let encodedOID = try curve.info.oid.asn1encode(tag: nil).serialize()
            let encodedPublicKey = try ASN1Kit.create(tag: .applicationTag(73), data: .constructed(
                [curve.publicKey.asn1encode(tag: .taggedTag(6))]
            ))
                .serialize()
            let encodedPublicKeyWrapper = try ASN1Kit.create(tag: .taggedTag(28), data: .primitive(encodedPublicKey))
                .serialize()
            let encodedSignature = try signature.asn1encode(tag: .taggedTag(30)).serialize()
            return encodedOID + encodedHash + encodedPublicKeyWrapper + encodedSignature
        }

        static let responseMessages: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.keyInvalid.code: .keyInvalid,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
            ResponseStatus.noKeyReference.code: .noKeyReference,
            ResponseStatus.unsupportedFunction.code: .unsupportedFunction,
            ResponseStatus.keyNotFound.code: .keyNotFound,
            ResponseStatus.verificationError.code: .verificationError,
        ]
    }

    /// Builders representing Decipher command in gemSpec_COS#14.8.3
    public enum PsoDecipher {
        static let cla: UInt8 = 0x0
        static let ins: UInt8 = 0x2A
        static let p1: UInt8 = 0x80 // swiftlint:disable:this identifier_name
        static let p2: UInt8 = 0x86 // swiftlint:disable:this identifier_name

        static func builder() -> HealthCardCommandBuilder {
            HealthCardCommandBuilder()
                .set(cla: cla)
                .set(ins: ins)
                .set(p1: p1)
                .set(p2: p2)
                .set(responseStatuses: responseMessages)
        }

        /// Use case Decipher using RSA gemSpec_COS#14.8.3.1
        /// - Parameters:
        ///     - cryptogram: number of octets must be identical to OctetLength(n), n being the modulus of the key
        public static func decipherUsingRsa(cryptogram: Data) throws -> HealthCardCommand {
            let data = Data([0x0]) + cryptogram
            let expectedLength = APDU.expectedLengthWildcardExtended
            return try builder()
                .set(data: data)
                .set(ne: expectedLength)
                .build()
        }

        /// Use case Decipher using ELC gemSpec_COS#14.8.3.2
        /// - Parameters:
        ///     - cryptogram: specified as in gemSpec_COS#N090.300
        public static func decipherUsingElc(cryptogram: Data) throws -> HealthCardCommand {
            try builder()
                .set(data: cryptogram)
                .set(ne: expectedLengthWildcard)
                .build()
        }

        /// Use case Decipher using a symmetric key gemSpec_COS#14.8.3.3
        /// - Parameters:
        ///     - cryptogram: number of octets must be a multiple of the block length of the used algorithm
        public static func decipherUsingSymmetricKey(cryptogram: Data) throws -> HealthCardCommand {
            let data = Data([0x1]) + cryptogram
            return try builder()
                .set(data: data)
                .set(ne: expectedLengthWildcard)
                .build()
        }

        static let responseMessages: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.keyInvalid.code: .keyInvalid,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
            ResponseStatus.noKeyReference.code: .noKeyReference,
            ResponseStatus.wrongCipherText.code: .wrongCipherText,
            ResponseStatus.unsupportedFunction.code: .unsupportedFunction,
            ResponseStatus.keyNotFound.code: .keyNotFound,
        ]
    }

    /// Builders representing Encipher command in gemSpec_COS#14.8.4
    public enum PsoEncipher {
        static let cla: UInt8 = 0x0
        static let ins: UInt8 = 0x2A
        static let p1: UInt8 = 0x86 // swiftlint:disable:this identifier_name
        static let p2: UInt8 = 0x80 // swiftlint:disable:this identifier_name

        static func builder() -> HealthCardCommandBuilder {
            HealthCardCommandBuilder()
                .set(cla: cla)
                .set(ins: ins)
                .set(p1: p1)
                .set(p2: p2)
                .set(responseStatuses: responseMessages)
        }

        /// Use case Encipher using transmitted RSA key Pkcs1_v1_5 gemSpec_COS#14.8.4.1_1
        /// - Parameters:
        ///     - rsaPublicKey: SecKey must conform to PKCS #1 format for an RSA key
        ///     - data: data to be enciphered
        /// - Note: Key data must be in PKCS #1 format for an RSA key, see Apple documentation on SecKeyCreateWithData
        /// - Returns: The command
        public static func encipherUsingTransmittedRsaKeyPkcs1_v1_5(rsaPublicKey: SecKey, data: Data) throws
            -> HealthCardCommand {
            let plainDo = try computePlainDoForRsaEncipher(algId: 0x1, publicKey: rsaPublicKey, data: data)
            return try builder()
                .set(data: plainDo)
                .set(ne: 0)
                .build()
        }

        /// Use case Encipher using transmitted RSA key Oaep gemSpec_COS#14.8.4.1_2
        /// - Parameters:
        ///     - rsaPublicKey: SecKey must conform to PKCS #1 format for an RSA key
        ///     - data: data to be enciphered
        /// - Note: Key data must be in PKCS #1 format for an RSA key, see Apple documentation on SecKeyCreateWithData
        /// - Returns: The command
        public static func encipherUsingTransmittedRsaKeyOaep(rsaPublicKey: SecKey, data: Data) throws
            -> HealthCardCommand {
            let plainDo = try computePlainDoForRsaEncipher(algId: 0x5, publicKey: rsaPublicKey, data: data)
            return try builder()
                .set(data: plainDo)
                .set(ne: 0)
                .build()
        }

        /// Use case Encipher using transmitted ELC key gemSpec_COS#14.8.4.2
        /// - Parameters:
        ///     - elcPublicKey
        ///     - data: data to be enciphered
        /// - Returns: The command
        public static func encipherUsingTransmittedElcKey(elcPublicKey: SecKey, data: Data) throws
            -> HealthCardCommand {
            let plainDo = try computePlainDoElcEncipher(publicKey: elcPublicKey, data: data)
            return try builder()
                .set(data: plainDo)
                .set(ne: APDU.expectedLengthWildcardExtended)
                .build()
        }

        /// Use cases Encipher using a RSA key saved on card gemSpec_COS#14.8.4.3
        /// - Parameters:
        ///      - data: data to be enciphered
        /// - Returns: The command
        public static func encipherUsingRsaKeyOnCard(data: Data) throws -> HealthCardCommand {
            try builder()
                .set(data: data)
                .set(ne: APDU.expectedLengthWildcardExtended)
                .build()
        }

        /// Use cases Encipher using a Elc key saved on card gemSpec_COS#14.8.4.4
        /// - Parameters:
        ///      - data: data to be enciphered
        /// - Returns: The command
        public static func encipherUsingElcKeyOnCard(data: Data) throws -> HealthCardCommand {
            try builder()
                .set(data: data)
                .set(ne: 0)
                .build()
        }

        /// Use cases Encipher using a symmetric key saved on card gemSpec_COS#14.8.4.5
        /// - Parameters:
        ///     - dataToBeEnciphered
        /// - Returns: The command
        public static func encipherUsingSymmetricKeyOnCard(data: Data) throws -> HealthCardCommand {
            try builder()
                .set(data: data)
                .set(ne: 0)
                .build()
        }

        private static let responseMessages: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.encipherError.code: .encipherError,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
            ResponseStatus.unsupportedFunction.code: .unsupportedFunction,
            ResponseStatus.keyNotFound.code: .keyNotFound,
        ]

        // gemSpec_COS#N091.700{b, c}
        private static func computePlainDoForRsaEncipher(algId: UInt8,
                                                         publicKey: SecKey,
                                                         data: Data) throws -> Data {
            // Extract values from SecKey, key must be public and of type RSA
            guard let pubKeyAttributes = SecKeyCopyAttributes(publicKey) as? [String: Any],
                  let valueData = pubKeyAttributes[kSecValueData as String] as? Data,
                  let keySizeInBits = pubKeyAttributes[kSecAttrKeySizeInBits as String] as? Int,
                  pubKeyAttributes[kSecAttrType as String] as? String == kSecAttrKeyTypeRSA as String,
                  pubKeyAttributes[kSecAttrKeyClass as String] as? String == kSecAttrKeyClassPublic as String else {
                throw HealthCardCommandBuilder.InvalidArgument.unsupportedKey(publicKey)
            }

            // parse public key data
            let asn1 = try ASN1Decoder.decode(asn1: valueData)
            guard let items = asn1.data.items, items.count > 1
            else {
                throw HealthCardCommandBuilder.InvalidArgument.unsupportedKey(publicKey)
            }
            let modulus = try ASN1Int(from: items[0])
            let exponent = try ASN1Int(from: items[1])

            // build plainDo
            let algDo = Data([algId]).asn1encode(tag: .taggedTag(0x0))
            let pukNDo = modulus.rawInt.normalize(to: keySizeInBits / 8).asn1encode(tag: .taggedTag(1))
            let pukEDo = exponent.rawInt.asn1encode(tag: .taggedTag(2))
            let keyDo = ASN1Kit.create(tag: .applicationTag(0x49), data: .constructed([pukNDo, pukEDo]))
            let mDo = data.asn1encode(tag: .taggedTag(0x0))
            let plainDo = ASN1Kit.create(tag: .taggedTag(0x00), data: .constructed([algDo, keyDo, mDo]))

            return try plainDo.serialize()
        }

        // gemSpec_COS#N091.700d
        private static func computePlainDoElcEncipher(publicKey: SecKey, data: Data) throws -> Data {
            // Extract values from SecKey, key must be public and of type EC
            guard let pubKeyAttributes = SecKeyCopyAttributes(publicKey) as? [String: Any],
                  let keySizeInBits = pubKeyAttributes[kSecAttrKeySizeInBits as String] as? Int,
                  pubKeyAttributes[kSecAttrType as String] as? String == kSecAttrKeyTypeEC as String,
                  pubKeyAttributes[kSecAttrKeyClass as String] as? String == kSecAttrKeyClassPublic as String else {
                throw HealthCardCommandBuilder.InvalidArgument.unsupportedKey(publicKey)
            }

            let curve = try ECCurveInfo.parse(publicKey: publicKey)

            // build plainDo
            let algDo = Data([0xB]).asn1encode(tag: .taggedTag(0x0))
            let oidDo = try curve.info.oid.asn1encode(tag: nil)
            let pobDo = curve.publicKey.normalize(to: keySizeInBits / 8).asn1encode(tag: .taggedTag(6))
            let keyDo = ASN1Kit.create(tag: .applicationTag(0x49), data: .constructed([pobDo]))
            let mDo = data.asn1encode(tag: .taggedTag(0x0))
            let plainDo = ASN1Kit.create(tag: .taggedTag(0x00), data: .constructed([algDo, oidDo, keyDo, mDo]))

            return try plainDo.serialize()
        }
    }

    /// Builder(s) representing Verify Certificate in gemSpec_COS#14.8.7
    public enum PsoCertificate {
        static let cla: UInt8 = 0x0
        static let ins: UInt8 = 0x2A
        static let p1: UInt8 = 0x0 // swiftlint:disable:this identifier_name
        static let p2: UInt8 = 0xBE // swiftlint:disable:this identifier_name

        /// Use Case 14.8.7.2: Import of ELC-key by certificate
        /// - Parameter certificate: The CVC ELC certificate to verify/import
        /// - Returns: The command
        public static func verify(cvc certificate: GemCvCertificate) throws -> HealthCardCommand {
            try HealthCardCommandBuilder()
                .set(cla: cla)
                .set(ins: ins)
                .set(p1: p1)
                .set(p2: p2)
                .set(data: try certificate.asn1encode())
                .set(ne: nil)
                .set(responseStatuses: responseMessages)
                .build()
        }

        private static let responseMessages: [UInt16: ResponseStatus] = [
            ResponseStatus.updateRetryWarningCount00.code: .updateRetryWarningCount00,
            ResponseStatus.updateRetryWarningCount01.code: .updateRetryWarningCount01,
            ResponseStatus.updateRetryWarningCount02.code: .updateRetryWarningCount02,
            ResponseStatus.updateRetryWarningCount03.code: .updateRetryWarningCount03,
            ResponseStatus.updateRetryWarningCount04.code: .updateRetryWarningCount04,
            ResponseStatus.updateRetryWarningCount05.code: .updateRetryWarningCount05,
            ResponseStatus.updateRetryWarningCount06.code: .updateRetryWarningCount06,
            ResponseStatus.updateRetryWarningCount07.code: .updateRetryWarningCount07,
            ResponseStatus.updateRetryWarningCount08.code: .updateRetryWarningCount08,
            ResponseStatus.updateRetryWarningCount09.code: .updateRetryWarningCount09,
            ResponseStatus.updateRetryWarningCount10.code: .updateRetryWarningCount10,
            ResponseStatus.updateRetryWarningCount11.code: .updateRetryWarningCount11,
            ResponseStatus.updateRetryWarningCount12.code: .updateRetryWarningCount12,
            ResponseStatus.updateRetryWarningCount13.code: .updateRetryWarningCount13,
            ResponseStatus.updateRetryWarningCount14.code: .updateRetryWarningCount14,
            ResponseStatus.updateRetryWarningCount15.code: .updateRetryWarningCount15,
            ResponseStatus.success.code: .success,
            ResponseStatus.memoryFailure.code: .memoryFailure,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
            ResponseStatus.keyExpired.code: .keyExpired,
            ResponseStatus.noKeyReference.code: .noKeyReference,
            ResponseStatus.verificationError.code: .verificationError,
            ResponseStatus.inconsistentKeyReference.code: .inconsistentKeyReference,
        ]
    }
}
