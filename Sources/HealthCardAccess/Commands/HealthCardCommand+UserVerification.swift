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

import Foundation

/// These commands represent the User Verification Commands (Benutzerverifikation) in gemSpec_COS#14.6
extension HealthCardCommand {

    /// Command representing Change/Set Reference Data Command gemSpec_COS#14.6.1
    public struct ChangeReferenceData {
        static let cla: UInt8 = 0x0
        static let ins: UInt8 = 0x24
        static let passwordChange: UInt8 = 0x0
        static let passwordSet: UInt8 = 0x1

        /// Change password command parameters
        /// - Parameters:
        ///     - password: The password object to change/update
        ///     - dfSpecific: whether or not the password object specifies a Global or DF-specific.
        ///                     true = DF-Specific, false = global
        ///     - old: the old secret (pin) to verify
        ///     - new: the new secret (pin) to set
        public typealias ChangePasswordParameter =
                (password: Password, dfSpecific: Bool, old: Format2Pin, new: Format2Pin)

        /// Use case Change Password Secret (Pin) gemSpec_COS#14.6.1.1
        /// - Parameter parameter: the arguments for the password change command
        /// - Returns: Command for a change password secret command
        public static func change(password parameter: ChangePasswordParameter) throws -> HealthCardCommand {
            return try builder()
                    .set(p1: passwordChange)
                    .set(p2: parameter.password.calculateKeyReference(dfSpecific: parameter.dfSpecific))
                    .set(data: parameter.old.pin + parameter.new.pin)
            .build()
        }

        /// Set password command parameters
        /// - Parameters:
        ///     - password: The password object to change/update
        ///     - dfSpecific: whether or not the password object specifies a Global or DF-specific.
        ///                     true = DF-Specific, false = global
        ///     - pin: the secret (pin) to set
        public typealias SetPasswordParameter = (password: Password, dfSpecific: Bool, pin: Format2Pin)

        /// Use case Set Password Secret (Pin) gemSpec_COS#14.6.1.2
        /// - Parameter parameter: the arguments for the password set command
        /// - Returns: Command for a set password secret command
        public static func set(password parameter: SetPasswordParameter) -> HealthCardCommand {
            // swiftlint:disable:next force_try
            return try! builder()
                    .set(p1: passwordSet)
                    .set(p2: parameter.password.calculateKeyReference(dfSpecific: parameter.dfSpecific))
                    .set(data: parameter.pin.pin)
            .build()
        }

        private static func builder() -> HealthCardCommandBuilder {
            return HealthCardCommandBuilder()
                    .set(cla: cla)
                    .set(ins: ins)
                    .set(ne: nil)
                    .set(responseStatuses: responseMessages)
        }
    }

    /// Command representing Disable Verification Requirement Command gemSpec_COS#14.6.2
    public struct DisableVerificationRequirement {
        static let cla: UInt8 = 0x0
        static let ins: UInt8 = 0x26

        /// Set password command parameters
        /// - Parameters:
        ///     - password: The password object to change/update
        ///     - dfSpecific: whether or not the password object specifies a Global or DF-specific.
        ///                     true = DF-Specific, false = global
        ///     - verificationData: the secret (pin) to be transmitted (omit if not necessary)
        public typealias VerificationRequirementPasswordParameter =
                (password: Password, dfSpecific: Bool, verificationData: Format2Pin?)

        /// Use case Disable Verification Requirement gemSpec_COS#14.6.2.1 + 14.6.2.2
        /// - Parameter parameter: the arguments for the disable verification requirement command
        /// - Returns: Command for a set password secret command
        public static func disable(password parameter: VerificationRequirementPasswordParameter) throws
                        -> HealthCardCommand {
            let p1: UInt8 = parameter.verificationData != nil ? 0x0 : 0x1 // swiftlint:disable:this identifier_name
            return try HealthCardCommandBuilder()
                    .set(cla: cla)
                    .set(ins: ins)
                    .set(p1: p1)
                    .set(p2: parameter.password.calculateKeyReference(dfSpecific: parameter.dfSpecific))
                    .set(data: parameter.verificationData?.pin)
                    .set(responseStatuses: responseMessagesVerificationRequirement)
            .build()
        }
    }

    /// Command representing Enable Verification Requirement Command gemSpec_COS#14.6.3
    public struct EnableVerificationRequirement {
        static let cla: UInt8 = 0x0
        static let ins: UInt8 = 0x28

        /// Set password command parameters
        /// - Parameters:
        ///     - password: The password object to change/update
        ///     - dfSpecific: whether or not the password object specifies a Global or DF-specific.
        ///                     true = DF-Specific, false = global
        ///     - verificationData: the secret (pin) to be transmitted (omit if not necessary)
        public typealias VerificationRequirementPasswordParameter =
                (password: Password, dfSpecific: Bool, verificationData: Format2Pin?)

