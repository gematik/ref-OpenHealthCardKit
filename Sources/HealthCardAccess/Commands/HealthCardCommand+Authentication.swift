//
//  Copyright (c) 2021 gematik GmbH
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
import CardReaderProviderApi
import Foundation

extension HealthCardCommand {
    /// These builders represent the commands in gemSpec_COS#14.7 "Komponentenauthentisierung".
    public struct Authentication {
        /// Use-case 14.7.1 External Mutual Authentication command - gemSpec_COS#14.7.1
        /// - Parameters:
        ///     - cmdData: data from the external entity to verify on the target card (N083.402 or N083.600)
        //      - flag: whether to expect response data
        /// - Returns: the external mutual authentication command
        public static func externalMutualAuthentication(_ cmdData: Data, expectResponse flag: Bool = false) throws
            -> HealthCardCommand {
                try builder()
                    .set(data: cmdData)
                    .set(ne: flag ? APDU.expectedLengthWildcardShort : nil)
                    .set(responseStatuses: externalResponseMessages)
                    .build()
            }

        private static let externalResponseMessages: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.authenticationFailure.code: .authenticationFailure,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
            ResponseStatus.keyExpired.code: .keyExpired,
            ResponseStatus.noKeyReference.code: .noKeyReference,
            ResponseStatus.unsupportedFunction.code: .unsupportedFunction,
            ResponseStatus.keyNotFound.code: .keyNotFound,
        ]

        /// Use-case 14.7.4 Internal Authentication command - gemSpec_COS#14.7.4
        /// - Parameters:
        ///     - token: data to verify by the target card (N086.200)
        /// - Returns: the internal authentication command
        public static func internalAuthenticate(_ token: Data) throws -> HealthCardCommand {
            try builder()
                .set(ins: 0x88)
                .set(data: token)
                .set(ne: 0)
                .set(responseStatuses: internalResponseMessages)
                .build()
        }

