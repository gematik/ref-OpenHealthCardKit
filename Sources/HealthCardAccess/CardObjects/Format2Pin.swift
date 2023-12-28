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

import DataKit
import Foundation

/// PIN block, formatted according to gemSpec_COS 8.1.7
/// and [`ISO9564`](https://en.wikipedia.org/wiki/ISO_9564) standard
public struct Format2Pin: CardItemType {
    private static let minPinLen = 4 // gemSpec_COS#N008.000
    private static let maxPinLen = 12 // gemSpec_COS#N008.000

    public enum Error: Swift.Error, Equatable {
        case illegalArgument(String)
    }

    /**
         PIN block
         ****************************************
         PAN:            43219876543210987
         PIN:            1234
         PAD:            N/A
         Format:         Format 2 (ISO-2)
         ----------------------------------------
         Clear PIN block:241234FFFFFFFFFF
     */
    public let pin: Data

    private static let regex = "^[0-9]{\(minPinLen),\(maxPinLen)}$"

    private static let pinRegex = {
        // see COS spec chapter 8.1.7
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: regex, options: .caseInsensitive)
    }()

    /**
        Format and check pincode

        - Parameter pincode: min 4 and max 12 character string consisting of numbers only

        - Throws: Format2Pin.Error when the pincode param is invalid
     */
    public init(pincode: String) throws {
        // gemSpec_COS#N008.000
        guard Format2Pin.pinRegex.numberOfMatches(in: pincode,
                                                  range: NSRange(location: 0, length: pincode.count)) == 1 else {
            throw Error.illegalArgument("Invalid pin: [\(pincode)] does not conform to regex: [\(Format2Pin.regex)]")
        }
        // gemSpec_COS#N008.100.b,c,d,e
        let paddedPin = (pincode as NSString).padding(toLength: 14, withPad: "F", startingAt: 0)
        let buffer = String(format: "2%hX%@", pincode.count, paddedPin)

        // gemSpec_COS#N008.100.a
        pin = try Data(hex: buffer)
    }
}

extension Format2Pin: ExpressibleByStringLiteral {
    /// Grapheme for Password is String
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    /// Unicode scalar for Password is String
    public typealias UnicodeScalarLiteralType = String

    /**
        Initialize a Pincode Format2Pin with a Hex value

        - Parameter value: Hex string with range {4,12}
     */
    public init(stringLiteral value: StringLiteralType) {
        do {
            try self.init(pincode: value)
        } catch {
            preconditionFailure("\(error)")
        }
    }

    /**
        Initialize a Pincode Format2Pin with a Hex value

        - Parameter value: Hex string with range {4,12}
     */
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.init(stringLiteral: value)
    }

    /**
        Initialize a Pincode Format2Pin with a Hex value

        - Parameter value: Hex string with range {4,12}
     */
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.init(stringLiteral: value)
    }
}
