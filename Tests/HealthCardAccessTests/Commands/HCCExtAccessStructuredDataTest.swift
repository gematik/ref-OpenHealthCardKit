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

import CardReaderProviderApi
import Foundation
@testable import HealthCardAccess
import Nimble
import XCTest

final class HCCExtAccessStructuredDataTest: XCTestCase {
    func testActivateRecord() {
        let recordNumber: UInt8 = 0x2
        let sfid = "1C" as ShortFileIdentifier
        let expected = Data([0x0, 0x8, 0x2, 0x4])

        expect {
            try HealthCardCommand
                .ActivateRecord.activateRecord(recordNumber: recordNumber)
                .bytes
        } == expected

        let expected2 = Data([0x0, 0x8, 0x2, 0x5])
        expect {
            try HealthCardCommand
                .ActivateRecord.activateRecord(recordNumber: recordNumber, useAllFollowingRecords: true)
                .bytes
        } == expected2

        let expected3 = Data([0x0, 0x8, 0x2, 0xE5])
        expect {
            try HealthCardCommand
                .ActivateRecord.activateRecord(shortFileIdentifier: sfid,
                                               recordNumber: recordNumber,
                                               useAllFollowingRecords: true)
                .bytes
        } == expected3

        expect {
            try HealthCardCommand
                .ActivateRecord.activateRecord(recordNumber: recordNumber)
                .responseStatuses.keys
        }.to(contain(ResponseStatus.noRecordLifeCycleStatus.code))
    }

    func testAppendRecord() {
        let sfid = "1C" as ShortFileIdentifier
        let data = Data([0x9, 0x8, 0x7])

        let expected = Data([0x0, 0xE2, 0x0, 0x0]) + Data([0x3]) + data
        expect {
            try HealthCardCommand
                .AppendRecord.appendRecord(recordData: data)
                .bytes
        } == expected

        let expected2 = Data([0x0, 0xE2, 0x0, 0xE0]) + Data([0x3]) + data
        expect {
            try HealthCardCommand
                .AppendRecord.appendRecord(shortFileIdentifier: sfid, recordData: data)
                .bytes
        } == expected2

        expect {
            try HealthCardCommand
                .AppendRecord.appendRecord(recordData: data)
                .responseStatuses.keys
        }.to(contain(ResponseStatus.fullRecordListOrOutOfMemory.code))

        expect {
            try HealthCardCommand
                .AppendRecord.appendRecord(recordData: Data())
        }.to(throwError(HealthCardCommandBuilder.InvalidArgument.recordDataSizeOutOfBounds(Data())))
    }

    func testDeactivateRecord() {
        let recordNumber: UInt8 = 0x2
        let sfid = "1C" as ShortFileIdentifier

        let expected = Data([0x0, 0x6, 0x2, 0x4])
        expect {
            try HealthCardCommand
                .DeactivateRecord.deactivateRecord(recordNumber: recordNumber)
                .bytes
        } == expected

        let expected3 = Data([0x0, 0x6, 0x2, 0xE5])
        expect {
            try HealthCardCommand
                .DeactivateRecord.deactivateRecord(shortFileIdentifier: sfid,
                                                   recordNumber: recordNumber,
                                                   useAllFollowingRecords: true)
                .bytes
        } == expected3
    }

    func testDeleteRecord() {
        let recordNumber: UInt8 = 0x3
        let sfid = "1D" as ShortFileIdentifier

        let expected = Data([0x80, 0xC, 0x3, 0x4])
        expect {
            try HealthCardCommand
                .DeleteRecord.deleteRecord(recordNumber: recordNumber)
                .bytes
        } == expected

        let expected2 = Data([0x80, 0xC, 0x3, 0xEC])
        expect {
            try HealthCardCommand
                .DeleteRecord.deleteRecord(shortFileIdentifier: sfid, recordNumber: recordNumber)
                .bytes
        } == expected2

        expect {
            try HealthCardCommand
                .DeleteRecord.deleteRecord(recordNumber: recordNumber)
                .responseStatuses.keys
        }.to(contain(ResponseStatus.recordNotFound.code))
    }

    func testEraseRecord() {
        let recordNumber: UInt8 = 0x3
        let sfid = "1D" as ShortFileIdentifier

        let expected = Data([0x0, 0xC, 0x3, 0x4])
        expect {
            try HealthCardCommand
                .EraseRecord.eraseRecord(recordNumber: recordNumber)
                .bytes
        } == expected

        let expected2 = Data([0x0, 0xC, 0x3, 0xEC])
        expect {
            try HealthCardCommand
                .EraseRecord.eraseRecord(shortFileIdentifier: sfid, recordNumber: recordNumber)
                .bytes
        } == expected2
    }

