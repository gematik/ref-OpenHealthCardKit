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

final class PasswordTest: XCTestCase {
    func testValidPassword() {
        for pwdId: UInt8 in 0 ... 31 {
            expect {
                try Password(pwdId).pwdId
            } == pwdId
        }
    }

    func testValidPasswordFromString() {
        expect {
            ("01" as Password).pwdId
        } == 0x1

        expect {
            ("1" as Password).pwdId
        } == 0x1

        expect {
            ("1C" as Password).pwdId
        } == 0x1C
    }

    func testPasswordOutOfRange() {
        // gemSpec_COS#N015.000
        for pwdId: UInt8 in 32 ... 0xFF {
            expect {
                try Password(pwdId)
            }.to(throwError(Password.Error.illegalArgument("Password value is invalid: [\(pwdId)]")))
        }
    }

    func testCalculateKeyReference() {
        expect {
            try Password(0x10).calculateKeyReference(dfSpecific: true)
        } == 0x90
        expect {
            try Password(0x10).calculateKeyReference(dfSpecific: false)
        } == 0x10
    }

    static let allTests = [
        ("testValidPassword", testValidPassword),
        ("testValidPasswordFromString", testValidPasswordFromString),
        ("testPasswordOutOfRange", testPasswordOutOfRange),
        ("testCalculateKeyReference", testCalculateKeyReference),
    ]
}