        /// Use case Enable Verification Requirement gemSpec_COS#14.6.3.1 + 14.6.3.2
        /// - Parameter parameter: the arguments for the disable verification requirement command
        /// - Returns: Command for a set password secret command
        public static func enable(password parameter: VerificationRequirementPasswordParameter) throws
                        -> HealthCardCommand {
            let p1: UInt8 = parameter.verificationData != nil ? 0x0 : 0x1 // swiftlint:disable:this identifier_name
            return try HealthCardCommandBuilder()
                    .set(cla: cla)
                    .set(ins: ins)
                    .set(p1: p1)
                    .set(p2: parameter.password.calculateKeyReference(dfSpecific: parameter.dfSpecific))
                    .set(data: parameter.verificationData?.pin)
                    .set(responseStatuses: responseMessagesVerificationRequirement)
                    .build()
        }
    }

    /// Command representing Get Pin Status Command gemSpec_COS#14.6.4
    public struct Status {
        static let cla: UInt8 = 0x80
        static let ins: UInt8 = 0x20
        static let p1: UInt8 = 0x0 // swiftlint:disable:this identifier_name

        /// Get Pin Status command parameters
        /// - Parameters:
        ///     - password: The password object to get the status for
        ///     - dfSpecific: whether or not the password object specifies a Global or DF-specific.
        ///                     true = DF-Specific, false = global
        public typealias GetPinStatusParameter = (password: Password, dfSpecific: Bool)

        /// Use case Get Pin Status gemSpec_COS#14.6.4.1
        /// - Parameter parameter: the arguments for the Get Pin Status command
        /// - Returns: Command for a Get Pin Status command
        public static func status(for parameter: GetPinStatusParameter) -> HealthCardCommand {
            // swiftlint:disable:next force_try
            return try! HealthCardCommandBuilder()
                    .set(cla: cla)
                    .set(ins: ins)
                    .set(p1: p1)
                    .set(p2: parameter.password.calculateKeyReference(dfSpecific: parameter.dfSpecific))
                    .set(ne: nil)
                    .set(responseStatuses: pinStatusResponses)
                    .build()
        }