    func testReadRecord() {
        let recordNumber: UInt8 = 0x3
        let sfid = "1D" as ShortFileIdentifier
        let expectedLength: Int = 0x1234

        let expected = Data([0x0, 0xB2, 0x3, 0x4]) + Data([0x0]) + Data([0x12, 0x34])
        expect {
            try HealthCardCommand
                .ReadRecord.readRecord(recordNumber: recordNumber, expectedLength: expectedLength)
                .bytes
        } == expected

        let expected2 = Data([0x0, 0xB2, 0x3, 0xEC]) + Data([0x0]) + Data([0x12, 0x34])
        expect {
            try HealthCardCommand
                .ReadRecord.readRecord(shortFileIdentifier: sfid,
                                       recordNumber: recordNumber,
                                       expectedLength: expectedLength)
                .bytes
        } == expected2

        expect {
            try HealthCardCommand
                .ReadRecord.readRecord(shortFileIdentifier: sfid,
                                       recordNumber: recordNumber,
                                       expectedLength: expectedLength)
                .responseStatuses.keys
        }.to(contain(ResponseStatus.recordNotFound.code))
    }

    func testSearchRecord() {
        let recordNumber: UInt8 = 0x3
        let sfid = "1C" as ShortFileIdentifier
        let searchData = Data([0x9, 0x8, 0x7])
        let expectedLength: Int = 0x1234

        let expected = Data([0x0, 0xA2, 0x3, 0x4])
            + Data([0x0, 0x0, 0x3]) + searchData
            + Data([0x12, 0x34])
        expect {
            try HealthCardCommand
                .SearchRecord.searchRecord(recordNumber: recordNumber,
                                           searchString: searchData,
                                           expectedLength: expectedLength)
                .bytes
        } == expected

        let expected2 = Data([0x0, 0xA2, 0x3, 0xE4])
            + Data([0x0, 0x0, 0x3]) + searchData
            + Data([0x12, 0x34])
        expect {
            try HealthCardCommand
                .SearchRecord.searchRecord(shortFileIdentifier: sfid,
                                           recordNumber: recordNumber,
                                           searchString: searchData,
                                           expectedLength: expectedLength)
                .bytes
        } == expected2

        expect {
            try HealthCardCommand
                .SearchRecord.searchRecord(recordNumber: recordNumber,
                                           searchString: searchData,
                                           expectedLength: expectedLength)
                .responseStatuses.keys
        }.to(contain(ResponseStatus.unsuccessfulSearch.code))

        let invalidSearch = Data(count: 256)
        expect {
            try HealthCardCommand
                .SearchRecord.searchRecord(recordNumber: recordNumber,
                                           searchString: invalidSearch,
                                           expectedLength: expectedLength)
        }.to(throwError(HealthCardCommandBuilder.InvalidArgument.recordDataSizeOutOfBounds(invalidSearch)))
    }

    func testUpdateRecord() {
        let recordNumber: UInt8 = 0x3
        let sfid = "1C" as ShortFileIdentifier
        let data = Data([0x9, 0x8, 0x7])

        let expected = Data([0x0, 0xDC, 0x3, 0x4]) + Data([0x3]) + data
        expect {
            try HealthCardCommand
                .UpdateRecord.updateRecord(recordNumber: recordNumber, newData: data)
                .bytes
        } == expected

        let expected2 = Data([0x0, 0xDC, 0x3, 0xE4]) + Data([0x3]) + data
        expect {
            try HealthCardCommand
                .UpdateRecord.updateRecord(shortFileIdentifier: sfid, recordNumber: recordNumber, newData: data)
                .bytes
        } == expected2

        expect {
            try HealthCardCommand
                .UpdateRecord.updateRecord(recordNumber: recordNumber, newData: data)
                .responseStatuses.keys
        }.to(contain(ResponseStatus.recordDeactivated.code))
    }

    static let allTests = [
        ("testActivateRecord", testActivateRecord),
        ("testAppendRecord", testAppendRecord),
        ("testDeactivateRecord", testDeactivateRecord),
        ("testDeleteRecord", testDeleteRecord),
        ("testEraseRecord", testEraseRecord),
        ("testReadRecord", testReadRecord),
        ("testSearchRecord", testSearchRecord),
        ("testUpdateRecord", testUpdateRecord),
    ]
}
