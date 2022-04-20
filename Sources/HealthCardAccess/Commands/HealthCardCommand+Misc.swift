//
//  Copyright (c) 2022 gematik GmbH
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
import GemCommonsKit

extension HealthCardCommand {
    /// Builder representing Miscellaneous Commands in gemSpec_COS#14.9
    public enum Misc {
        /// Use case verify COS Fingerprint gemSpec_COS#14.9.2.1
        /// - Parameter prefix: the prefix data 128 bytes
        /// - Throws: when prefix is not 128 long
        /// - Returns: The Fingerprint command
        public static func fingerprint(for prefix: Data) throws -> HealthCardCommand {
            guard prefix.count == 128 else {
                throw HealthCardCommandBuilder.InvalidArgument.illegalSize(prefix.count, expected: 128)
            }
            // swiftlint:disable:next force_try
            return try! HealthCardCommandBuilder()
                .set(cla: 0x80)
                .set(ins: 0xFA)
                .set(p1: 0x0)
                .set(p2: 0x0)
                .set(data: prefix)
                .set(ne: APDU.expectedLengthWildcardShort)
                .set(responseStatuses: fingerprintResponseStatuses)
                .build()
        }

        private static let fingerprintResponseStatuses: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
        ]

        /// Asymmetric Key Pair Generation (GAKP) modes
        public enum GenerationMode {
            /// No generation, just read the current (public) key
            /// - Parameters:
            ///     - reference: The Key reference or nil
            ///     - dfSpecific: Whether dfSpecific or not (only applicable when reference is set)
            case readOnly(reference: Key?, dfSpecific: Bool)
            /// Generate a new Key Pair for a given Key reference
            /// - Parameters:
            ///     - reference: The Key reference or nil
            ///     - dfSpecific: Whether dfSpecific or not (only applicable when reference is set)
            ///     - overwrite: Whether to overwrite existing key. false = use existing when possible
            ///     - out: whether to return the generated (or existing) Public Key
            case generate(reference: Key?, dfSpecific: Bool, overwrite: Bool, out: Bool)

            // swiftlint:disable:next identifier_name
            var p1: UInt8 {
                switch self {
                case .readOnly:
                    return 0x81
                case let .generate(_, _, overwrite, out):
                    if overwrite, out {
                        return 0xC0
                    }
                    if overwrite {
                        return 0xC4
                    }
                    if out {
                        return 0x80
                    }
                    return 0x84
                }
            }

            // swiftlint:disable:next identifier_name
            var p2: UInt8 {
                switch self {
                case let .readOnly(reference: .some(key), dfSpecific):
                    return key.calculateKeyReference(dfSpecific: dfSpecific)
                case let .generate(reference: .some(key), dfSpecific, _, _):
                    return key.calculateKeyReference(dfSpecific: dfSpecific)
                default:
                    return 0
                }
            }

            var expectedLength: Int? {
                switch self {
                case .readOnly:
                    return APDU.expectedLengthWildcardExtended
                case let .generate(_, _, _, out):
                    return out ? APDU.expectedLengthWildcardExtended : nil
                }
            }
        }

