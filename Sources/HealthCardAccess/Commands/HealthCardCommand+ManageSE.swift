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
import GemCommonsKit

extension HealthCardCommand {

    /// Use case Manage Security Environment - gemSpec_COS#14.9.9
    public struct ManageSE {
        private static let cla: UInt8 = 0x0
        private static let ins: UInt8 = 0x22

        /// Change/Set the Security Environment - gemSpec_COS#14.9.9.1
        /// - Parameter number: SE identifier [1, 4] (N007.900)
        /// - Returns: Set environment command
        public static func setEnvironment(number: Int) throws -> HealthCardCommand {
            let range = 1..<5
            guard range ~= number else {
                throw HealthCardCommandBuilder.InvalidArgument.illegalValue(number, for: "SE", expected: range)
            }
            return try builder()
                    .set(p1: 0xf3)
                    .set(p2: UInt8(number))
                    .build()
        }

        /// Select internal key for symmetric authentication - gemSpec_COS#14.9.9.2
        /// - Parameters:
        ///     - symmetricKey: The key reference
        ///     - dfSpecific: Whether the key is dfSpecific or global
        ///     - algorithm: select the algorithm to be used for the internal authentication (N100.300)
        /// - Returns: The select key command
        public static func selectInternal(symmetricKey: Key, dfSpecific: Bool, algorithm: PSOAlgorithm) throws
                        -> HealthCardCommand {
            return try select(key: symmetricKey.calculateKeyReference(dfSpecific: dfSpecific).bytes,
                              algorithm: algorithm,
                              tag: .taggedTag(3))
                    .set(p1: 0x41)
                    .build()
        }

        /// Select internal key for asymmetric authentication - gemSpec_COS#14.9.9.3
        /// - Parameters:
        ///     - asymmetricKey: The key reference
        ///     - dfSpecific: Whether the key is dfSpecific or global
        ///     - algorithm: select the algorithm to be used for the internal authentication (N100.800)
        /// - Returns: The select key command
        public static func selectInternal(asymmetricKey: Key, dfSpecific: Bool, algorithm: PSOAlgorithm) throws
                        -> HealthCardCommand {
            return try select(key: asymmetricKey.calculateKeyReference(dfSpecific: dfSpecific).bytes,
                              algorithm: algorithm,
                              tag: .taggedTag(4))
                    .set(p1: 0x41)
                    .build()
        }

        /// Select external key for symmetric authentication - gemSpec_COS#14.9.9.4
        /// - Parameters:
        ///     - symmetricKey: The key reference
        ///     - dfSpecific: Whether the key is dfSpecific or global
        ///     - algorithm: select the algorithm to be used for the internal authentication (N101.300)
        /// - Returns: The select key command
        public static func selectExternal(symmetricKey: Key, dfSpecific: Bool, algorithm: PSOAlgorithm) throws
                        -> HealthCardCommand {
            return try select(key: symmetricKey.calculateKeyReference(dfSpecific: dfSpecific).bytes,
                              algorithm: algorithm,
                              tag: .taggedTag(3))
                    .set(p1: 0x81)
                    .build()
        }

        /// Select external key for asymmetric authentication - gemSpec_COS#14.9.9.5
        /// - Parameters:
        ///     - referenceKey: The key identifier.
        ///         Must be 12 bytes long (E.g. GemCvCertificate.CVCBody.certificateHolderReference) (N101.700)
        ///     - dfSpecific: Whether the key is dfSpecific or global
        ///     - algorithm: select the algorithm to be used for the internal authentication (N101.800)
        /// - Returns: The select key command
        public static func selectExternal(referenceKey: Data, algorithm: PSOAlgorithm) throws
                        -> HealthCardCommand {
            guard referenceKey.count == 12 else {
                throw HealthCardCommandBuilder.InvalidArgument.illegalSize(referenceKey.count, expected: 12)
            }
            return try select(key: referenceKey, algorithm: algorithm, tag: .taggedTag(3))
                    .set(p1: 0x81)
                    .build()
        }

        /// Select symmetric key for mutual authentication - gemSpec_COS#14.9.9.6
        /// - Parameters:
        ///     - symmetricKey: The key identifier. (N102.200)
        ///     - dfSpecific: Whether the key is dfSpecific or global
        ///     - algorithm: select the algorithm to be used for the internal authentication (N102.300)
        /// - Returns: The select key command
        public static func selectMutual(symmetricKey: Key, dfSpecific: Bool, algorithm: PSOAlgorithm) throws
                        -> HealthCardCommand {
            return try select(key: symmetricKey.calculateKeyReference(dfSpecific: dfSpecific).bytes,
                              algorithm: algorithm,
                              tag: .taggedTag(3))
                    .set(p1: 0x81)
                    .build()
        }

        private static func select(key: Data, algorithm: PSOAlgorithm?, tag: ASN1DecodedTag) throws
                        -> HealthCardCommandBuilder {
            let keySerialized = try ASN1Kit.create(tag: tag, data: .primitive(key)).serialize()
            let algIdSerialized: Data?
            if let algorithm = algorithm {
                algIdSerialized = try ASN1Kit.create(tag: .taggedTag(0), data: .primitive(algorithm.identifier.bytes))
                        .serialize()
            } else {
                algIdSerialized = nil
            }
            return builder()
                    .set(data: keySerialized + (algIdSerialized ?? Data()))
                    .set(p2: 0xa4)
        }

