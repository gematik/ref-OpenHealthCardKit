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
import GemCommonsKit
import HealthCardAccess
@testable import HealthCardControl
import Nimble
import Util
import XCTest

final class CardChannelTypeExtVersionIntegrationTest: CardSimulationTerminalTestCase {
    override class var configFileInput: String {
        "Configuration/configuration_EGK_G2_1_80276883110000095711_GuD_TCP.xml"
    }

    func testReadCardTypeFromVersion_publisher() {
        expect {
            try Self.healthCard.currentCardChannel.readCardType()
                .test()
        } == HealthCardPropertyType.egk(generation: .g2_1)
    }

    func testReadCardTypeFromVersion() async throws {
        let cardType = try await Self.healthCard.currentCardChannel.readCardType()
        expect(cardType) == HealthCardPropertyType.egk(generation: .g2_1)
    }

    func testDetermineCardAidThenReadCardTypeFromVersion_publisher() {
        expect {
            try Self.healthCard.currentCardChannel.determineCardAid()
                .flatMap { cardAid in
                    Self.healthCard.currentCardChannel.readCardType(cardAid: cardAid)
                }
                .eraseToAnyPublisher()
                .test()
        } == HealthCardPropertyType.egk(generation: .g2_1)
    }

    func testDetermineCardAidThenReadCardTypeFromVersion() async throws {
        let cardAid = try await Self.healthCard.currentCardChannel.determineCardAid()
        let cardType = try await Self.healthCard.currentCardChannel.readCardType(cardAid: cardAid)
        expect(cardType) == HealthCardPropertyType.egk(generation: .g2_1)
    }

    func testReadCardTypeFromVersionWithKnownCardAid_publisher() {
        let cardAid = CardAid.egk
        expect {
            try Self.healthCard.currentCardChannel.readCardType(cardAid: cardAid)
                .test()
        } == HealthCardPropertyType.egk(generation: .g2_1)
    }

    func testReadCardTypeFromVersionWithKnownCardAid() async throws {
        let cardAid = CardAid.egk
        let cardType = try await Self.healthCard.currentCardChannel.readCardType(cardAid: cardAid)
        expect(cardType) == HealthCardPropertyType.egk(generation: .g2_1)
    }
}
