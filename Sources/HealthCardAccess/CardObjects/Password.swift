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

import Foundation

/// Password Identifier as per gemSpec_COS#N015.000
public struct Password: CardItemType, CardKeyReferenceType {
    private static let minPwdId: UInt8 = 0; // gemSpec_COS#N015.000
    private static let maxPwdId: UInt8 = 31; // gemSpec_COS#N015.000

    public enum Error: Swift.Error, Equatable {
        case illegalArgument(String)
    }

    public let pwdId: UInt8

    public init(_ value: UInt8) throws {
        guard value <= Password.maxPwdId else {
            throw Error.illegalArgument("Password value is invalid: [\(value)]")
        }
        self.pwdId = value
    }

    public func calculateKeyReference(dfSpecific: Bool) -> UInt8 {
        // gemSpec_COS#N072.800
        if dfSpecific {
            return pwdId + dfSpecificPwdMarker
        }
        return pwdId
    }
}

extension Password: ExpressibleByStringLiteral {
    /// Grapheme for Password is String
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    /// Unicode scalar for Password is String
    public typealias UnicodeScalarLiteralType = String

    /**
        Initialize a Password identifier with a Hex value

        - Parameter value: Hex string with range {1,2}
     */
    public init(stringLiteral value: StringLiteralType) {
        guard !value.isEmpty && value.count < 3, let pwd = UInt8(value, radix: 16) else {
            preconditionFailure("[String Literal] Password value is invalid: [\(value)]")
        }
        do {
            try self.init(pwd)
        } catch let error {
            preconditionFailure("\(error)")
        }
    }

    /**
        Initialize a Password identifier with a Hex value

        - Parameter value: Hex string with range {1,2}
     */
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.init(stringLiteral: value)
    }

    /**
        Initialize a Password identifier with a Hex value

        - Parameter value: Hex string with range {1,2}
     */
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.init(stringLiteral: value)
    }
}