        private static let internalResponseMessages: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.keyInvalid.code: .keyInvalid,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
            ResponseStatus.noKeyReference.code: .noKeyReference,
            ResponseStatus.wrongToken.code: .wrongToken,
            ResponseStatus.unsupportedFunction.code: .unsupportedFunction,
            ResponseStatus.keyNotFound.code: .keyNotFound,
        ]

        private static func builder() -> HealthCardCommandBuilder {
            HealthCardCommandBuilder()
                .set(cla: 0x0)
                .set(ins: 0x82)
                .set(p1: 0x0)
                .set(p2: 0x0)
        }
    }

    /// Use-case ELC #14.7.2.2 and #14.7.2.3
    public struct ELC {
        /// Mutual authentication with ELC - step 1 #14.7.2.2.1
        /// - Parameter keyRef: 12-bytes long public key reference
        /// - Returns: the ELC step 1 command
        public static func step1a(keyRef: Data) throws -> HealthCardCommand {
            guard keyRef.count == 12 else {
                throw HealthCardCommandBuilder.InvalidArgument.illegalSize(keyRef.count, expected: 12)
            }
            let tag = try ASN1Kit.create(
                tag: .applicationTag(0x1C),
                data: .constructed([ASN1Kit.create(tag: .privateTag(3), data: .primitive(keyRef))])
            )
            .serialize()
            return try builder()
                .set(ne: APDU.expectedLengthWildcardShort)
                .set(data: tag)
                .build()
        }

        /// Exchange session key - step 2 #14.7.2.2.2
        /// - Parameter ephemeralPK: the point on the curve of the public key exchanged
        /// - Returns: the ELC step 2 command
        public static func step2a(ephemeralPK: Data) throws -> HealthCardCommand {
            let tag = try ASN1Kit.create(
                tag: .applicationTag(0x1C),
                data: .constructed([ASN1Kit.create(tag: .taggedTag(5), data: .primitive(ephemeralPK))])
            )
            .serialize()
            return try builder()
                .set(data: tag)
                .build()
        }

        private static func builder() -> HealthCardCommandBuilder {
            HealthCardCommandBuilder()
                .set(cla: 0x10)
                .set(ins: 0x86)
                .set(responseStatuses: [ResponseStatus.success.code: .success])
        }

        /// Start ELC mutual authentication - step 1b #14.7.2.3.1
        /// - Returns: ELC step 1b command
        public static func step1b() -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! builder()
                .set(data: Data([0x7C, 0x2, 0x81, 0x0]))
                .set(ne: APDU.expectedLengthWildcardShort)
                .build()
        }

        /// Finish ELC authentication - step 2b #14.7.2.3.2
        /// - Parameter data: the cmd data. Must be 76 bytes long
        /// - Returns:
        public static func step2b(cmd data: Data) throws -> HealthCardCommand {
            guard data.count == 76 else {
                throw HealthCardCommandBuilder.InvalidArgument.illegalSize(data.count, expected: 76)
            }
            let tag = try ASN1Kit.create(
                tag: .applicationTag(0x1C),
                data: .constructed([ASN1Kit.create(tag: .taggedTag(2), data: .primitive(data))])
            )
            .serialize()
            return try builder()
                .set(cla: 0x0)
                .set(data: tag)
                .build()
        }
    }

    /// Use-case PACE #14.7.2.1 and #14.7.2.4
    public struct PACE {
        /// Start PACE General authenticate - step 1a #14.7.2.1.1
        /// - Returns: Step 1a command
        public static func step1a() -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! builder()
                .set(data: Data([0x7C, 0x0]))
                .build()
        }

        /// Send publicKey data (from response step 1b) command - step 2a #14.7.2.1.2
        /// - Parameter publicKey: the COSb PCD PK1 to verify on COSa
        /// - Returns: Step 2a command
        public static func step2a(publicKey: Data) throws -> HealthCardCommand {
            let data = derEncoded(objects: [(data: publicKey, tag: .taggedTag(1))])
            return try builder()
                .set(data: try data.serialize())
                .build()
        }

        /// Key agreement - step 3a #14.7.2.1.3
        /// - Parameter publicKey: the COSb PCD PK2 to verify on COSa
        /// - Returns: Step 3a command
        public static func step3a(publicKey: Data) throws -> HealthCardCommand {
            let data = derEncoded(objects: [(data: publicKey, tag: .taggedTag(3))])
            return try builder()
                .set(data: try data.serialize())
                .build()
        }

        /// Verify/Exchange token - step4a #14.7.2.1.4
        /// - Parameter token: Exchange token. Must be 8 bytes long
        /// - Returns: Step 4a command
        public static func step4a(token: Data) throws -> HealthCardCommand {
            guard token.count == 8 else {
                throw HealthCardCommandBuilder.InvalidArgument.illegalSize(token.count, expected: 8)
            }

            let data = derEncoded(objects: [(data: token, tag: .taggedTag(5))])
            return try builder()
                .set(cla: 0x0)
                .set(data: try data.serialize())
                .build()
        }

        private static func derEncoded(objects: [(data: Data, tag: ASN1DecodedTag)]) -> ASN1Object {
            ASN1Kit.create(
                tag: .applicationTag(0x1C),
                data: .constructed(objects.map {
                    ASN1Kit.create(
                        tag: $0.1,
                        data: .primitive($0.0)
                    )
                })
            )
        }

        private static func builder() -> HealthCardCommandBuilder {
            HealthCardCommandBuilder()
                .set(cla: 0x10)
                .set(ins: 0x86)
                .set(p1: 0x0)
                .set(p2: 0x0)
                .set(ne: 0)
                .set(responseStatuses: [ResponseStatus.success.code: .success])
        }

        /// Start PACE General authenticate - step 1b #14.7.2.4.1
        /// - Returns: Step 1a command - since they initialize the same way
        public static func step1b() -> HealthCardCommand {
            step1a()
        }

        /// Set the nonce for PACE General authenticate with CAN - step 2b #14.7.2.4.2
        /// - Parameters:
        ///     - z: a nonce of random bytes. Must be 16 bytes long
        ///     - can: the card's CAN
        /// - Returns: Step 2b command
        public static func step2b(z: Data, can: CAN) throws -> HealthCardCommand {
            // swiftlint:disable:previous identifier_name
            guard z.count == 0x10 else {
                throw HealthCardCommandBuilder.InvalidArgument.illegalSize(z.count, expected: 0x10)
            }
            let data = derEncoded(objects: [
                (data: z, tag: .taggedTag(0)),
                (data: can.rawValue, tag: .privateTag(0)),
            ])
            return try builder()
                .set(data: try data.serialize())
                .set(ne: nil)
                .build()
        }

        /// Key agreement - step 3b #14.7.2.4.3
        /// - Parameter publicKey: the COSb PCD PK1 to verify on COSb
        /// - Returns: Step 3b command
        public static func step3b(publicKey: Data) throws -> HealthCardCommand {
            let data = derEncoded(objects: [(data: publicKey, tag: .taggedTag(2))])
            return try builder()
                .set(data: try data.serialize())
                .build()
        }

        /// Derive Sessions key - step4b #14.7.2.4.4
        /// - Parameter publicKey: The data from returned from 3a to derive a session key
        /// - Returns: Step 4b command
        public static func step4b(publicKey: Data) throws -> HealthCardCommand {
            let data = derEncoded(objects: [(data: publicKey, tag: .taggedTag(4))])
            return try builder()
                .set(data: try data.serialize())
                .build()
        }

        /// Verify/Exchange token - step5b #14.7.2.4.5
        /// - Parameter token: Exchange token. Must be 8 bytes long
        /// - Returns: Step 5b command
        public static func step5b(token: Data) throws -> HealthCardCommand {
            guard token.count == 8 else {
                throw HealthCardCommandBuilder.InvalidArgument.illegalSize(token.count, expected: 8)
            }

            let data = derEncoded(objects: [(data: token, tag: .taggedTag(6))])
            return try builder()
                .set(cla: 0x0)
                .set(data: try data.serialize())
                .build()
        }
    }

    /// Use-cases for getting the security status for particular objects/references gemSpec_COS#14.7.3
    public struct SecurityStatus {
        /// Read the security status for a given symmetric key - gemSpec_COS#14.7.3.1
        /// - Returns: the command
        public static func readStatusFor(symmetricKey: Key, dfSpecific: Bool) throws -> HealthCardCommand {
            try builder()
                .set(data: Data([0x83, 0x1, symmetricKey.calculateKeyReference(dfSpecific: dfSpecific)]))
                .build()
        }

        /// Read the security status for a given CHA - gemSpec_COS#14.7.3.2
        /// - Parameter key: Certificate Holder Authorization (CHA). Must be 7 bytes long
        /// - Returns: the command
        public static func readStatusFor(rsaCvc key: Data) throws -> HealthCardCommand {
            // key must be 7 bytes long
            guard key.count == 7 else {
                throw HealthCardCommandBuilder.InvalidArgument.illegalSize(key.count, expected: 7)
            }
            return try builder()
                .set(data: Data([0x5F, 0x4C, 0x7] + key))
                .build()
        }

        /// Read the security status for the given list of bits - gemSpec_COS#14.7.3.3
        /// - Parameters:
        ///     - flags: 7 Bytes gemSpec_COS #N085.442
        ///     - oid: {oid_cvc_fl_ti, oid_cvc_fl_cms} gemSpec_COS #N085.440
        /// - Returns: the command
        public static func readStatusFor(bitList flags: Data, oid: ASN1Kit.ObjectIdentifier) throws
            -> HealthCardCommand {
                guard oid == oidCvcFlCms || oid == oidCvcFlTi else {
                    throw HealthCardCommandBuilder.InvalidArgument.illegalOid(oid)
                }
                guard flags.count == 7 else {
                    throw HealthCardCommandBuilder.InvalidArgument.illegalSize(flags.count, expected: 7)
                }
                let tag = try ASN1Kit.create(
                    tag: .applicationTag(76),
                    data: .constructed(
                        [
                            try oid.asn1encode(tag: nil),
                            ASN1Kit.create(tag: .applicationTag(0x13), data: .primitive(flags)),
                        ]
                    )
                )
                .serialize()
                return try builder()
                    .set(data: tag)
                    .build()
            }

        // swiftlint:disable force_try
        private static let oidCvcFlCms = try! ObjectIdentifier.from(string: "{1.2.276.0.76.4.153}")
        private static let oidCvcFlTi = try! ObjectIdentifier.from(string: "{1.2.276.0.76.4.152}")
        // swiftlint:enable force_try

        private static func builder() -> HealthCardCommandBuilder {
            HealthCardCommandBuilder()
                .set(cla: 0x80)
                .set(ins: 0x82)
                .set(p1: 0x80)
                .set(p2: 0x0)
                .set(responseStatuses: responseStatuses)
        }

        private static let responseStatuses: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.noAuthentication.code: .noAuthentication,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
            ResponseStatus.keyNotFound.code: .keyNotFound,
        ]
    }
}
