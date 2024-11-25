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

import Foundation
import HealthCardAccess
@testable import HealthCardControl
import Nimble
import Util
import XCTest

final class DetermineCardAidIntegrationTest: CardSimulationTerminalTestCase {
    override class var configFileInput: String { "Configuration/configuration_EGK_G2_1_ecc.xml" }
    override class var healthCardStatusInput: HealthCardStatus { .valid(cardType: .egk(generation: .g2_1)) }

    func testDetermineCardAid_publisher() {
        expect {
            try Self.healthCard.currentCardChannel.determineCardAidPublisher()
                .test()
        } == CardAid.egk
    }

    func testDetermineCardAid() async throws {
        let result = try await Self.healthCard.currentCardChannel.determineCardAidAsync()
        expect(result) == CardAid.egk
    }
}
