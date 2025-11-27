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

import CardReaderProviderApi
import Foundation
import HealthCardAccess
@testable import HealthCardControl
import Nimble
import XCTest

final class KeyAgreementIntegrationTest: CardSimulationTerminalTestCase {
    override class var configFileInput: String { "Configuration/configuration_E021D-A5Tp_432_80276883110000218486.xml" }

    func testNegotiatePaceEcdhGmAesCbcCmac128_publisher() {
        let can = try! CAN.from(Data("123123".utf8)) // swiftlint:disable:this force_try
        expect { () -> SecureMessaging? in
            // tag::negotiateSessionKey_publisher[]
            try KeyAgreement.Algorithm.idPaceEcdhGmAesCbcCmac128.negotiateSessionKeyPublisher(
                card: CardSimulationTerminalTestCase.healthCard,
                can: can,
                writeTimeout: 0,
                readTimeout: 10
            )
            // end::negotiateSessionKey_publisher[]
            .test()
        }.toNot(beNil())
    }

    func testNegotiatePaceEcdhGmAesCbcCmac128() async throws {
        let can = try! CAN.from(Data("123123".utf8)) // swiftlint:disable:this force_try
        // tag::negotiateSessionKey[]
        let secureMessaging = try await KeyAgreement.Algorithm.idPaceEcdhGmAesCbcCmac128.negotiateSessionKeyAsync(
            card: CardSimulationTerminalTestCase.healthCard,
            can: can,
            writeTimeout: 0,
            readTimeout: 10
        )
        // end::negotiateSessionKey[]
        expect(secureMessaging).toNot(beNil())
    }

    static let allTests = [
        ("testNegotiatePaceEcdhGmAesCbcCmac128", testNegotiatePaceEcdhGmAesCbcCmac128),
    ]
}
