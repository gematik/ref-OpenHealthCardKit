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
import Foundation
import GemCommonsKit

/**
    This extension is supposed to copy the configuration file to a tmp path
     while giving the delegate the option to manipulate the config values ad hoc.
 */
extension URL: ConfigurationFileProcessor {
    /**
        Prepare the configuration for the simulation runtime by mutating its original contents by the `manipulators`.

        - Note: The contents of the file at the URL path needs to be XML formatted.

        - Parameters:
            - manipulators: The XMLManipulators for the specified XML paths

        - Returns: the with manipulators manipulated Result<AEXMLDocument, Swift.Error>
     */
    public func prepareXMLConfigFile(with manipulators: [XMLPathManipulator] = [])
        -> Result<AEXMLDocument, Swift.Error> {
        Result {
            try self.readFileContents()
        }
        .flatMap { configXmlData in
            Result {
                try AEXMLDocument(xml: configXmlData)
            }
        }
        .flatMap { (configXml: AEXMLDocument) in
            Result {
                try configXml.manipulateXMLDocument(with: manipulators)
            }
        }
    }
}
