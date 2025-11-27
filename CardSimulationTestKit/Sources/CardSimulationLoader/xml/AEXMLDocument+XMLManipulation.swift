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
import Foundation

extension AEXMLDocument {
    enum ConfigurationError: Error {
        case encodingFailed
        case manipulationFailed(XMLPath)
    }

    /**
        Manipulate XML Elements in the Document.

        - Parameter manipulators: List of XMLPathManipulators

        - Returns: self as the Result XML upon success
     */
    internal func manipulateXMLDocument(with manipulators: [XMLPathManipulator] = []) throws -> AEXMLDocument {
        try manipulators.forEach { manipulator in
            let path = manipulator.path
            if let element = self.resolve(path: path) {
                if !self.replace(path: path, with: manipulator.manipulate(path: path, with: element)) {
                    throw ConfigurationError.manipulationFailed(path)
                }
            }
        }
        return self
    }

    internal func createXML(using encoding: String.Encoding = .utf8) throws -> Data {
        guard let configOutputXml = xml.data(using: encoding, allowLossyConversion: false) else {
            throw ConfigurationError.encodingFailed
        }
        return configOutputXml
    }
}
