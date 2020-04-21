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
import GemCommonsKit

/// Short File Identifier - gemSpec_COS#N007.000
public struct ShortFileIdentifier: CardObjectIdentifierType {

    private static let sfidMin = 1
    private static let sfidMax = 30 // inclusive

    public enum Error: Swift.Error, Equatable {
        case illegalArgument(String)
    }

    /// The actual value representation for the ShortFileIdentifier
    public let rawValue: Data

    public static func isValid(_ value: Data) -> Result<Data, Swift.Error> {
        guard value.count == 1 else {
            return .failure(Error.illegalArgument("Short File Identifier is invalid: [0x\(value.hexString())]"))
        }
        return isValid(value[0])
    }

    public static func isValid(_ value: UInt8) -> Result<Data, Swift.Error> {
        guard value >= sfidMin && value <= sfidMax else {
            return .failure(Error.illegalArgument(
                "Short File Identifier is invalid: [0x\(String(format: "%02hhX", value))]"
            ))
        }
        return Result.success(value).map { (sfid: UInt8) -> Data in
            Data([sfid])
        }
    }

    /// Init the Short File Identifier from ASN.1 formatted primitive
    public init(asn1 data: Data) throws {
        guard data.count == 1 else {
            throw Error.illegalArgument("Parsing [ASN.1] Short File Identifier is invalid: [0x\(data.hexString())]")
        }
        try self.init(data[0] >> 3)
    }

    public init(hex text: String) throws {
        guard let data = try? Data(hex: text), data.count == 1 else {
            throw Error.illegalArgument(
                "Short File Identifier is invalid (non-hex characters found). [\(text)]"
            )
        }
        try self.init(data[0])
    }

    public init(_ value: UInt8) throws {
        rawValue = try type(of: self).isValid(value).get()
    }
}

extension ShortFileIdentifier: CustomDebugStringConvertible, CustomStringConvertible {
    public var debugDescription: String {
        return "[0x\(rawValue.hexString())]"
    }

    public var description: String {
        return debugDescription
    }
}

extension ShortFileIdentifier {
    /// Grapheme for SFID is String
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    /// Unicode scalar for SFID is String
    public typealias UnicodeScalarLiteralType = String

    /**
        Initialize ShortFileIdentifier from String

        - Parameter value: String value in the range of 01...1E
     */
    public init(stringLiteral value: StringLiteralType) {
        try! self.init(hex: value) //swiftlint:disable:this force_try
    }

    /**
        Initialize ShortFileIdentifier from String

        - Parameter value: String value in the range of 01...1E
     */
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.init(stringLiteral: value)
    }

    /**
        Initialize ShortFileIdentifier from String

        - Parameter value: String value in the range of 01...1E
     */
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.init(stringLiteral: value)
    }
}
