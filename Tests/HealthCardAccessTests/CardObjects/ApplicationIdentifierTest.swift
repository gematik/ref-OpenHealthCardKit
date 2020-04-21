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

@testable import HealthCardAccess
import Nimble
import XCTest

final class ApplicationIdentifierTest: XCTestCase {
    func testValidAID() {
        let aid = "D27600000102" as ApplicationIdentifier
        let expected = Data([0xd2, 0x76, 0x0, 0x0, 0x1, 0x2])
        expect(aid.rawValue) == expected
    }

    func testValidAID_initFromString() {
        expect {
            try ApplicationIdentifier(hex: "D276000001").rawValue
        }.to(equal(Data([0xd2, 0x76, 0x0, 0x0, 0x1])))
    }

    func testValidAID_initFromData() {
        let data = Data([0x1, 0x2, 0x23, 0x45, 0xd0])
        expect {
            try ApplicationIdentifier(data).rawValue
        }.to(equal(data))
    }

    func testValidatorWhenAIDisInvalidLength() {
        let invalidAID = Data([0x0, 0x1, 0x2])
        expect {
            try ApplicationIdentifier.isValid(invalidAID).get()
        }.to(throwError(ApplicationIdentifier.Error.invalidLength(length: 3)))
    }

    func testWhenAIDhasNonHexValue() {
        expect {
            try ApplicationIdentifier(hex: "Z27600000102")
        }.to(throwError(ApplicationIdentifier.Error.illegalArgument(
                "Application File Identifier is invalid (non-hex characters found). [Z27600000102]"
        )))
    }

    func testValidatorWhenAIDisValid() {
        let validAID = Data([0x0, 0x1, 0x2, 0x3, 0x4])
        expect {
            try ApplicationIdentifier.isValid(validAID).get()
        } == validAID
    }

    func testInvalidAIDfromStringLiteral() {
#if !SWIFT_PACKAGE
        expect {
            _ = "ZD27600000102" as ApplicationIdentifier
        }.to(throwAssertion())

        expect {
            _ = "D276" as ApplicationIdentifier
        }.to(throwAssertion())
#endif
    }

    static let allTests = [
        ("testValidAID", testValidAID),
        ("testValidAID_initFromString", testValidAID_initFromString),
        ("testValidAID_initFromData", testValidAID_initFromData),
        ("testValidatorWhenAIDisInvalidLength", testValidatorWhenAIDisInvalidLength),
        ("testWhenAIDhasNonHexValue", testWhenAIDhasNonHexValue),
        ("testValidatorWhenAIDisValid", testValidatorWhenAIDisValid),
        ("testInvalidAIDfromStringLiteral", testInvalidAIDfromStringLiteral)
    ]
}
