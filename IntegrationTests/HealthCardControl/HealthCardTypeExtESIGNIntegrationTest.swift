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

final class HealthCardTypeExtESIGNIntegrationTest: CardSimulationTerminalTestCase {
    override class var configFileInput: String {
        "Configuration/configuration_EGK_G2_1_80276883110000095711_GuD_TCP.xml"
    }

    override class var healthCardStatusInput: HealthCardStatus { .valid(cardType: .egk(generation: .g2_1)) }

    func testSignForAuthentication_publisher() {
        // tag::signChallenge_publisher[]
        expect {
            let challenge = Data([0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8])
            let format2Pin = try Format2Pin(pincode: "123456")
            return try Self.healthCard.verify(pin: format2Pin, type: EgkFileSystem.Pin.mrpinHome)
                .flatMap { _ in
                    Self.healthCard.sign(data: challenge)
                }
                .eraseToAnyPublisher()
                .test()
                .responseStatus
        } == ResponseStatus.success
        // end::signChallenge_publisher[]
    }

    func testSignForAuthentication() async throws {
        // tag::signChallenge[]
        let challenge = Data([0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8])
        let format2Pin = try Format2Pin(pincode: "123456")
        _ = try await Self.healthCard.verify(pin: format2Pin, type: EgkFileSystem.Pin.mrpinHome)
        let signResponse = try await Self.healthCard.signAsync(data: challenge)
        expect(signResponse.responseStatus) == ResponseStatus.success
        // end::signChallenge[]
    }
}
