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
@testable import HealthCardControl
import XCTest

class DataSecureTest: XCTestCase {
    func testData_Secure_SHA1() {
        let data = "random value".data(using: .utf8)! //swiftlint:disable:this force_unwrapping
        let expectedHash = try! Data(hex: "7d1d4d4957bfb81f43f5574cecec63f91ae181fb")//swiftlint:disable:this force_try
        XCTAssertEqual(expectedHash, data.sha1())
        XCTAssertNotEqual(expectedHash, "Different".data(using: .utf8)!.sha1()) //swiftlint:disable:this force_unwrapping line_length
    }
}
