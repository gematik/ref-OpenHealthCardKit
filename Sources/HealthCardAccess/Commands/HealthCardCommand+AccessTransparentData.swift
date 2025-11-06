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

import Foundation

/// These Commands represent the commands in gemSpec_COS#14.3 "Zugriff auf Daten in transparenten EF".
extension HealthCardCommand {
    static let byteModulo = 256

    /// Commands representing the commands in gemSpec_COS#14.3.1
    public enum Erase {
        static let eraseCommandResponseMessages: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.updateRetryWarningCount00.code: .updateRetryWarningCount00,
            ResponseStatus.updateRetryWarningCount01.code: .updateRetryWarningCount01,
            ResponseStatus.updateRetryWarningCount02.code: .updateRetryWarningCount02,
            ResponseStatus.updateRetryWarningCount03.code: .updateRetryWarningCount03,
            ResponseStatus.memoryFailure.code: .memoryFailure,
            ResponseStatus.wrongFileType.code: .wrongFileType,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
            ResponseStatus.noCurrentEf.code: .noCurrentEf,
            ResponseStatus.fileNotFound.code: .fileNotFound,
            ResponseStatus.offsetTooBig.code: .offsetTooBig,
        ]

        static let cla: UInt8 = 0x0
        static let ins: UInt8 = 0xE0

        static func builder() -> HealthCardCommandBuilder {
            HealthCardCommandBuilder()
                .set(cla: cla)
                .set(ins: ins)
                .set(data: nil)
                .set(ne: nil)
                .set(responseStatuses: eraseCommandResponseMessages)
        }

        /// Use cases Erase Binary without `ShortFileIdentifier`
        public static func eraseFileCommand(offset: Int = 0) throws -> HealthCardCommand {
            try HealthCardCommandBuilder.checkValidity(offset: offset, usingShortFileIdentifier: false)

            let p2ValueInt = offset % byteModulo
            let p1ValueInt = (offset - p2ValueInt) / byteModulo
            let p1Value = UInt8(p1ValueInt)
            let p2Value = UInt8(p2ValueInt)

            return try Erase.builder()
                .set(p1: p1Value)
                .set(p2: p2Value)
                .build()
        }

