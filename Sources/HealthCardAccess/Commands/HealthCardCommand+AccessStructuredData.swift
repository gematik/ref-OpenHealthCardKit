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

/// These Commands represent the commands in gemSpec_COS#14.4 "Zugriff auf strukturierte Daten".
extension HealthCardCommand {
    /// Commands representing Activate Record command in gemSpec_COS#14.4.1
    public enum ActivateRecord {
        static let ins: UInt8 = 0x08
        static let activateResponseMessages = ResponseMessages.deActivateResponseMessages

        /// Use cases Activate Record with and without shortFileIdentifier gemSpec_COS#14.4.1.1 - 14.4.1.4
        public static func activateRecord(shortFileIdentifier: ShortFileIdentifier? = nil,
                                          recordNumber: UInt8,
                                          useAllFollowingRecords: Bool = false) throws -> HealthCardCommand {
            try AlterRecord
                .alterRecord(shortFileIdentifier: shortFileIdentifier,
                             recordNumber: recordNumber,
                             useAllFollowingRecords: useAllFollowingRecords)
                .set(ins: ins)
                .set(responseStatuses: activateResponseMessages)
                .build()
        }
    }

    /// Commands representing Append Record command in gemSpec_COS#14.4.2
    public enum AppendRecord {
        static let cla: UInt8 = 0x0
        static let ins: UInt8 = 0xE2
        static let pNoMeaning: UInt8 = 0x0
        static let appendRecordResponseMessages = ResponseMessages.appendRecordResponseMessages

        static func builder() -> HealthCardCommandBuilder {
            HealthCardCommandBuilder()
                .set(cla: cla)
                .set(ins: ins)
                .set(p1: pNoMeaning)
                .set(responseStatuses: appendRecordResponseMessages)
        }

        /// Use cases Append Record with and without shortFileIdentifier gemSpec_COS#14.4.2.1 - 14.4.2.2
        public static func appendRecord(shortFileIdentifier: ShortFileIdentifier? = nil,
                                        recordData: Data) throws -> HealthCardCommand {
            // gemSpec_COS#N007.700
            if recordData.count < 1 || recordData.count > 255 {
                throw HealthCardCommandBuilder.InvalidArgument.recordDataSizeOutOfBounds(recordData)
            }

            var p2Value = pNoMeaning
            if let sfid = shortFileIdentifier {
                p2Value += sfid.rawValue[0] << 3
            }

            return try AppendRecord.builder()
                .set(p2: p2Value)
                .set(data: recordData)
                .build()
        }
    }

    /// Commands representing Deactivate Record command in gemSpec_COS#14.4.3
    public enum DeactivateRecord {
        static let ins: UInt8 = 0x06
        static let deactivateResponseMessages = ResponseMessages.deActivateResponseMessages

        /// Use cases Deactivate Record with and without shortFileIdentifier gemSpec_COS#14.4.3.1 - 14.4.3.4
        public static func deactivateRecord(shortFileIdentifier: ShortFileIdentifier? = nil,
                                            recordNumber: UInt8,
                                            useAllFollowingRecords: Bool = false) throws -> HealthCardCommand {
            try AlterRecord
                .alterRecord(shortFileIdentifier: shortFileIdentifier,
                             recordNumber: recordNumber,
                             useAllFollowingRecords: useAllFollowingRecords)
                .set(ins: ins)
                .set(responseStatuses: deactivateResponseMessages)
                .build()
        }
    }

    /// Commands representing Delete Record command in gemSpec_COS#14.4.4
    public enum DeleteRecord {
        static let cla: UInt8 = 0x80
        static let ins: UInt8 = 0x0C
        static let deleteRecordResponseMessages = ResponseMessages.deleteOrEraseRecordResponseMessages

        /// Use cases Delete Record command with and without shortFileIdentifier gemSpec_COS#14.4.4.1 - 14.4.4.2
        public static func deleteRecord(shortFileIdentifier: ShortFileIdentifier? = nil,
                                        recordNumber: UInt8) throws -> HealthCardCommand {
            try AlterRecord.alterRecord(shortFileIdentifier: shortFileIdentifier, recordNumber: recordNumber)
                .set(cla: cla)
                .set(ins: ins)
                .set(responseStatuses: deleteRecordResponseMessages)
                .build()
        }
    }

