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

class CardVersion2Test: XCTestCase {
    func testCardVersionParsingFromData() {
        do {
            let data = try Data(hex: "EF2BC003020000C103040302C21045474B473220" +
                "20202020202020010304C403010000C503020000C703010000")
            let version2 = try CardVersion2(data: data)
            expect(version2.fillingInstructionsEfAtrVersion) == Data([0x02, 0x00, 0x00]) // C5
            expect(version2.fillingInstructionsEfAtrVersion) == Data([0x02, 0x00, 0x00]) // C5
            expect(version2.fillingInstructionsEfEnvironmentSettingsVersion).to(beNil()) // C3
            expect(version2.fillingInstructionsEfGdoVersion) == Data([0x01, 0x00, 0x00]) // C4
            expect(version2.fillingInstructionsEfKeyInfoVersion).to(beNil()) // C6
            expect(version2.fillingInstructionsEfLoggingVersion) == Data([0x01, 0x00, 0x00]) // C7
            expect(version2.fillingInstructionsVersion) == Data([0x02, 0x00, 0x00]) // C0
            expect(version2.objectSystemVersion) == Data([0x04, 0x03, 0x02]) // C1
            let objSystemVersion = Data(
                [0x45, 0x47, 0x4B, 0x47, 0x32, 0x20, 0x20, 0x20,
                 0x20, 0x20, 0x20, 0x20, 0x20, 0x01, 0x03, 0x04]
            ) // C2
            expect(version2.productIdentificationObjectSystemVersion) == objSystemVersion

            expect(version2.generation()) == .g2
        } catch {
            Nimble.fail("Error: \(error)")
        }
    }

    static let allTests = [
        ("testCardVersionParsingFromData", testCardVersionParsingFromData),
    ]
}