        /// Generate an Asymmetric Key Pair - gemSpec_COS#14.9.3
        /// - Parameters:
        ///     - mode: The generation mode to use
        /// - Returns: The GAKP command
        public static func generateAsymmetricKeyPair(mode: GenerationMode) -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! HealthCardCommandBuilder()
                .set(cla: 0x0)
                .set(ins: 0x46)
                .set(p1: mode.p1)
                .set(p2: mode.p2)
                .set(ne: mode.expectedLength)
                .set(responseStatuses: generateResponseStatuses)
                .build()
        }

        private static let generateResponseStatuses: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.keyInvalid.code: .keyInvalid,
            ResponseStatus.memoryFailure.code: .memoryFailure,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
            ResponseStatus.keyAlreadyPresent.code: .keyAlreadyPresent,
            ResponseStatus.keyNotFound.code: .keyNotFound,

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
        ]

        /// ChallengeParameter to specify challenge mode in gemSpec_COS#14.9.4
        public enum ChallengeParameter {
            /// AES
            case aes
            /// DES
            case des
            /// ELC
            case elc
            /// RSA
            case rsa

            var expectedLength: Int {
                switch self {
                case .aes: fallthrough // swiftlint:disable:this no_fallthrough_only
                case .elc: return 0x10
                case .des: fallthrough // swiftlint:disable:this no_fallthrough_only
                case .rsa: return 0x8
                }
            }
        }

        /// Get Challenge - gemSpec_COS#14.9.4
        /// - Parameter mode: The crypto mode to request a challenge for
        /// - Returns: The GetChallenge command
        public static func challenge(mode: ChallengeParameter) -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! HealthCardCommandBuilder()
                .set(cla: 0x0)
                .set(ins: 0x84)
                .set(ne: mode.expectedLength)
                .set(responseStatuses: [ResponseStatus.success.code: .success])
                .build()
        }

        /// Get random bytes with given length - gemSpec_COS#14.9.5
        public static func random(length: Int) throws -> HealthCardCommand {
            let range = 0 ..< 256
            guard range ~= length else {
                throw HealthCardCommandBuilder.InvalidArgument.illegalValue(length, for: "length", expected: range)
            }
            return try HealthCardCommandBuilder()
                .set(cla: 0x80)
                .set(ins: 0x84)
                .set(ne: length)
                .set(responseStatuses: [
                    ResponseStatus.success.code: .success,
                    ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
                ])
                .build()
        }

        /// List all Public Keys - gemSpec_COS#14.9.7
        /// - Returns: The List Public Key command
        public static func listPublicKeys() -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! HealthCardCommandBuilder()
                .set(cla: 0x80)
                .set(ins: 0xCA)
                .set(p1: 0x1)
                .set(ne: APDU.expectedLengthWildcardExtended)
                .set(responseStatuses: [
                    ResponseStatus.success.code: .success,
                    ResponseStatus.dataTruncated.code: .dataTruncated,
                ])
                .build()
        }

        /// Manage Channel commands - gemSpec_COS#14.9.8
        private static let manageChannelIns: UInt8 = 0x70
        private static let manageChannelResponseStatuses: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.noMoreChannelsAvailable.code: .noMoreChannelsAvailable,
        ]

        /// Open logic channel - gemSpec_COS#14.9.8.1
        /// - Returns: Open logic channel command
        public static func openLogicChannel() -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! HealthCardCommandBuilder()
                .set(cla: 0x0)
                .set(ins: manageChannelIns)
                .set(ne: 1)
                .set(responseStatuses: manageChannelResponseStatuses)
                .build()
        }

        /// Close logic channel - gemSpec_COS#14.9.8.2
        /// - Parameter number: The channel number that should be closed
        /// - Returns: Close channel command
        public static func closeLogicChannel(number: UInt8) -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! HealthCardCommandBuilder()
                .set(cla: number)
                .set(ins: manageChannelIns)
                .set(p1: 0x80)
                .set(responseStatuses: manageChannelResponseStatuses)
                .build()
        }

        /// Reset logic channel - gemSpec_COS#14.9.8.3
        /// - Parameter number: The channel number to reset
        /// - Returns: Reset logic channel command
        public static func resetLogicChannel(number: UInt8) -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! HealthCardCommandBuilder()
                .set(cla: number)
                .set(ins: manageChannelIns)
                .set(p1: 0x40)
                .set(responseStatuses: manageChannelResponseStatuses)
                .build()
        }

        /// Reset Application (channel context) - gemSpec_COS#14.9.8.4
        /// - Returns: Reset command
        public static func resetApplication() -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! HealthCardCommandBuilder()
                .set(cla: 0x0)
                .set(ins: manageChannelIns)
                .set(p1: 0x40)
                .set(p2: 0x1)
                .set(responseStatuses: manageChannelResponseStatuses)
                .build()
        }
    }
}
