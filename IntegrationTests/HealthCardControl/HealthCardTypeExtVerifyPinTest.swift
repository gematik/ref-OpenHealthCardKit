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

final class HealthCardTypeExtVerifyPinTest: CardSimulationTerminalTestCase {
    static let thisConfigFile = "Configuration/configuration_EGK_G2_1_80276883110000095711_GuD_TCP.xml"

    override class func configFile() -> URL? {
        let bundle = Bundle(for: CardSimulationTerminalTestCase.self)
        let path = bundle.resourceFilePath(in: "Resources", for: self.thisConfigFile)
        return path.asURL
    }

    func testVerifyMrPinHomeEgk21() {
        let pinCode = "123456"
        expect {
            let format2Pin = try Format2Pin(pincode: pinCode)
            var response: VerifyPinResponse?
            CardSimulationTerminalTestCase.healthCard.verify(pin: format2Pin, type: EgkFileSystem.Pin.mrpinHome)
                    .run(on: Executor.trampoline)
                    .on { event in
                        response = event.value
                    }
            return response
        } == VerifyPinResponse.success
    }

    func testVerifyMrPinHomeEgk21Failing() {
        let pinCode = "654321"
        expect {
            let format2Pin = try Format2Pin(pincode: pinCode)
            var response: VerifyPinResponse?
            CardSimulationTerminalTestCase.healthCard.verify(pin: format2Pin, type: EgkFileSystem.Pin.mrpinHome)
                    .run(on: Executor.trampoline)
                    .on { event in
                        response = event.value
                    }
            return response
        } == VerifyPinResponse.failed(retryCount: 2)
    }

    static let allTests = [
        ("testVerifyMrPinHomeEgk21", testVerifyMrPinHomeEgk21),
        ("testVerifyMrPinHomeEgk21Failing", testVerifyMrPinHomeEgk21Failing)
    ]
}
