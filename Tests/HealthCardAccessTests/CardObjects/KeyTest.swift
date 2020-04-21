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

final class KeyTest: XCTestCase {
    func testValidKey() {
        for keyId: UInt8 in 2...28 {
            expect {
                try Key(keyId)
            }.toNot(throwError())
        }
    }

    func testOutOfRangeKeys() {
        // gemSpec_COS#N016.400 and #N017.100
        var invalidKeys = [UInt8]()
        for idx: UInt8 in 29..<0xff {
            invalidKeys.append(idx)
        }
        invalidKeys.append(0)
        invalidKeys.append(1)
        invalidKeys.forEach { keyId in
            expect {
                try Key(keyId)
            }.to(throwError(Key.Error.illegalArgument("Password ID: [\(keyId)] out of range [2,28]")))
        }
    }

    static let allTests = [
        ("testValidKey", testValidKey),
        ("testOutOfRangeKeys", testOutOfRangeKeys)
    ]
}
