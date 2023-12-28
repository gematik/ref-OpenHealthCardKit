// swiftlint:disable file_length
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

/// These commands represent the commands in gemSpec_COS#14.2 "Management des Objektsystems"
extension HealthCardCommand {
    /// Builders representing Activate Command gemSpec_COS#14.2.1
    public enum Activate {
        static let ins: UInt8 = 0x44

        /// Use case Activate current EF gemSpec_Cos#14.2.1.1
        public static func activateCurrentFile() -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! DeActivateDeleteTerminate.alterCurrentFile()
                .set(ins: ins)
                .build()
        }

        /// Use case Activate private or symmetric key object gemSpec_Cos#14.2.1.2
        public static func activate(privateOrSymmetricKey: Key, dfSpecific: Bool) -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! DeActivateDeleteTerminate.alter(privateOrSymmetricKey: privateOrSymmetricKey,
                                                 dfSpecific: dfSpecific)
                .set(ins: ins)
                .build()
        }

        /// Use case Activate public key object gemSpec_Cos#14.2.1.3
        public static func activatePublicKey(reference: Data) throws -> HealthCardCommand {
            try DeActivateDeleteTerminate.alterPublicKey(reference: reference)
                .set(ins: ins)
                .build()
        }

        /// Use case Activate password object gemSpec_Cos#14.2.1.4
        public static func activate(password: Password, dfSpecific: Bool) -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! DeActivateDeleteTerminate.alter(password: password, dfSpecific: dfSpecific)
                .set(ins: ins)
                .build()
        }
    }

    /// Builders representing Deactivate Command gemSpec_COS#14.2.3
    public enum Deactivate {
        static let ins: UInt8 = 0x04

        /// Use case Deactivate current EF gemSpec_Cos#14.2.3.1
        public static func deactivateCurrentFile() -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! DeActivateDeleteTerminate.alterCurrentFile()
                .set(ins: ins)
                .build()
        }

        /// Use case Deactivate private or symmetric key object gemSpec_Cos#14.2.3.2
        public static func deactivate(privateOrSymmetricKey: Key, dfSpecific: Bool) -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! DeActivateDeleteTerminate.alter(privateOrSymmetricKey: privateOrSymmetricKey, dfSpecific:
                dfSpecific)
                .set(ins: ins)
                .build()
        }

        /// Use case Deactivate public key object gemSpec_Cos#14.2.3.3
        public static func deactivatePublicKey(reference: Data) throws -> HealthCardCommand {
            try DeActivateDeleteTerminate.alterPublicKey(reference: reference)
                .set(ins: ins)
                .build()
        }

        /// Use case Deactivate password object gemSpec_Cos#14.2.3.4
        public static func deactivate(password: Password, dfSpecific: Bool) -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! DeActivateDeleteTerminate.alter(password: password, dfSpecific: dfSpecific)
                .set(ins: ins)
                .build()
        }
    }

    /// Builders representing Delete Command gemSpec_COS#14.2.4
    public enum Delete {
        static let ins: UInt8 = 0xE4

        /// Use case Delete current EF gemSpec_Cos#14.2.4.1
        public static func deleteCurrentFile() -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! DeActivateDeleteTerminate.alterCurrentFile()
                .set(ins: ins)
                .build()
        }

        /// Use case Delete private or symmetric key object gemSpec_Cos#14.2.4.2
        public static func delete(privateOrSymmetricKey: Key, dfSpecific: Bool) -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! DeActivateDeleteTerminate.alter(privateOrSymmetricKey: privateOrSymmetricKey,
                                                 dfSpecific: dfSpecific)
                .set(ins: ins)
                .build()
        }

        /// Use case Delete public key object gemSpec_Cos#14.2.4.3
        public static func deletePublicKey(reference: Data) throws -> HealthCardCommand {
            try DeActivateDeleteTerminate.alterPublicKey(reference: reference)
                .set(ins: ins)
                .build()
        }

        /// Use case Delete password object gemSpec_Cos#14.2.4.4
        public static func delete(password: Password, dfSpecific: Bool) -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! DeActivateDeleteTerminate.alter(password: password, dfSpecific: dfSpecific)
                .set(ins: ins)
                .build()
        }
    }

    /// Builders representing Load Application Command gemSpec_COS#14.2.5
    public enum LoadApplication {
        static let loadApplicationResponseMessages: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.updateRetryWarningCount00.code: .updateRetryWarningCount00,
            ResponseStatus.updateRetryWarningCount01.code: .updateRetryWarningCount01,
            ResponseStatus.updateRetryWarningCount02.code: .updateRetryWarningCount02,
            ResponseStatus.updateRetryWarningCount03.code: .updateRetryWarningCount03,
            ResponseStatus.memoryFailure.code: .memoryFailure,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
            ResponseStatus.outOfMemory.code: .outOfMemory,
            ResponseStatus.duplicatedObjects.code: .duplicatedObjects,
            ResponseStatus.dfNameExists.code: .dfNameExists,
            ResponseStatus.instructionNotSupported.code: .instructionNotSupported,
        ]

        static let claWithChaining: UInt8 = 0x10
        static let claWithoutChaining: UInt8 = 0x0
        static let ins: UInt8 = 0xEA
        static let p1Value: UInt8 = 0x0
        static let p2Value: UInt8 = 0x0

        static func builder() -> HealthCardCommandBuilder {
            HealthCardCommandBuilder()
                .set(ins: ins)
                .set(p1: p1Value)
                .set(p2: p2Value)
                .set(responseStatuses: loadApplicationResponseMessages)
        }

        /// Use cases Load Application gemSpec_Cos#14.2.5.1 - 14.2.5.2
        public static func loadApplication(useChaining: Bool, data: Data) -> HealthCardCommand {
            let claValue: UInt8 = useChaining ? claWithChaining : claWithoutChaining
            // swiftlint:disable:next force_try
            return try! LoadApplication.builder()
                .set(cla: claValue)
                .set(data: data)
                .build()
        }
    }

    /// Builders representing Select Command gemSpec_COS#14.2.6
    public enum Select {
        static let selectResponseMessages: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.fileDeactivated.code: .fileDeactivated,
            ResponseStatus.fileTerminated.code: .fileTerminated,
            ResponseStatus.fileNotFound.code: .fileNotFound,
            ResponseStatus.instructionNotSupported.code: .instructionNotSupported,
        ]

        static let cla: UInt8 = 0x0
        static let ins: UInt8 = 0xA4

        static func builder() -> HealthCardCommandBuilder {
            HealthCardCommandBuilder()
                .set(cla: cla)
                .set(ins: ins)
                .set(responseStatuses: selectResponseMessages)
        }

        static let p1SelectionModeParent: UInt8 = 0x3
        static let p1SelectionModeAid: UInt8 = 0x4
        static let p1SelectionModeDfWithFid: UInt8 = 0x1
        static let p1SelectionModeEfWithFid: UInt8 = 0x2
        static let p2FirstOccurrenceFcp: UInt8 = 0x4
        static let p2Fcp: UInt8 = 0x2
        static let p2FirstOccurrence: UInt8 = 0xC

        /// Use case Select root of object system gemSpec_Cos#14.2.6.1
        public static func selectRoot() -> HealthCardCommand {
            let p2Value = calculateP2(fcp: false, next: false)
            // swiftlint:disable:next force_try
            return try! Select.builder()
                .set(p1: p1SelectionModeAid)
                .set(p2: p2Value)
                .build()
        }

        /// Use cases Select root of object system requesting FCP gemSpec_Cos#4.2.6.2
        public static func selectRootRequestingFcp(expectedLength: Int) throws -> HealthCardCommand {
            try expectedLength.isNot(0, else: HealthCardCommandBuilder.InvalidArgument.expectedLengthMustNotBeZero)

            let p2Value = calculateP2(fcp: true, next: false)
            return try Select.builder()
                .set(p1: p1SelectionModeAid)
                .set(p2: p2Value)
                .set(ne: expectedLength)
                .build()
        }

        // Note: Left out use cases Select without Application Identifier, next gemSpec_Cos#14.2.6.3 - 14.2.6.4

        /// Use cases Select file with Application Identifier gemSpec_Cos#14.2.6.5 + 14.2.6.7
        public static func selectFile(with aid: ApplicationIdentifier,
                                      next occurrence: Bool = false) -> HealthCardCommand {
            let p2Value: UInt8 = calculateP2(fcp: false, next: occurrence)
            // swiftlint:disable:next force_try
            return try! Select.builder()
                .set(p1: p1SelectionModeAid)
                .set(p2: p2Value)
                .set(data: aid.rawValue)
                .build()
        }

        /// Use cases Select file with Application Identifier requesting FCP gemSpec_Cos#14.2.6.6 + 14.2.6.8
        public static func selectFileRequestingFcp(with aid: ApplicationIdentifier,
                                                   expectedLength: Int,
                                                   next occurrence: Bool = false) throws -> HealthCardCommand {
            try expectedLength.isNot(0, else: HealthCardCommandBuilder.InvalidArgument.expectedLengthMustNotBeZero)

            let p2Value: UInt8 = calculateP2(fcp: true, next: occurrence)
            return try Select.builder()
                .set(p1: p1SelectionModeAid)
                .set(p2: p2Value)
                .set(data: aid.rawValue)
                .set(ne: expectedLength)
                .build()
        }

        /// Use case Select DF with File Identifier gemSpec_Cos#14.2.6.9
        public static func selectDf(with fid: FileIdentifier) -> HealthCardCommand {
            let p2Value = calculateP2(fcp: false, next: false)
            // swiftlint:disable:next force_try
            return try! Select.builder()
                .set(p1: p1SelectionModeDfWithFid)
                .set(p2: p2Value)
                .set(data: fid.rawValue)
                .build()
        }

        /// Use case Select DF with File Identifier gemSpec_Cos#14.2.6.10
        public static func selectDfRequestingFcp(with fid: FileIdentifier, expectedLength: Int) throws ->
            HealthCardCommand {
            try expectedLength.isNot(0, else: HealthCardCommandBuilder.InvalidArgument.expectedLengthMustNotBeZero)

            let p2Value = calculateP2(fcp: true, next: false)
            return try Select.builder()
                .set(p1: p1SelectionModeDfWithFid)
                .set(p2: p2Value)
                .set(data: fid.rawValue)
                .set(ne: expectedLength)
                .build()
        }

        /// Use case Select parent folder gemSpec_Cos#14.2.6.11
        public static func selectParent() -> HealthCardCommand {
            let p2Value = calculateP2(fcp: false, next: false)
            // swiftlint:disable:next force_try
            return try! Select.builder()
                .set(p1: p1SelectionModeParent)
                .set(p2: p2Value)
                .build()
        }

        /// Use case Select parent folder requesting FCP gemSpec_Cos#14.2.6.12
        public static func selectParentRequestingFcp(expectedLength: Int) throws -> HealthCardCommand {
            try expectedLength.isNot(0, else: HealthCardCommandBuilder.InvalidArgument.expectedLengthMustNotBeZero)

            let p2Value = calculateP2(fcp: true, next: false)
            return try Select.builder()
                .set(p1: p1SelectionModeParent)
                .set(p2: p2Value)
                .set(ne: expectedLength)
                .build()
        }

        /// Use cases Select EF with File Identifier gemSpec_Cos#14.2.6.13
        public static func selectEf(with fid: FileIdentifier) -> HealthCardCommand {
            let p2Value = calculateP2(fcp: false, next: false)
            // swiftlint:disable:next force_try
            return try! Select.builder()
                .set(p1: p1SelectionModeEfWithFid)
                .set(p2: p2Value)
                .set(data: fid.rawValue)
                .build()
        }

        /// Use case Select EF with File Identifier requesting FCP gemSpec_Cos#14.2.6.14
        public static func selectEfRequestingFcp(with fid: FileIdentifier, expectedLength: Int) throws ->
            HealthCardCommand {
            try expectedLength.isNot(0, else: HealthCardCommandBuilder.InvalidArgument.expectedLengthMustNotBeZero)

            let p2Value = calculateP2(fcp: true, next: false)
            return try Select.builder()
                .set(p1: p1SelectionModeEfWithFid)
                .set(p2: p2Value)
                .set(data: fid.rawValue)
                .set(ne: expectedLength)
                .build()
        }

        private static func calculateP2(fcp: Bool, next occurrence: Bool) -> UInt8 {
            let responseTypeFcp: UInt8 = 0x4
            let responseTypeNoResponse: UInt8 = 0xC
            let fileOccurrenceNext: UInt8 = 0x2
            let fileOccurrenceFirst: UInt8 = 0x0

            var p2Value: UInt8 = fcp ? responseTypeFcp : responseTypeNoResponse
            p2Value += occurrence ? fileOccurrenceNext : fileOccurrenceFirst
            return p2Value
        }
    }

    /// Builders representing Terminate Card Usage Command gemSpec_COS#14.2.7
    public enum TerminateCardUsage {
        static let terminateCardUsageResponseMessages: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.updateRetryWarningCount00.code: .updateRetryWarningCount00,
            ResponseStatus.updateRetryWarningCount01.code: .updateRetryWarningCount01,
            ResponseStatus.updateRetryWarningCount02.code: .updateRetryWarningCount02,
            ResponseStatus.updateRetryWarningCount03.code: .updateRetryWarningCount03,
            ResponseStatus.memoryFailure.code: .memoryFailure,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
        ]

        static let cla: UInt8 = 0x0
        static let ins: UInt8 = 0xFE
        static let p1Value: UInt8 = 0x0
        static let p2Value: UInt8 = 0x0

        static func builder() -> HealthCardCommandBuilder {
            HealthCardCommandBuilder()
                .set(cla: cla)
                .set(ins: ins)
                .set(p1: p1Value)
                .set(p2: p2Value)
                .set(responseStatuses: terminateCardUsageResponseMessages)
        }

        /// Use case Terminate Card Usage gemSpec_Cos#14.2.7.1
        public static func terminateCardUsage() -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! TerminateCardUsage
                .builder()
                .build()
        }
    }

    /// Builders representing Terminate DF Command gemSpec_COS#14.2.8
    public enum TerminateDf {
        static let terminateDfResponseMessages: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.updateRetryWarningCount00.code: .updateRetryWarningCount00,
            ResponseStatus.updateRetryWarningCount01.code: .updateRetryWarningCount01,
            ResponseStatus.updateRetryWarningCount02.code: .updateRetryWarningCount02,
            ResponseStatus.updateRetryWarningCount03.code: .updateRetryWarningCount03,
            ResponseStatus.memoryFailure.code: .memoryFailure,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
        ]

        static let cla: UInt8 = 0x0
        static let ins: UInt8 = 0xE6
        static let p1Value: UInt8 = 0x0
        static let p2Value: UInt8 = 0x0

        static func builder() -> HealthCardCommandBuilder {
            HealthCardCommandBuilder()
                .set(cla: cla)
                .set(ins: ins)
                .set(p1: p1Value)
                .set(p2: p2Value)
                .set(responseStatuses: terminateDfResponseMessages)
        }

        /// Use case Terminate DF current Folder gemSpec_Cos#14.2.8.1
        public static func terminateDf() -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! TerminateDf
                .builder()
                .build()
        }
    }

    /// Builders representing Terminate Command gemSpec_COS#14.2.9
    public enum Terminate {
        static let ins: UInt8 = 0xE8

        /// Use case Terminate current EF gemSpec_Cos#14.2.9.1
        public static func terminateCurrentFile() -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! DeActivateDeleteTerminate.alterCurrentFile()
                .set(ins: ins)
                .build()
        }

        /// Use case Terminate private or symmetric key object gemSpec_Cos#14.2.9.2
        public static func terminate(privateOrSymmetricKey: Key, dfSpecific: Bool) -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! DeActivateDeleteTerminate.alter(privateOrSymmetricKey: privateOrSymmetricKey,
                                                 dfSpecific: dfSpecific)
                .set(ins: ins)
                .build()
        }

        /// Use case Terminate public key object gemSpec_Cos#14.2.9.3
        public static func terminatePublicKey(reference: Data) throws -> HealthCardCommand {
            try DeActivateDeleteTerminate.alterPublicKey(reference: reference)
                .set(ins: ins)
                .build()
        }

        /// Use case Terminate password object gemSpec_Cos#14.2.9.4
        public static func terminate(password: Password, dfSpecific: Bool) -> HealthCardCommand {
            // swiftlint:disable:next force_try
            try! DeActivateDeleteTerminate.alter(password: password, dfSpecific: dfSpecific)
                .set(ins: ins)
                .build()
        }
    }

    /// Internal helper struct for commands Activate, Deactivate, Delete, Terminate
    /// They share the same APDU-bytes - except INS - and the same response messages
    enum DeActivateDeleteTerminate {
        static let responseMessages: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.updateRetryWarningCount00.code: .updateRetryWarningCount00,
            ResponseStatus.updateRetryWarningCount01.code: .updateRetryWarningCount01,
            ResponseStatus.updateRetryWarningCount02.code: .updateRetryWarningCount02,
            ResponseStatus.updateRetryWarningCount03.code: .updateRetryWarningCount03,
            ResponseStatus.memoryFailure.code: .memoryFailure,
            ResponseStatus.volatileKeyWithoutLcs.code: .volatileKeyWithoutLcs,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
            ResponseStatus.noCurrentEf.code: .noCurrentEf,
            ResponseStatus.keyOrPwdNotFound.code: .keyOrPwdNotFound,
        ]

        static let cla: UInt8 = 0x0
        static let ins: UInt8 = 0x00
        static let p2NoMeaning: UInt8 = 0x0

        static func builder() -> HealthCardCommandBuilder {
            HealthCardCommandBuilder()
                .set(cla: cla)
                .set(ins: ins)
                .set(responseStatuses: responseMessages)
        }

        static func alterCurrentFile() -> HealthCardCommandBuilder {
            let p1Value: UInt8 = 0x0
            return DeActivateDeleteTerminate.builder()
                .set(p1: p1Value)
                .set(p2: p2NoMeaning)
        }

        static func alter(privateOrSymmetricKey: Key, dfSpecific: Bool) -> HealthCardCommandBuilder {
            let p1Value: UInt8 = 0x20
            let p2Value = privateOrSymmetricKey.calculateKeyReference(dfSpecific: dfSpecific)
            return DeActivateDeleteTerminate.builder()
                .set(p1: p1Value)
                .set(p2: p2Value)
        }

        static func alterPublicKey(reference: Data) throws -> HealthCardCommandBuilder {
            let p1Value: UInt8 = 0x21
            let p2Value: UInt8 = 0x0
            let taggedData = try ASN1Kit.create(tag: .taggedTag(3), data: .primitive(reference)).serialize()
            return DeActivateDeleteTerminate.builder()
                .set(p1: p1Value)
                .set(p2: p2Value)
                .set(data: taggedData)
        }

        static func alter(password: Password, dfSpecific: Bool) -> HealthCardCommandBuilder {
            let p1Value: UInt8 = 0x10
            let p2Value = password.calculateKeyReference(dfSpecific: dfSpecific)
            return DeActivateDeleteTerminate.builder()
                .set(p1: p1Value)
                .set(p2: p2Value)
        }
    }
}
