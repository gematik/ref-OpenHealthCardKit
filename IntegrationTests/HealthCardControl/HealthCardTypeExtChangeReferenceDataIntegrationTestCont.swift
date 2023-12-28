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

// Note: This continuation of `HealthCardTypeExtChangeReferenceDataIntegrationTest` exists to separate
// the count dependent tests from the other ones.
final class HealthCardTypeExtChangeReferenceDataIntegrationTestCont: CardSimulationTerminalTestCase {
    override class var configFileInput: String {
        "Configuration/configuration_EGK_G2_1_80276883110000095711_GuD_TCP.xml"
    }

    override class var healthCardStatusInput: HealthCardStatus {
        .valid(cardType: .egk(generation: .g2_1))
    }

    func testChangeReferenceDataEgk21_wrongSecretWarning() throws {
        let wrongOld = "9999999" as Format2Pin
        let correctOld = "123456" as Format2Pin
        let new = "654321" as Format2Pin

        expect(
            try Self.healthCard.changeReferenceDataSetNewPin(
                old: wrongOld,
                new: new,
                type: EgkFileSystem.Pin.mrpinHome,
                dfSpecific: false
            )
            .test()
        ) == ChangeReferenceDataResponse.wrongSecretWarning(retryCount: 2)

        expect(
            try Self.healthCard.changeReferenceDataSetNewPin(
                old: wrongOld,
                new: new,
                type: EgkFileSystem.Pin.mrpinHome,
                dfSpecific: false
            )
            .test()
        ) == ChangeReferenceDataResponse.wrongSecretWarning(retryCount: 1)

        expect(
            try Self.healthCard.changeReferenceDataSetNewPin(
                old: correctOld,
                new: new,
                type: EgkFileSystem.Pin.mrpinHome,
                dfSpecific: false
            )
            .test()
        ) == ChangeReferenceDataResponse.success
    }
}
