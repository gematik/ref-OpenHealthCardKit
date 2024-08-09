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

/// XML Element manipulator to supply a new value for the given path
public protocol XMLPathManipulator {
    /// The path for this manipulator
    var path: XMLPath { get }

    /**
        Manipulate the given element.

        - Parameters:
            - path: the current path for the passed in element
            - element: the current element to modify

        - Returns: the modified XML element
     */
    func manipulate(path: XMLPath, with element: AEXMLElement) -> AEXMLElement
}

/// The actual function signature that get's invoked to manipulate a specific XML element at the specified path
/// - Parameters:
///     - path: the current path for the passed in element
///     - element: the current element to modify
/// - Returns: the modified XML element
public typealias XMLPathManipulatorFunction = (_ path: XMLPath, _ element: AEXMLElement) -> AEXMLElement

/// XML Manipulator holder
public struct XMLPathManipulatorHolder {
    /// The XML path for this manipulator to respond to
    public let path: XMLPath
    /// The manipulator function held by this holder
    public let manipulator: XMLPathManipulatorFunction

    /// Initialize a Manipulator holder with path and manipulator
    /// - Parameters:
    ///     - path: the current path for the passed in element
    ///     - element: the current element to modify
    public init(path: XMLPath, manipulator: @escaping XMLPathManipulatorFunction) {
        self.path = path
        self.manipulator = manipulator
    }
}

extension XMLPathManipulatorHolder: XMLPathManipulator {
    /// Execute the manipulator on a given element
    /// - Parameters:
    ///     - path: the current path for the passed in element
    ///     - element: the current element to modify
    /// - Returns: the modified XML element
    public func manipulate(path: XMLPath, with element: AEXMLElement) -> AEXMLElement {
        manipulator(path, element)
    }
}

extension XMLPathManipulatorHolder {
    /// TLV Port XML Path
    public static let TLVPortXMLPath = "configuration.ioConfiguration.port" as XMLPath
    /// Card image file XML Path
    public static let CardConfigFileXMLPath = "configuration.general.attribute{id:cardImageFile}" as XMLPath
    /// Channel file XML Path
    public static let ChannelConfigFileXMLPath = "configuration.general.attribute{id:channelContextFile}" as XMLPath

    /// Default TLV Manipulator
    /// - Parameter port: the port to inject into `TLVPortXMLPath` element
    /// - Returns: XML manipulator to set the port in the XML config file
    public static func tlvPortManipulator(port: String) -> XMLPathManipulator {
        XMLPathManipulatorHolder(path: TLVPortXMLPath) { _, element in
            element.value = port
            return element
        }
    }

    /**
        Create an XML Path manipulator that translates relative paths to absolute paths with the given absolutePath

        - Parameters:
            - path: the path for manipulator
            - absolutePath: the absolute path the prepend to the relative path

        - Returns: XML manipulator that modifies relative path for the give path
     */
    public static func relativeToAbsolutePathManipulator(
        with path: XMLPath,
        absolutePath: URL
    ) -> XMLPathManipulator {
        XMLPathManipulatorHolder(path: path) { _, element in
            if var elementValue = element.value {
                if elementValue.hasPrefix("../") || elementValue.hasPrefix("./") {
                    elementValue = absolutePath.appendingPathComponent(elementValue).absoluteURL.path
                }
                element.value = elementValue
            }
            return element
        }
    }
}
