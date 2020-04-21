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

/// File Identifier - gemSpec_COS 8.1.1 #N006.700, N006.900
public struct FileIdentifier: CardObjectIdentifierType {
    /// FileIdentifier initialization error type
    public enum Error: Swift.Error, Equatable {
        /// When the File Identifier value is not according to the gemSpec_COS#N006.700, N006.900
        case illegalArgument(String)
        /// When the File Identifier argument is not 2-bytes long
        case invalidLength(length: Int)
    }

    /// The actual value representation for the FileIdentifier
    public let rawValue: Data

    public init(_ data: Data) throws {
        rawValue = try type(of: self).isValid(data).get()
    }

    public init(hex text: String) throws {
        guard let data = try? Data(hex: text) else {
            throw Error.illegalArgument(
                    "File Identifier is invalid (non-hex characters found). [\(text)]"
            )
        }
        try self.init(data)
    }

    /**
        Sanity check for file identifier

        - SeeAlso: gemSpec_COS 8.1.1 (#N006.700, N006.900)

        - Parameters:
            - value: the byte buffer that should make up the FID
        - Returns: Result success with true when the value could represent a FID
     */
    public static func isValid(_ value: Data) -> Result<Data, Swift.Error> {
        guard value.count == 2 else {
            return .failure(Error.invalidLength(length: value.count))
        }

        let fid: UInt16 = value.withUnsafeBytes { bytes in
            //swiftlint:disable:next force_unwrapping
            bytes.baseAddress!.assumingMemoryBound(to: UInt16.self).pointee.bigEndian
        }

        guard (fid >= 0x1000 && fid <= 0xfeff && fid != 0x3fff) || fid == 0x011c else {
            return .failure(Error.illegalArgument("File Identifier invalid: [0x\(value.hexString())]"))
        }
        return .success(value)
    }

}

extension FileIdentifier: CustomDebugStringConvertible, CustomStringConvertible {
    public var debugDescription: String {
        return "[0x\(rawValue.hexString())]"
    }

    public var description: String {
        return debugDescription
    }
}

extension FileIdentifier {
    /// Grapheme for AID is String
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    /// Unicode scalar for AID is String
    public typealias UnicodeScalarLiteralType = String

    /**
        Initialize FileIdentifier from String

        - Parameter value: String value in the range of 0100...feff
     */
    public init(stringLiteral value: StringLiteralType) {
        try! self.init(hex: value) //swiftlint:disable:this force_try
    }

    /**
        Initialize FileIdentifier from String

        - Parameter value: String value in the range of 0100...feff
     */
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.init(stringLiteral: value)
    }

    /**
        Initialize FileIdentifier from String

        - Parameter value: String value in the range of 0100...feff
     */
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.init(stringLiteral: value)
    }
}