    /// Commands representing Erase Record command in gemSpec_COS#14.4.5
    public enum EraseRecord {
        static let ins: UInt8 = 0xC
        static let eraseResponseMessages = ResponseMessages.deleteOrEraseRecordResponseMessages

        /// Use cases Erase Record with and without shortFileIdentifier gemSpec_COS#14.4.5.1 - 14.4.5.2
        public static func eraseRecord(shortFileIdentifier: ShortFileIdentifier? = nil,
                                       recordNumber: UInt8) throws -> HealthCardCommand {
            try AlterRecord
                .alterRecord(shortFileIdentifier: shortFileIdentifier, recordNumber: recordNumber)
                .set(ins: ins)
                .set(responseStatuses: eraseResponseMessages)
                .build()
        }
    }

    /// Commands representing Read Record command in gemSpec_COS#14.4.6
    public enum ReadRecord {
        static let ins: UInt8 = 0xB2
        static let readResponseMessages = ResponseMessages.readRecordResponseMessages

        /// Use cases Read Record with and without shortFileIdentifier gemSpec_COS#14.4.6.1 - 14.4.6.2
        public static func readRecord(shortFileIdentifier: ShortFileIdentifier? = nil,
                                      recordNumber: UInt8,
                                      expectedLength: Int) throws -> HealthCardCommand {
            try AlterRecord
                .alterRecord(shortFileIdentifier: shortFileIdentifier, recordNumber: recordNumber)
                .set(ins: ins)
                .set(ne: expectedLength)
                .set(responseStatuses: readResponseMessages)
                .build()
        }
    }

    /// Commands representing Search Record command in gemSpec_COS#14.4.7
    public enum SearchRecord {
        static let ins: UInt8 = 0xA2
        static let searchResponseMessages = ResponseMessages.searchRecordResponseMessages

        /// Use cases Search Record with and without shortFileIdentifier gemSpec_COS#14.4.7.1 - 14.4.7.2
        public static func searchRecord(shortFileIdentifier: ShortFileIdentifier? = nil,
                                        recordNumber: UInt8,
                                        searchString: Data,
                                        expectedLength: Int) throws -> HealthCardCommand {
            // gemSpec_COS#N068.200
            if searchString.count < 1 || searchString.count > 255 {
                throw HealthCardCommandBuilder.InvalidArgument.recordDataSizeOutOfBounds(searchString)
            }

            return try AlterRecord
                .alterRecord(shortFileIdentifier: shortFileIdentifier, recordNumber: recordNumber)
                .set(ins: ins)
                .set(data: searchString)
                .set(ne: expectedLength)
                .set(responseStatuses: searchResponseMessages)
                .build()
        }
    }

    /// Commands representing Update Record command in gemSpec_COS#14.4.8
    public enum UpdateRecord {
        static let ins: UInt8 = 0xDC
        static let updateRecordResponseMessages = ResponseMessages.updateRecordResponseMessages

        /// Use cases Update Record with and without shortFileIdentifier gemSpec_COS#14.4.8.1 - 14.4.8.2
        public static func updateRecord(shortFileIdentifier: ShortFileIdentifier? = nil,
                                        recordNumber: UInt8,
                                        newData: Data) throws -> HealthCardCommand {
            try AlterRecord
                .alterRecord(shortFileIdentifier: shortFileIdentifier, recordNumber: recordNumber)
                .set(ins: ins)
                .set(data: newData)
                .set(responseStatuses: updateRecordResponseMessages)
                .build()
        }
    }

    /// Internal helper struct for commands ActivateRecord, DeactivateRecord, ...
    /// They share the same APDU-bytes - except INS
    enum AlterRecord {
        static let cla: UInt8 = 0x0
        static let ins: UInt8 = 0x00

        static func builder() -> HealthCardCommandBuilder {
            HealthCardCommandBuilder()
                .set(cla: cla)
                .set(ins: ins)
        }

        static func alterRecord(shortFileIdentifier: ShortFileIdentifier?,
                                recordNumber: UInt8,
                                useAllFollowingRecords: Bool = false) -> HealthCardCommandBuilder {
            var p2Value: UInt8 = 0x0
            if let sfid = shortFileIdentifier {
                p2Value += sfid.rawValue[0] << 3
            }
            p2Value += useAllFollowingRecords ? 0x5 : 0x4
            return AlterRecord.builder()
                .set(p1: recordNumber)
                .set(p2: p2Value)
        }
    }

