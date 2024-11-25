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

final class HealthCardTypeExtVerifyPinTest: CardSimulationTerminalTestCase {
    override class var configFileInput: String {
        "Configuration/configuration_EGK_G2_1_80276883110000095711_GuD_TCP.xml"
    }

    override class var healthCardStatusInput: HealthCardStatus { .valid(cardType: .egk(generation: .g2_1)) }

    func testVerifyMrPinHomeEgk21_publisher() {
        let pinCode = "123456"
        expect {
            let format2Pin = try Format2Pin(pincode: pinCode)
            return try Self.healthCard.verifyPublisher(pin: format2Pin, type: EgkFileSystem.Pin.mrpinHome)
                .test()
        } == VerifyPinResponse.success
    }

    func testVerifyMrPinHomeEgk21() async throws {
        let pinCode = "123456"
        let format2Pin = try Format2Pin(pincode: pinCode)
        let response = try await Self.healthCard.verifyAsync(pin: format2Pin, type: EgkFileSystem.Pin.mrpinHome)
        expect(response) == VerifyPinResponse.success
    }

    func testVerifyMrPinHomeEgk21_WarningRetryCounter_publisher() {
        let pinCode = "654321"
        expect {
            let format2Pin = try Format2Pin(pincode: pinCode)
            return try Self.healthCard.verifyPublisher(pin: format2Pin, type: EgkFileSystem.Pin.mrpinHome)
                .test()
        } == VerifyPinResponse.wrongSecretWarning(retryCount: 2)
    }

    func testVerifyMrPinHomeEgk21_WarningRetryCounter() async throws {
        let pinCode = "654321"
        let format2Pin = try Format2Pin(pincode: pinCode)
        let response = try await Self.healthCard.verifyAsync(pin: format2Pin, type: EgkFileSystem.Pin.mrpinHome)
        // Note: The retry counter is not reset after each test case. Therefore, the retry counter is 1 here.
        expect(response) == VerifyPinResponse.wrongSecretWarning(retryCount: 1)
    }
}