        /// Select symmetric key for PACE authentication without specifying the curve - gemSpec_COS#14.9.9.7
        /// - Parameters:
        ///     - symmetricKey: The key Identifier
        ///     - dfSpecific: Whether the key is dfSpecific or global
        ///     - oid: PACE identifier (N102.440)
        /// - Returns: The select key command
        public static func selectPACE(symmetricKey: Key, dfSpecific: Bool, oid: ASN1Kit.ObjectIdentifier) throws
                        -> HealthCardCommand {
            let serializedOID = try ASN1Kit.create(tag: .taggedTag(0), data: oid.asn1encode(tag: nil).data).serialize()
            let serializedKey =
                    try ASN1Kit.create(
                                    tag: .taggedTag(3),
                                    data: .primitive(symmetricKey.calculateKeyReference(dfSpecific: dfSpecific).bytes)
                            )
                            .serialize()
            return try builder()
                    .set(p1: 0xc1)
                    .set(p2: 0xa4)
                    .set(data: serializedOID + serializedKey)
                    .build()
        }

        /// Domain Id parameter = gemSpec_COS#14.9.9.8 N102.454
        public enum DomainId: UInt8 {
            case brainpoolP256r1 = 0xD
            case brainpoolP384r1 = 0x10
            case brainpoolP512r1 = 0x11
        }

        /// Select symmetric key for PACE authentication with domain - gemSpec_COS#14.9.9.8
        /// - Parameters:
        ///     - symmetricKey: The key Identifier
        ///     - dfSpecific: Whether the key is dfSpecific or global
        ///     - oid: PACE identifier (N102.440)
        ///     - domain: specify the elliptic curve to use
        /// - Returns: The select key command
        public static func selectPACE(
                symmetricKey: Key,
                dfSpecific: Bool,
                oid: ASN1Kit.ObjectIdentifier,
                domain: DomainId
        ) throws -> HealthCardCommand {
            let serializedDomain = try ASN1Kit.create(tag: .taggedTag(4), data: .primitive(domain.rawValue.bytes))
                    .serialize()
            return try HealthCardCommandBuilder.builder(from: selectPACE(symmetricKey: symmetricKey,
                                                                         dfSpecific: dfSpecific,
                                                                         oid: oid))
                    .add(data: serializedDomain)
                    .build()

        }

        /// Select signing key for signing - gemSpec_COS#14.9.9.9
        /// - Parameters:
        ///     - key: The key Identifier (N102.700)
        ///     - dfSpecific: Whether the key is dfSpecific or global
        ///     - algorithm: select the algorithm to be used for signing operations (N102.800)
        /// - Returns: The select key command
        public static func selectSigning(key: Key, dfSpecific: Bool, algorithm: PSOAlgorithm) throws
                        -> HealthCardCommand {
            return try select(key: key.calculateKeyReference(dfSpecific: dfSpecific).bytes,
                              algorithm: algorithm,
                              tag: .taggedTag(4))
                    .set(p1: 0x41)
                    .set(p2: 0xb6)
                    .build()
        }

        /// Select CVC key - gemSpec_COS#14.9.9.10
        /// - Parameters:
        ///     - referenceKey: The key identifier.
        ///         Must be 8 bytes long (E.g. GemCvCertificate.CVCBody.certificateAuthorityReference) (N103.200)
        /// - Returns: The select key command
        public static func selectCVC(referenceKey: Data) throws
                        -> HealthCardCommand {
            guard referenceKey.count == 8 else {
                throw HealthCardCommandBuilder.InvalidArgument.illegalSize(referenceKey.count, expected: 8)
            }
            return try select(key: referenceKey, algorithm: nil, tag: .taggedTag(3))
                    .set(p1: 0x81)
                    .set(p2: 0xb6)
                    .build()
        }

        /// Select decipher key for decrypting - gemSpec_COS#14.9.9.11
        /// - Parameters:
        ///     - key: The key Identifier (N103.600)
        ///     - dfSpecific: Whether the key is dfSpecific or global
        ///     - algorithm: select the algorithm to be used for decipher operations (N103.700)
        /// - Returns: The select decipher key command
        public static func selectDecipher(key: Key, dfSpecific: Bool, algorithm: PSOAlgorithm) throws
                        -> HealthCardCommand {
            return try select(key: key.calculateKeyReference(dfSpecific: dfSpecific).bytes,
                              algorithm: algorithm,
                              tag: .taggedTag(4)
            )
                    .set(p1: 0x41)
                    .set(p2: 0xb8)
                    .build()
        }

        /// Select encipher key for encrypting - gemSpec_COS#14.9.9.12
        /// - Parameters:
        ///     - key: The key identifier.
        ///         Must be 12 bytes long (E.g. GemCvCertificate.CVCBody.certificateHolderReference) (N103.840)
        ///     - algorithm: select the algorithm to be used for encipher operations (N103.845)
        /// - Returns: The select encipher key command
        public static func selectEncipher(key: Data, algorithm: PSOAlgorithm) throws -> HealthCardCommand {
            return try select(key: key, algorithm: algorithm, tag: .taggedTag(3))
                    .set(p1: 0x81)
                    .set(p2: 0xb8)
                    .build()
        }

        private static func builder() -> HealthCardCommandBuilder {
            return HealthCardCommandBuilder().set(cla: cla).set(ins: ins).set(responseStatuses: responseStatuses)
        }

        private static let responseStatuses: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.unsupportedFunction.code: .unsupportedFunction,
            ResponseStatus.keyNotFound.code: .keyNotFound
        ]
    }
}