        /// Response codes for Get Pin Status gemSpec_COS#14.6.4.2
        static let pinStatusResponses: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.retryCounterCount00.code: .retryCounterCount00,
            ResponseStatus.retryCounterCount01.code: .retryCounterCount01,
            ResponseStatus.retryCounterCount02.code: .retryCounterCount02,
            ResponseStatus.retryCounterCount03.code: .retryCounterCount03,
            ResponseStatus.retryCounterCount04.code: .retryCounterCount04,
            ResponseStatus.retryCounterCount05.code: .retryCounterCount05,
            ResponseStatus.retryCounterCount06.code: .retryCounterCount06,
            ResponseStatus.retryCounterCount07.code: .retryCounterCount07,
            ResponseStatus.retryCounterCount08.code: .retryCounterCount08,
            ResponseStatus.retryCounterCount09.code: .retryCounterCount09,
            ResponseStatus.retryCounterCount10.code: .retryCounterCount10,
            ResponseStatus.retryCounterCount11.code: .retryCounterCount11,
            ResponseStatus.retryCounterCount12.code: .retryCounterCount12,
            ResponseStatus.retryCounterCount13.code: .retryCounterCount13,
            ResponseStatus.retryCounterCount14.code: .retryCounterCount14,
            ResponseStatus.retryCounterCount15.code: .retryCounterCount15,
            ResponseStatus.passwordDisabled.code: .passwordDisabled,
            ResponseStatus.transportStatusEmptyPin.code: .transportStatusEmptyPin,
            ResponseStatus.transportStatusTransportPin.code: .transportStatusTransportPin
        ]
    }

    /// Command representing Verify Secret Command gemSpec_COS#14.6.6
    public struct Verify {
        static let cla: UInt8 = 0x0
        static let ins: UInt8 = 0x20
        static let p1: UInt8 = 0x0 // swiftlint:disable:this identifier_name

        /// Verify password command parameters
        /// - Parameters:
        ///     - password: The password object to change/update
        ///     - dfSpecific: whether or not the password object specifies a Global or DF-specific.
        ///                     true = DF-Specific, false = global
        ///     - pin: the old secret (pin) to verify
        ///     - new: the new secret (pin) to set
        public typealias VerifyPasswordParameter =
                (password: Password, dfSpecific: Bool, pin: Format2Pin)

        /// Use case Change Password Secret (Pin) gemSpec_COS#14.6.6.1
        /// - Parameter parameter: the arguments for the password change command
        /// - Returns: Command for a change password secret command
        public static func verify(password parameter: VerifyPasswordParameter) -> HealthCardCommand {
            // swiftlint:disable:next force_try
            return try! HealthCardCommandBuilder()
                    .set(cla: cla)
                    .set(ins: ins)
                    .set(p1: p1)
                    .set(p2: parameter.password.calculateKeyReference(dfSpecific: parameter.dfSpecific))
                    .set(data: parameter.pin.pin)
                    .set(ne: nil)
                    .set(responseStatuses: responseMessages)
                    .build()
        }
    }

    /// Response statuses gemSpec_COS#14.6.2.3
    static let responseMessagesVerificationRequirement: [UInt16: ResponseStatus] = [
        ResponseStatus.success.code: .success,
        ResponseStatus.wrongSecretWarningCount00.code: .wrongSecretWarningCount00,
        ResponseStatus.wrongSecretWarningCount01.code: .wrongSecretWarningCount01,
        ResponseStatus.wrongSecretWarningCount02.code: .wrongSecretWarningCount02,
        ResponseStatus.wrongSecretWarningCount03.code: .wrongSecretWarningCount03,
        ResponseStatus.wrongSecretWarningCount04.code: .wrongSecretWarningCount04,
        ResponseStatus.wrongSecretWarningCount05.code: .wrongSecretWarningCount05,
        ResponseStatus.wrongSecretWarningCount06.code: .wrongSecretWarningCount06,
        ResponseStatus.wrongSecretWarningCount07.code: .wrongSecretWarningCount07,
        ResponseStatus.wrongSecretWarningCount08.code: .wrongSecretWarningCount08,
        ResponseStatus.wrongSecretWarningCount09.code: .wrongSecretWarningCount09,
        ResponseStatus.wrongSecretWarningCount10.code: .wrongSecretWarningCount10,
        ResponseStatus.wrongSecretWarningCount11.code: .wrongSecretWarningCount11,
        ResponseStatus.wrongSecretWarningCount12.code: .wrongSecretWarningCount12,
        ResponseStatus.wrongSecretWarningCount13.code: .wrongSecretWarningCount13,
        ResponseStatus.wrongSecretWarningCount14.code: .wrongSecretWarningCount14,
        ResponseStatus.wrongSecretWarningCount15.code: .wrongSecretWarningCount15,
        ResponseStatus.memoryFailure.code: .memoryFailure,
        ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
        ResponseStatus.passwordBlocked.code: .passwordBlocked,
        ResponseStatus.passwordNotUsable.code: .passwordNotUsable,
        ResponseStatus.passwordNotFound.code: .passwordNotFound
    ]

    /// Response statuses gemSpec_COS#14.6.1.3, #14.6.6.2
    static let responseMessages: [UInt16: ResponseStatus] = [
        ResponseStatus.success.code: .success,
        ResponseStatus.wrongSecretWarningCount00.code: .wrongSecretWarningCount00,
        ResponseStatus.wrongSecretWarningCount01.code: .wrongSecretWarningCount01,
        ResponseStatus.wrongSecretWarningCount02.code: .wrongSecretWarningCount02,
        ResponseStatus.wrongSecretWarningCount03.code: .wrongSecretWarningCount03,
        ResponseStatus.wrongSecretWarningCount04.code: .wrongSecretWarningCount04,
        ResponseStatus.wrongSecretWarningCount05.code: .wrongSecretWarningCount05,
        ResponseStatus.wrongSecretWarningCount06.code: .wrongSecretWarningCount06,
        ResponseStatus.wrongSecretWarningCount07.code: .wrongSecretWarningCount07,
        ResponseStatus.wrongSecretWarningCount08.code: .wrongSecretWarningCount08,
        ResponseStatus.wrongSecretWarningCount09.code: .wrongSecretWarningCount09,
        ResponseStatus.wrongSecretWarningCount10.code: .wrongSecretWarningCount10,
        ResponseStatus.wrongSecretWarningCount11.code: .wrongSecretWarningCount11,
        ResponseStatus.wrongSecretWarningCount12.code: .wrongSecretWarningCount12,
        ResponseStatus.wrongSecretWarningCount13.code: .wrongSecretWarningCount13,
        ResponseStatus.wrongSecretWarningCount14.code: .wrongSecretWarningCount14,
        ResponseStatus.wrongSecretWarningCount15.code: .wrongSecretWarningCount15,
        ResponseStatus.memoryFailure.code: .memoryFailure,
        ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
        ResponseStatus.passwordBlocked.code: .passwordBlocked,
        ResponseStatus.wrongPasswordLength.code: .wrongPasswordLength,
        ResponseStatus.passwordNotFound.code: .passwordNotFound
    ]
}
