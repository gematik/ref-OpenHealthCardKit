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

import AEXML
@testable import CardSimulationLoader
import Nimble
import OSLog
import XCTest

final class AEXMLDocumentExtXMLManipulationTest: XCTestCase {
    func testXMLManipulation() {
        do {
            let configData = try Data(contentsOf: Bundle(for: AEXMLDocumentExtXMLManipulationTest.self)
                .testResourceFilePath(in: "Resources", for: "configuration.xml")
                .asURL)
            let xmlDoc = try AEXMLDocument(xml: configData)

            let manipulators: [XMLPathManipulator] = [
                XMLPathManipulatorHolder(path: "configuration.general.attribute{id:cardImageFile}") { _, element in
                    element.value = "changed_" + (element.value ?? "no-value")
                    return element
                },
                XMLPathManipulatorHolder(path: "configuration.ioConfiguration.port") { _, element in
                    element.value = "0"
                    return element
                },
            ]
            let xmlResult = try xmlDoc.manipulateXMLDocument(with: manipulators)
            let configElement = xmlResult.root["general"]["attribute"].all(withAttributes: ["id": "cardImageFile"])?[0]
            expect(configElement?.value).to(equal("changed_../images/HBAG2_80276883110000017289_gema5.xml"))
            expect(xmlResult.root["ioConfiguration"]["port"].value).to(equal("0"))
        } catch {
            Logger.cardSimulationLoaderTests.fault("Test-case failed: [\(error)]")
            Nimble.fail("Failed with error \(error)")
        }
    }

    static var allTests = [
        ("testXMLManipulation", testXMLManipulation),
    ]
}
