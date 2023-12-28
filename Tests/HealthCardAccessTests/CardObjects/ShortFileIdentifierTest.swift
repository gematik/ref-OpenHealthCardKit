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

@testable import HealthCardAccess
import Nimble
import XCTest

final class ShortFileIdentifierTest: XCTestCase {
    func testValidSFID() {
        let sfid = "0E" as ShortFileIdentifier
        let expected = Data([0x0E])
        expect(sfid.rawValue) == expected
    }

    func testValidSFID_initFromString() {
        expect {
            try ShortFileIdentifier(hex: "1E").rawValue
        }.to(equal(Data([0x1E])))
    }

    func testValidSFID_initFromUInt8() {
        let data = Data([0x10])
        expect {
            try ShortFileIdentifier(data[0]).rawValue
        }.to(equal(data))
    }

    func testValidSFID_initFromASN1() {
        let data = Data([0x10])
        expect {
            try ShortFileIdentifier(asn1: data).rawValue
        }.to(equal(Data([0x2])))
    }

    func testWhenSFIDhasNonHexValue() {
        expect {
            try ShortFileIdentifier(hex: "ZE")
        }.to(throwError(ShortFileIdentifier.Error.illegalArgument(
            "Short File Identifier is invalid (non-hex characters found). [ZE]"
        )))
    }

    func testValidatorWhenOutOfRange() {
        // gemSpec_COS#N007.000
        var invalidSFIDs = [UInt8]()
        for idx: UInt8 in 0x1F ..< 0xFF {
            invalidSFIDs.append(idx)
        }
        invalidSFIDs.append(0x0)
        invalidSFIDs.map { Data([$0]) }.forEach { sfid in
            expect {
                try ShortFileIdentifier.isValid(sfid).get()
            }.to(throwError(
                ShortFileIdentifier.Error.illegalArgument(
                    "Short File Identifier is invalid: [0x\(sfid.hexString())]"
                )
            ))
        }
    }

    func testValidatorWhenSFIDisValid() {
        // gemSpec_COS#N007.000
        var invalidSFIDs = [UInt8]()
        for idx: UInt8 in 0x1 ... 0x1E {
            invalidSFIDs.append(idx)
        }
        invalidSFIDs.map { Data([$0]) }.forEach { sfid in
            expect {
                try ShortFileIdentifier.isValid(sfid).get()
            } == sfid
        }
    }

    static let allTests = [
        ("testValidSFID", testValidSFID),
        ("testValidSFID_initFromString", testValidSFID_initFromString),
        ("testValidSFID_initFromUInt8", testValidSFID_initFromUInt8),
        ("testValidSFID_initFromASN1", testValidSFID_initFromASN1),
        ("testWhenFIDhasNonHexValue", testWhenSFIDhasNonHexValue),
        ("testValidatorWhenOutOfRange", testValidatorWhenOutOfRange),
        ("testValidatorWhenSFIDisValid", testValidatorWhenSFIDisValid),
    ]
}