    enum ResponseMessages {
        static let deActivateResponseMessages: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.updateRetryWarningCount00.code: .updateRetryWarningCount00,
            ResponseStatus.updateRetryWarningCount01.code: .updateRetryWarningCount01,
            ResponseStatus.updateRetryWarningCount02.code: .updateRetryWarningCount02,
            ResponseStatus.updateRetryWarningCount03.code: .updateRetryWarningCount03,
            ResponseStatus.memoryFailure.code: .memoryFailure,
            ResponseStatus.wrongFileType.code: .wrongFileType,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
            ResponseStatus.noRecordLifeCycleStatus.code: .noRecordLifeCycleStatus,
            ResponseStatus.noCurrentEf.code: .noCurrentEf,
            ResponseStatus.fileNotFound.code: .fileNotFound,
            ResponseStatus.recordNotFound.code: .recordNotFound,
        ]

        static let appendRecordResponseMessages: [UInt16: ResponseStatus] = [
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
            ResponseStatus.fullRecordListOrOutOfMemory.code: .fullRecordListOrOutOfMemory,
        ]

        static let deleteOrEraseRecordResponseMessages: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.updateRetryWarningCount00.code: .updateRetryWarningCount00,
            ResponseStatus.updateRetryWarningCount01.code: .updateRetryWarningCount01,
            ResponseStatus.updateRetryWarningCount02.code: .updateRetryWarningCount02,
            ResponseStatus.updateRetryWarningCount03.code: .updateRetryWarningCount03,
            ResponseStatus.recordDeactivated.code: .recordDeactivated,
            ResponseStatus.memoryFailure.code: .memoryFailure,
            ResponseStatus.wrongFileType.code: .wrongFileType,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
            ResponseStatus.noCurrentEf.code: .noCurrentEf,
            ResponseStatus.fileNotFound.code: .fileNotFound,
            ResponseStatus.recordNotFound.code: .recordNotFound,
        ]

        static let readRecordResponseMessages: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.corruptDataWarning.code: .corruptDataWarning,
            ResponseStatus.endOfRecordWarning.code: .endOfRecordWarning,
            ResponseStatus.recordDeactivated.code: .recordDeactivated,
            ResponseStatus.wrongFileType.code: .wrongFileType,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
            ResponseStatus.noCurrentEf.code: .noCurrentEf,
            ResponseStatus.fileNotFound.code: .fileNotFound,
            ResponseStatus.recordNotFound.code: .recordNotFound,
        ]

        static let searchRecordResponseMessages: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.corruptDataWarning.code: .corruptDataWarning,
            ResponseStatus.unsuccessfulSearch.code: .unsuccessfulSearch,
            ResponseStatus.wrongFileType.code: .wrongFileType,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
            ResponseStatus.noCurrentEf.code: .noCurrentEf,
            ResponseStatus.fileNotFound.code: .fileNotFound,
            ResponseStatus.recordNotFound.code: .recordNotFound,
        ]

        static let updateRecordResponseMessages: [UInt16: ResponseStatus] = [
            ResponseStatus.success.code: .success,
            ResponseStatus.updateRetryWarningCount00.code: .updateRetryWarningCount00,
            ResponseStatus.updateRetryWarningCount01.code: .updateRetryWarningCount01,
            ResponseStatus.updateRetryWarningCount02.code: .updateRetryWarningCount02,
            ResponseStatus.updateRetryWarningCount03.code: .updateRetryWarningCount03,
            ResponseStatus.recordDeactivated.code: .recordDeactivated,
            ResponseStatus.memoryFailure.code: .memoryFailure,
            ResponseStatus.wrongFileType.code: .wrongFileType,
            ResponseStatus.securityStatusNotSatisfied.code: .securityStatusNotSatisfied,
            ResponseStatus.noCurrentEf.code: .noCurrentEf,
            ResponseStatus.fileNotFound.code: .fileNotFound,
            ResponseStatus.fullRecordListOrOutOfMemory.code: .fullRecordListOrOutOfMemory,
        ]
    }
}
