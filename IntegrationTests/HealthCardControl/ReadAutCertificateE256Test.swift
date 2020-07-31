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
import GemCommonsKit
import HealthCardAccess
@testable import HealthCardControl
import Nimble
import XCTest

final class ReadAutCertificateE256Test: CardSimulationTerminalTestCase {
    static let thisConfigFile = "Configuration/configuration_EGK_G2_1_ecc.xml"

    override class func configFile() -> URL? {
        let bundle = Bundle(for: CardSimulationTerminalTestCase.self)
        let path = bundle.resourceFilePath(in: "Resources", for: self.thisConfigFile)
        return path.asURL
    }

    private var expectedCertificate: Data!

    override func setUp() {
        super.setUp()

        let bundle = Bundle(for: ReadAutCertificateE256Test.self)
        let path = bundle.testResourceFilePath(in: "Resources", for: "Certificates/esignCChAutE256.cer").asURL
        do {
            expectedCertificate = try Data(contentsOf: path)
        } catch let error {
            ALog("Could not read certificate file: \(path)\nError: \(error)")
        }
    }

    func testReadAutCertificateE256() {
        // setup: Instantiate health card object with card type eGk 2.1
        let egkCardStatus = HealthCardStatus.valid(cardType: HealthCardPropertyType.egk(generation: .g2_1))
        // swiftlint:disable:next force_try
        let healthCard = try! HealthCard(card: CardSimulationTerminalTestCase.card, status: egkCardStatus)

        var autCertificateResponse: AutCertificateResponse?
        expect {
            autCertificateResponse = try healthCard
                    .readAutCertificate()
                    .test()
        }.toNot(throwError())
        expect(autCertificateResponse?.info) == .efAutE256
        expect(autCertificateResponse?.certificate) == expectedCertificate
    }
}
