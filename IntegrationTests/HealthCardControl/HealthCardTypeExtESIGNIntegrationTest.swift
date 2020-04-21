//
//  Copyright (c) 2020 gematik GmbH
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//     http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import CardSimulationTerminalTestCase
import Foundation
import HealthCardAccess
@testable import HealthCardControl
import Nimble
import XCTest

final class HealthCardTypeExtESIGNIntegrationTest: CardSimulationTerminalTestCase {
    static let thisConfigFile = "Configuration/configuration_EGK_G2_1_80276883110000095711_GuD_TCP.xml"

    override class func configFile() -> URL? {
        let bundle = Bundle(for: CardSimulationTerminalTestCase.self)
        let path = bundle.resourceFilePath(in: "Resources", for: self.thisConfigFile)
        return path.asURL
    }

    func testSignForAuthentication() {

        expect {
            var response: HealthCardResponseType?
            // tag::signChallenge[]
            let challenge = Data([0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8])
            let format2Pin = try Format2Pin(pincode: "123456")
            CardSimulationTerminalTestCase.healthCard
                    .verify(pin: format2Pin, type: EgkFileSystem.Pin.mrpinHome)
                    .flatMap { _ in
                        CardSimulationTerminalTestCase.healthCard.sign(challenge: challenge)
                    }
                    .run(on: Executor.trampoline)
                    // end::signChallenge[]
                    .on { event in
                        response = event.value
                    }
            return response?.responseStatus
        } == ResponseStatus.success
    }

    static let allTests = [
        ("testSignForAuthentication", testSignForAuthentication)
    ]
}
