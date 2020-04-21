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

import BigInt
import CardReaderProviderApi
import CardSimulationTerminalTestCase
import Foundation
import GemCommonsKit
import HealthCardAccess
@testable import HealthCardControl
import Nimble
import XCTest

final class KeyAgreementIntegrationTest: CardSimulationTerminalTestCase {
    static let thisConfigFile = "Configuration/configuration_TLK_COS_image-kontaktlos128.xml"

    override class func configFile() -> URL? {
        let bundle = Bundle(for: CardSimulationTerminalTestCase.self)
        let path = bundle.resourceFilePath(in: "Resources", for: self.thisConfigFile)
        return path.asURL
    }

    func testNegotiatePaceEcdhGmAesCbcCmac128() {
        let can = try! CAN.from(Data("12345678".utf8)) //swiftlint:disable:this force_try
        expect {
            var paceKey: SecureMessaging?
            // tag::negotiateSessionKey[]
            try KeyAgreement.Algorithm.idPaceEcdhGmAesCbcCmac128.negotiateSessionKey(
                            channel: CardSimulationTerminalTestCase.healthCard.currentCardChannel,
                            can: can,
                            writeTimeout: 0,
                            readTimeout: 10)
                    .run(on: Executor.trampoline)
                    // end::negotiateSessionKey[]
                    .on { event in
                        paceKey = event.value
                    }
            return paceKey
        }.toNot(throwError())
    }

    static let allTests = [
        ("testNegotiatePaceEcdhGmAesCbcCmac128", testNegotiatePaceEcdhGmAesCbcCmac128)
    ]
}
