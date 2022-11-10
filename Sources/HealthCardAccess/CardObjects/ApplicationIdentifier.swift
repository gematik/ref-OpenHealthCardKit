//
//  Copyright (c) 2022 gematik GmbH
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
import GemCommonsKit

/// ApplicationIdentifier representation to prevent (accidental) misuse
/// E.g. using any 'random' String as function parameter where a AID is expected
/// - Note: see also gemSpec_COS#N010.200
public struct ApplicationIdentifier: CardObjectIdentifierType {
    public enum Error: Swift.Error, Equatable {
        case illegalArgument(String)
        case invalidLength(length: Int)
    }

    private static let AidMinLength = 5
    private static let AidMaxLength = 16

    /// The actual value representation for the ApplicationIdentifier
    public let rawValue: Data

    public init(_ data: Data) throws {
        rawValue = try type(of: self).isValid(data).get()
    }

    public init(hex text: String) throws {
        guard let data = try? Data(hex: text) else {
            throw Error.illegalArgument(
                "Application File Identifier is invalid (non-hex characters found). [\(text)]"
            )
        }
        try self.init(data)
    }

    /**
        Sanity check for application file identifier

        - Parameters:
            - value: the byte buffer that should make up the AID
        - Returns: Result success with true when the value could represent a AID
     */
    public static func isValid(_ value: Data) -> Result<Data, Swift.Error> {
        if value.count < AidMinLength || value.count > AidMaxLength {
            return .failure(Error.invalidLength(length: value.count))
        }
        return .success(value)
    }
}

extension ApplicationIdentifier: CustomDebugStringConvertible, CustomStringConvertible {
    public var debugDescription: String {
        "[0x\(rawValue.hexString())]"
    }

    public var description: String {
        debugDescription
    }
}

extension ApplicationIdentifier {
    /// Grapheme for AID is String
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    /// Unicode scalar for AID is String
    public typealias UnicodeScalarLiteralType = String

    /**
         Initialize ApplicationIdentifier from UnicodeScalar

         - Parameter value: The scalar to be used as rawValue
     */
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.init(stringLiteral: value)
    }

    /**
         Initialize ApplicationIdentifier from ExtendedGraphemeCluster

         - Parameter value: The grapheme to be used as rawValue
     */
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.init(stringLiteral: value)
    }

    /**
         Initialize ApplicationIdentifier from String

         - Parameter value: The StringLiteral to be used as rawValue
     */
    public init(stringLiteral value: StringLiteralType) {
        do {
            try self.init(hex: value)
        } catch {
            preconditionFailure(error.localizedDescription)
        }
    }
}
