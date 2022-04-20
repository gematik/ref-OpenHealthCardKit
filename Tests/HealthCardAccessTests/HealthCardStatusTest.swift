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
@testable import HealthCardAccess
import Nimble
import XCTest

class HealthCardStatusTest: XCTestCase {
    func testGeneration() {
        let unknown = HealthCardStatus.unknown
        let valid = HealthCardStatus.valid(cardType: .egk(generation: .g2_1))
        let invalid = HealthCardStatus.invalid

        expect(unknown.generation).to(beNil())
        expect(valid.generation) == .g2_1
        expect(invalid.generation).to(beNil())
    }

    func testType() {
        let unknown = HealthCardStatus.unknown
        let valid = HealthCardStatus.valid(cardType: .egk(generation: .g2_1))
        let invalid = HealthCardStatus.invalid

        expect(unknown.type).to(beNil())
        expect(valid.type) == .egk(generation: .g2_1)
        expect(invalid.type).to(beNil())
    }

    func testIsValid() {
        let unknown = HealthCardStatus.unknown
        let valid = HealthCardStatus.valid(cardType: .egk(generation: .g2_1))
        let invalid = HealthCardStatus.invalid

        expect(unknown.isValid).to(beFalse())
        expect(valid.isValid).to(beTrue())
        expect(invalid.isValid).to(beFalse())
    }

    static let allTests = [
        ("testGeneration", testGeneration),
        ("testType", testType),
        ("testIsValid", testIsValid),
    ]
}
