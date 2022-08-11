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
import HealthCardAccess
@testable import HealthCardControl
import Nimble
import XCTest

// Note: This continuation of `HealthCardTypeExtResetRetryCounterIntegrationTest` exists to separate the count dependent
// tests from the other ones.
final class HealthCardTypeExtResetRetryCounterIntegrationTestCont: CardSimulationTerminalTestCase {
    override class var configFileInput: String {
        "Configuration/configuration_EGK_G2_1_80276883110000095711_GuD_TCP.xml"
    }

    override class var healthCardStatusInput: HealthCardStatus { .valid(cardType: .egk(generation: .g2_1)) }

    func testResetRetryCounterEgk21_wrongSecretWarning() throws {
        let wrongPuk = "9999999" as Format2Pin
        let newPin = "654321" as Format2Pin

        // With setting a new PIN
        expect(
            try Self.healthCard.resetRetryCounterAndSetNewPin(
                puk: wrongPuk,
                newPin: newPin,
                type: EgkFileSystem.Pin.mrpinHome,
                dfSpecific: false
            )
            .test()
        ) == ResetRetryCounterResponse.wrongSecretWarning(retryCount: 9)

        expect(
            try Self.healthCard.resetRetryCounterAndSetNewPin(
                puk: wrongPuk,
                newPin: newPin,
                type: EgkFileSystem.Pin.mrpinHome,
                dfSpecific: false
            )
            .test()
        ) == ResetRetryCounterResponse.wrongSecretWarning(retryCount: 8)

        // Without setting a new PIN
        expect(
            try Self.healthCard.resetRetryCounter(
                puk: wrongPuk,
                type: EgkFileSystem.Pin.mrpinHome,
                dfSpecific: false
            )
            .test()
        ) == ResetRetryCounterResponse.wrongSecretWarning(retryCount: 7)

        expect(
            try Self.healthCard.resetRetryCounter(
                puk: wrongPuk,
                type: EgkFileSystem.Pin.mrpinHome,
                dfSpecific: false
            )
            .test()
        ) == ResetRetryCounterResponse.wrongSecretWarning(retryCount: 6)
    }
}
