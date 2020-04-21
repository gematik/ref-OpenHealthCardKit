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

public struct Key: CardItemType, CardKeyReferenceType {
    public enum Error: Swift.Error, Equatable {
        case illegalArgument(String)
    }

    private static let minKeyId = 2
    private static let maxKeyId = 28

    public let keyId: UInt8

    public init(_ key: UInt8) throws {
        guard key >= Key.minKeyId && key <= Key.maxKeyId else {
            // gemSpec_COS#N016.400 and #N017.100
            throw Error.illegalArgument("Password ID: [\(key)] out of range [\(Key.minKeyId),\(Key.maxKeyId)]")
        }
        keyId = key
    }

    public func calculateKeyReference(dfSpecific: Bool) -> UInt8 {
        // gemSpec_COS#N099.600
        if dfSpecific {
            return keyId + dfSpecificPwdMarker
        }
        return keyId
    }
}
