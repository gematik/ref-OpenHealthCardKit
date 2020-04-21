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

/// Channel Access Number
public struct CAN {
    public enum InvalidCAN: Swift.Error, Equatable {
        case illegalValue(Int, for: String, expected: Range<Int>)
    }

    /// CAN Number
    public let rawValue: Data

    private init(_ data: Data) {
        self.rawValue = data
    }

    /// Create and validate a CAN from Data
    /// - Parameter data: the CAN value. Must be [1, 16] bytes long
    /// - Throws: InvalidCAN.illegalValue when data is not valid
    /// - Returns: CAN
    public static func from(_ data: Data) throws -> CAN {
        let range = 1..<17
        guard range ~= data.count else {
            throw InvalidCAN.illegalValue(data.count, for: "CAN", expected: range)
        }

        return CAN(data)
    }
}
