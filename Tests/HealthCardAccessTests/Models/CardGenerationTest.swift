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
@testable import HealthCardAccess
import Nimble
import XCTest

class CardGenerationTest: XCTestCase {
    func testParseCardGenerationVersion() {
        expect(CardGeneration.parseCardGeneration(version: 0)) == .g1
        expect(CardGeneration.parseCardGeneration(version: 30002)) == .g1
        expect(CardGeneration.parseCardGeneration(version: 30003)) == .g1P
        expect(CardGeneration.parseCardGeneration(version: 39999)) == .g1P
        expect(CardGeneration.parseCardGeneration(version: 40000)) == .g2
        expect(CardGeneration.parseCardGeneration(version: 40399)) == .g2
        expect(CardGeneration.parseCardGeneration(version: 40400)) == .g2_1
        expect(CardGeneration.parseCardGeneration(version: 50000)) == .g2_1
        expect(CardGeneration.parseCardGeneration(version: -1)).to(beNil())
    }

    func testParseCardGenerationParsing() {
        expect(CardGeneration.parseCardGeneration(data: Data([0x0, 0x0, 0x0]))) == .g1
        expect(CardGeneration.parseCardGeneration(data: Data([0x3, 0x00, 0x02]))) == .g1
        expect(CardGeneration.parseCardGeneration(data: Data([0x3, 0x00, 0x03]))) == .g1P
        expect(CardGeneration.parseCardGeneration(data: Data([0x3, 0x63, 0x63]))) == .g1P
        expect(CardGeneration.parseCardGeneration(data: Data([0x4, 0x00, 0x00]))) == .g2
        expect(CardGeneration.parseCardGeneration(data: Data([0x4, 0x03, 0x63]))) == .g2
        expect(CardGeneration.parseCardGeneration(data: Data([0x4, 0x04, 0x00]))) == .g2_1
        expect(CardGeneration.parseCardGeneration(data: Data([0x5, 0x00, 0x00]))) == .g2_1
        expect(CardGeneration.parseCardGeneration(data: Data())).to(beNil())
    }

    static let allTests = [
        ("testParseCardGenerationVersion", testParseCardGenerationVersion),
        ("testParseCardGenerationParsing", testParseCardGenerationParsing),
    ]
}
