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
import HealthCardAccess
@testable import HealthCardControl
import Nimble
import XCTest

final class CardChannelTypeExtVersionIntegrationTest: CardSimulationTerminalTestCase {
    static let thisConfigFile = "Configuration/configuration_EGK_G2_1_80276883110000095711_GuD_TCP.xml"

    override class func configFile() -> URL? {
        let bundle = Bundle(for: CardSimulationTerminalTestCase.self)
        let path = bundle.resourceFilePath(in: "Resources", for: self.thisConfigFile)
        return path.asURL
    }

    func testReadCardTypeAndVersion() {
        expect {
            var mType: HealthCardPropertyType?
            CardSimulationTerminalTestCase.healthCard.currentCardChannel.readCardType()
                    .run(on: Executor.trampoline)
                    .on { event in
                        mType = event.value
                    }
            return mType
        } == HealthCardPropertyType.egk(generation: .g2_1)
    }
}
