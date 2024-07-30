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
import GemCommonsKit
import Nimble
import XCTest

final class URLExtConfigurationFileProcessorTest: XCTestCase {
    func testProcessConfigFile() {
        let configFile = Bundle(for: URLExtConfigurationFileProcessorTest.self)
            .testResourceFilePath(in: "Resources", for: "configuration.xml")
            .asURL

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
        let xmlResult = configFile.prepareXMLConfigFile(with: manipulators)
        expect {
            try xmlResult.get()
        }.to(satisfyAllOf(
            Predicate { expr in
                let configElement = try? expr.evaluate()?
                    .root["general"]["attribute"]
                    .all(withAttributes: ["id": "cardImageFile"])?[0]
                let condition = configElement?.value == "changed_../images/HBAG2_80276883110000017289_gema5.xml"
                return PredicateResult(bool: condition, message: .expectedTo("Have changed the cardImageFile"))
            },
            Predicate { expr in
                PredicateResult(bool: try expr.evaluate()?.root["ioConfiguration"]["port"].value == "0",
                                message: .expectedTo("Have 0 as ioConfiguration/port"))
            }
        ))
    }

    static var allTests = [
        ("testProcessConfigFile", testProcessConfigFile),
    ]
}
