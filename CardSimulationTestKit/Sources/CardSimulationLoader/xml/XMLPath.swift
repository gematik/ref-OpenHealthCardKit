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
import AEXMLExt
import Foundation

/**
    XML paths specified as . separated Strings.
 */
public struct XMLPath {
    /// XPath formatted path
    public let path: String

    var components: [String] {
        path.components(separatedBy: ".")
    }
}

extension XMLPath: ExpressibleByStringLiteral {
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = StringLiteralType

    public init(stringLiteral value: StringLiteralType) {
        path = value
    }

    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        path = value
    }

    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        path = value
    }
}

extension XMLPath: Hashable {
    // swiftlint:disable:next operator_whitespace
    public static func ==(lhs: XMLPath, rhs: XMLPath) -> Bool {
        lhs.path == rhs.path
    }
}

extension AEXMLDocument {
    /**
        Resolve a XMLPath from this XML document's root

        Example:
        ```
        <?xml version="1.0" encoding="utf-8"?>
        <configuration>
            <node>
                <element>Value</element>
                <element>Value2</element>
                <element id="123">Value2</element>
            </node>
        </configuration>
        ```

        To get <element> out of this document use:

        ```
        "configuration.node.element" as XMLPath
        ```

        Or to get element with Value2:
        ```
        "configuration.node.element[1]" as XMLPath
        ```

        And to get element id="123":
        ```
        "configuration.node.element{id:123}" as XMLPath
        ```

        - Parameter path: The path to resolve

        - Returns: The XML element when found
     */
    func resolve(path: XMLPath) -> AEXMLElement? {
        let foundElement: AEXMLElement? = path.components
            .reduce((0, nil)) { [unowned self] elementTuple, subPath -> (Int, AEXMLElement?) in
                let firstElem = elementTuple.0 + 1
                guard let element = elementTuple.1 else {
                    // Verify root.name is equal to subPath[0]
                    if firstElem == 1, self.root.name == subPath {
                        return (firstElem, self.root)
                    }
                    return (firstElem, nil)
                }
                if let index = subPath.match(pattern: "^.*\\[(\\d*)\\]$"), let idx = Int(index) {
                    /// check for child element at index
                    return (firstElem, element.children[idx])
                }
                /// Check for attribute matching
                if let attribute = subPath.match(pattern: "^.*\\{([\\w]*:{1}[\\w]*)\\}$"),
                   let upTo = subPath.firstIndex(of: "{") {
                    let elementName = String(subPath.prefix(upTo: upTo))
                    let mElement = element[elementName]
                    let attributeComponents = attribute.components(separatedBy: ":")
                    let attributeName = attributeComponents[0]
                    let attributeValue = attributeComponents[1]
                    let found = mElement.all(withAttributes: [attributeName: attributeValue])
                    guard found?.count ?? 0 > 0 else {
                        return (firstElem, nil)
                    }
                    return (firstElem, found?[0])
                }
                return (firstElem, element[subPath])
            }.1

        /// AEXMLDocument["key"] always returns an AEXMLElement, the only way to figure out whether
        /// the path did not exists is checking for the error property
        if let err = foundElement?.error, err == .elementNotFound {
            return nil
        }
        return foundElement
    }

    /**
        Replace the element at path

        - Parameters:
            - path: the XML path to replace
            - element: the XML Element to change

        - Returns: true when path was found and replaced
     */
    func replace(path: XMLPath, with element: AEXMLElement) -> Bool {
        guard let elementBefore = resolve(path: path), let parentElement = elementBefore.parent,
              !parentElement.isRoot else {
            return false
        }
        guard let index = parentElement.children.firstIndex(where: { elem in elem === elementBefore }) else {
            /// Child at index not found (impossible)
            return false
        }
        _ = parentElement.replaceChild(at: index, with: element)
        return true
    }
}

extension String {
    /**
         Returns the nth found group by the pattern matched as a string.
     */
    public func match(pattern: String, group number: Int = 1) -> String? {
        guard let regex = try? NSRegularExpression(pattern: "\(pattern)") else {
            return nil
        }
        let result = regex.matches(in: self, options: [], range: NSRange(location: 0, length: count))
        guard !result.isEmpty, result[0].numberOfRanges > 1, result[0].numberOfRanges > number else {
            return nil
        }

        return (self as NSString).substring(with: result[0].range(at: number))
    }
}
