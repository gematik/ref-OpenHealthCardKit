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

import AEXML
@testable import AEXMLExt
import Nimble
import XCTest

final class AEXMLElementExtRootTest: XCTestCase {
    func testReplaceChild() {
        let animals = AEXMLElement(name: "animals")
        let dogs = AEXMLElement(name: "dogs")
        dogs.addChild(AEXMLElement(name: "dog", value: "Blackie", attributes: ["breed": "Puppy", "color": "purple"]))
        dogs.addChild(AEXMLElement(name: "dog", value: "Brain", attributes: ["breed": "Puppy", "color": "purple"]))
        dogs.addChild(AEXMLElement(name: "dog", value: "Betty", attributes: ["breed": "Puppy", "color": "purple"]))
        animals.addChild(dogs)
        let xmlDocument = AEXMLDocument(root: animals)
        let newDog = AEXMLElement(name: "dog", value: "Jacky", attributes: ["breed": "Puppy", "color": "purple"])

        let dogsElement = xmlDocument.root["dogs"]
        let oldDog = dogsElement.replaceChild(at: 2, with: newDog)

        expect(oldDog.value) == "Betty"
        expect(dogsElement.children[2]) === newDog
        expect(newDog.parent) === dogsElement
    }

    static var allTests = [
        ("testReplaceChild", testReplaceChild),
    ]
}