        /// Use cases Erase Binary with `ShortFileIdentifier`
        public static func eraseFileCommand(with sfid: ShortFileIdentifier, offset: Int = 0) throws ->
            HealthCardCommand {
            try HealthCardCommandBuilder.checkValidity(offset: offset, usingShortFileIdentifier: true)

            let p1Value = HealthCardCommandBuilder.sfidMarker + UInt8(sfid.rawValue[0])
            let p2Value = UInt8(offset)

            return try Erase.builder()
                .set(p1: p1Value)
                .set(p2: p2Value)
                .build()
        }
    }

    /// Commands representing the commands in gemSpec_COS#14.3.2
    public enum Read {
        static let readCommandResponseMessages: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.corruptDataWarning.code: .corruptDataWarning,
            ResponseStatus.endOfFileWarning.code: .endOfFileWarning,
            ResponseStatus.wrongFileType.code: .wrongFileType,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
            ResponseStatus.noCurrentEf.code: .noCurrentEf,
            ResponseStatus.fileNotFound.code: .fileNotFound,
            ResponseStatus.offsetTooBig.code: .offsetTooBig,
        ]

        static let cla: UInt8 = 0x0
        static let ins: UInt8 = 0xB0

        static func builder() -> HealthCardCommandBuilder {
            HealthCardCommandBuilder()
                .set(cla: cla)
                .set(ins: ins)
                .set(data: nil)
                .set(ne: nil)
                .set(responseStatuses: readCommandResponseMessages)
        }

        /// Use cases Read Binary without `ShortFileIdentifier`
        public static func readFileCommand(ne: Int, offset: Int = 0) throws -> HealthCardCommand {
            // swiftlint:disable:previous identifier_name
            try HealthCardCommandBuilder.checkValidity(offset: offset, usingShortFileIdentifier: false)
            try ne.isNot(0, else: HealthCardCommandBuilder.InvalidArgument.expectedLengthMustNotBeZero)

            let p2ValueInt = offset % byteModulo
            let p1ValueInt = (offset - p2ValueInt) / byteModulo
            let p1Value = UInt8(p1ValueInt)
            let p2Value = UInt8(p2ValueInt)

            return try Read.builder()
                .set(p1: p1Value)
                .set(p2: p2Value)
                .set(ne: ne)
                .build()
        }

        /// Use cases Read Binary with `ShortFileIdentifier`
        public static func readFileCommand(with sfid: ShortFileIdentifier, ne: Int, offset: Int = 0) throws ->
            // swiftlint:disable:previous identifier_name
            HealthCardCommand {
            try HealthCardCommandBuilder.checkValidity(offset: offset, usingShortFileIdentifier: true)
            try ne.isNot(0, else: HealthCardCommandBuilder.InvalidArgument.expectedLengthMustNotBeZero)

            let p1Value = HealthCardCommandBuilder.sfidMarker + UInt8(sfid.rawValue[0])
            let p2Value = UInt8(offset)

            return try Read.builder()
                .set(p1: p1Value)
                .set(p2: p2Value)
                .set(ne: ne)
                .build()
        }
    }

    /// Commands representing the commands in gemSpec_COS#14.3.4
    public enum SetLogicalEof {
        static let setLogicalEofCommandResponseMessages: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.updateRetryWarningCount00.code: .updateRetryWarningCount00,
            ResponseStatus.updateRetryWarningCount01.code: .updateRetryWarningCount01,
            ResponseStatus.updateRetryWarningCount02.code: .updateRetryWarningCount02,
            ResponseStatus.updateRetryWarningCount03.code: .updateRetryWarningCount03,
            ResponseStatus.memoryFailure.code: .memoryFailure,
            ResponseStatus.wrongFileType.code: .wrongFileType,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
            ResponseStatus.noCurrentEf.code: .noCurrentEf,
            ResponseStatus.fileNotFound.code: .fileNotFound,
            ResponseStatus.offsetTooBig.code: .offsetTooBig,
        ]

        static let cla: UInt8 = 0x80
        static let ins: UInt8 = 0xE

        static func builder() -> HealthCardCommandBuilder {
            HealthCardCommandBuilder()
                .set(cla: cla)
                .set(ins: ins)
                .set(data: nil)
                .set(ne: nil)
                .set(responseStatuses: setLogicalEofCommandResponseMessages)
        }

        /// Use cases Set Logical EOF without `ShortFileIdentifier`
        public static func setLogicalEofCommand(offset: Int = 0) throws -> HealthCardCommand {
            try HealthCardCommandBuilder.checkValidity(offset: offset, usingShortFileIdentifier: false)

            let p2ValueInt = offset % byteModulo
            let p1ValueInt = (offset - p2ValueInt) / byteModulo
            let p1Value = UInt8(p1ValueInt)
            let p2Value = UInt8(p2ValueInt)

            return try SetLogicalEof.builder()
                .set(p1: p1Value)
                .set(p2: p2Value)
                .build()
        }

        /// Use cases Set Logical EOF with `ShortFileIdentifier`
        public static func setLogicalEofCommand(with sfid: ShortFileIdentifier, offset: Int = 0) throws ->
            HealthCardCommand {
            try HealthCardCommandBuilder.checkValidity(offset: offset, usingShortFileIdentifier: true)

            let p1Value = HealthCardCommandBuilder.sfidMarker + UInt8(sfid.rawValue[0])
            let p2Value = UInt8(offset)

            return try SetLogicalEof.builder()
                .set(p1: p1Value)
                .set(p2: p2Value)
                .build()
        }
    }

    /// Commands representing the commands in gemSpec_COS#14.3.5
    public enum Update {
        static let updateCommandResponseMessages: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.updateRetryWarningCount00.code: .updateRetryWarningCount00,
            ResponseStatus.updateRetryWarningCount01.code: .updateRetryWarningCount01,
            ResponseStatus.updateRetryWarningCount02.code: .updateRetryWarningCount02,
            ResponseStatus.updateRetryWarningCount03.code: .updateRetryWarningCount03,
            ResponseStatus.memoryFailure.code: .memoryFailure,
            ResponseStatus.wrongFileType.code: .wrongFileType,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
            ResponseStatus.noCurrentEf.code: .noCurrentEf,
            ResponseStatus.fileNotFound.code: .fileNotFound,
            ResponseStatus.offsetTooBig.code: .offsetTooBig,
        ]

        static let cla: UInt8 = 0x0
        static let ins: UInt8 = 0xD6

        static func builder() -> HealthCardCommandBuilder {
            HealthCardCommandBuilder()
                .set(cla: cla)
                .set(ins: ins)
                .set(ne: nil)
                .set(responseStatuses: updateCommandResponseMessages)
        }

        /// Use cases Update Binary without `ShortFileIdentifier`
        public static func updateCommand(data: Data, offset: Int = 0) throws -> HealthCardCommand {
            try HealthCardCommandBuilder.checkValidity(offset: offset, usingShortFileIdentifier: false)

            let p2ValueInt = offset % byteModulo
            let p1ValueInt = (offset - p2ValueInt) / byteModulo
            let p1Value = UInt8(p1ValueInt)
            let p2Value = UInt8(p2ValueInt)

            return try Update.builder()
                .set(p1: p1Value)
                .set(p2: p2Value)
                .set(data: data)
                .build()
        }

        /// Use cases Update Binary with `ShortFileIdentifier`
        public static func updateCommand(with sfid: ShortFileIdentifier, data: Data, offset: Int = 0) throws ->
            HealthCardCommand {
            try HealthCardCommandBuilder.checkValidity(offset: offset, usingShortFileIdentifier: true)

            let p1Value = HealthCardCommandBuilder.sfidMarker + UInt8(sfid.rawValue[0])
            let p2Value = UInt8(offset)

            return try Update.builder()
                .set(p1: p1Value)
                .set(p2: p2Value)
                .set(data: data)
                .build()
        }
    }

    /// Commands representing the commands in gemSpec_COS#14.3.6
    public enum Write {
        static let writeCommandResponseMessages: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.updateRetryWarningCount00.code: .updateRetryWarningCount00,
            ResponseStatus.updateRetryWarningCount01.code: .updateRetryWarningCount01,
            ResponseStatus.updateRetryWarningCount02.code: .updateRetryWarningCount02,
            ResponseStatus.updateRetryWarningCount03.code: .updateRetryWarningCount03,
            ResponseStatus.memoryFailure.code: .memoryFailure,
            ResponseStatus.wrongFileType.code: .wrongFileType,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
            ResponseStatus.noCurrentEf.code: .noCurrentEf,
            ResponseStatus.fileNotFound.code: .fileNotFound,
            ResponseStatus.offsetTooBig.code: .offsetTooBig,
        ]

        static let cla: UInt8 = 0x0
        static let ins: UInt8 = 0xD0
        static let p2Value: UInt8 = 0x0

        static func builder() -> HealthCardCommandBuilder {
            HealthCardCommandBuilder()
                .set(cla: cla)
                .set(ins: ins)
                .set(p2: p2Value)
                .set(ne: nil)
                .set(responseStatuses: writeCommandResponseMessages)
        }

        /// Use cases Write Binary without `ShortFileIdentifier`
        public static func writeCommand(data: Data) throws -> HealthCardCommand {
            let p1Value: UInt8 = 0x0

            return try Write.builder()
                .set(p1: p1Value)
                .set(data: data)
                .build()
        }

        /// Use cases Write Binary with `ShortFileIdentifier`
        public static func writeCommand(with sfid: ShortFileIdentifier, data: Data) throws -> HealthCardCommand {
            let p1Value = HealthCardCommandBuilder.sfidMarker + UInt8(sfid.rawValue[0])

            return try Write.builder()
                .set(p1: p1Value)
                .set(data: data)
                .build()
        }
    }
}
