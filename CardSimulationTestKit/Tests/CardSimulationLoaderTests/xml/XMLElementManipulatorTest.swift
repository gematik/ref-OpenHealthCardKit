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
import Foundation
import Nimble
import XCTest

final class XMLElementManipulatorTest: XCTestCase {
    func testTLVPortManipulator() {
        let manipulator = XMLPathManipulatorHolder.tlvPortManipulator(port: "0")
        expect(manipulator.path).to(equal("configuration.ioConfiguration.port" as XMLPath))
        let element = AEXML.AEXMLElement(name: "port", value: "12345")
        let manipulatedElement = manipulator.manipulate(path: "configuration.ioConfiguration.port", with: element)
        expect(manipulatedElement.value).to(equal("0"))
        expect(manipulatedElement.name).to(equal(element.name))
    }

    func testRelativePathManipulator() {
        let absoluteDirectoryPath = "/My/Awesome-Path/With space/ïn path".asURL
        let manipulator = XMLPathManipulatorHolder
            .relativeToAbsolutePathManipulator(with: XMLPathManipulatorHolder.CardConfigFileXMLPath,
                                               absolutePath: absoluteDirectoryPath)
        let element = AEXML.AEXMLElement(name: "attribute",
                                         value: "../Some/Path/To/File.xml",
                                         attributes: ["id": "channelContextFile"])
        let manipulatedElement = manipulator.manipulate(path: "configuration.general.attribute{id:channelContextFile}",
                                                        with: element)
        expect(manipulatedElement.value).to(equal("/My/Awesome-Path/With space/ïn path/../Some/Path/To/File.xml"))
        expect(manipulatedElement.name).to(equal(element.name))
    }

    static var allTests = [
        ("testTLVPortManipulator", testTLVPortManipulator),
        ("testRelativePathManipulator", testRelativePathManipulator),
    ]
}
