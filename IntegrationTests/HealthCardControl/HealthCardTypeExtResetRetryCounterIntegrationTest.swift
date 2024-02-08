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

final class HealthCardTypeExtResetRetryCounterIntegrationTest: CardSimulationTerminalTestCase {
    override class var configFileInput: String {
        "Configuration/configuration_EGK_G2_1_80276883110000095711_GuD_TCP.xml"
    }

    override class var healthCardStatusInput: HealthCardStatus { .valid(cardType: .egk(generation: .g2_1)) }

    func testResetRetryCounterEgk21_success_publisher() throws {
        let puk = "12345678" as Format2Pin

        expect(
            try Self.healthCard.resetRetryCounter(
                puk: puk,
                type: EgkFileSystem.Pin.mrpinHome,
                dfSpecific: false
            )
            .test()
        ) == ResetRetryCounterResponse.success
    }

    func testResetRetryCounterEgk21_success() async throws {
        let puk = "12345678" as Format2Pin

        let response = try await Self.healthCard.resetRetryCounter(
            puk: puk,
            type: EgkFileSystem.Pin.mrpinHome,
            dfSpecific: false
        )
        expect(response) == ResetRetryCounterResponse.success
    }

    func testResetRetryCounterWithNewPinEgk21_success_publisher() throws {
        let puk = "12345678" as Format2Pin
        let newPin = "654321" as Format2Pin

        expect(
            try Self.healthCard.resetRetryCounterAndSetNewPin(
                puk: puk,
                newPin: newPin,
                type: EgkFileSystem.Pin.mrpinHome,
                dfSpecific: false
            )
            .test()
        ) == ResetRetryCounterResponse.success
    }

    func testResetRetryCounterWithNewPinEgk21_success() async throws {
        let puk = "12345678" as Format2Pin
        let newPin = "654321" as Format2Pin

        let response = try await Self.healthCard.resetRetryCounterAndSetNewPin(
            puk: puk,
            newPin: newPin,
            type: EgkFileSystem.Pin.mrpinHome,
            dfSpecific: false
        )
        expect(response) == ResetRetryCounterResponse.success
    }

    func testResetRetryCounterWithNewPinEgk21_wrongPasswordLength_publsher() throws {
        let puk = "12345678" as Format2Pin
        let tooLongNewPin = "654112341234" as Format2Pin

        expect(
            try Self.healthCard.resetRetryCounterAndSetNewPin(
                puk: puk,
                newPin: tooLongNewPin,
                type: EgkFileSystem.Pin.mrpinHome,
                dfSpecific: false
            )
            .test()
        ) == ResetRetryCounterResponse.wrongPasswordLength
    }

    func testResetRetryCounterWithNewPinEgk21_wrongPasswordLength() async throws {
        let puk = "12345678" as Format2Pin
        let tooLongNewPin = "654112341234" as Format2Pin

        let response = try await Self.healthCard.resetRetryCounterAndSetNewPin(
            puk: puk,
            newPin: tooLongNewPin,
            type: EgkFileSystem.Pin.mrpinHome,
            dfSpecific: false
        )
        expect(response) == ResetRetryCounterResponse.wrongPasswordLength
    }
}
