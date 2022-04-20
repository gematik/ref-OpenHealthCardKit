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

import Foundation
@testable import HealthCardControl
import XCTest

class DataSecureTest: XCTestCase {
    func testData_Secure_SHA1() throws {
        let data = "random value".data(using: .utf8)! // swiftlint:disable:this force_unwrapping
        let expectedHash = try Data(hex: "7d1d4d4957bfb81f43f5574cecec63f91ae181fb")
        XCTAssertEqual(expectedHash, data.sha1())
        XCTAssertNotEqual(expectedHash, "Different".data(using: .utf8)?.sha1())
    }

    func testData_Secure_SHA256() throws {
        let data = "random value".data(using: .utf8)! // swiftlint:disable:this force_unwrapping
        let expectedHash = try Data(hex: "d20ad08d0a9ed1cf3f14a0faca4f018830bad7c5907a32a1799b10e19e4bfe70")
        XCTAssertEqual(expectedHash, data.sha256())
        XCTAssertNotEqual(expectedHash, "Different".data(using: .utf8)?.sha256())
    }
}
