//
//  Copyright (c) 2021 gematik GmbH
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

import Foundation

extension Data {
    /// Truncates or pads with  the Data object from the left until the given sized is reached.
    /// - Parameters:
    ///     - targetByteCount: Length to which the Data is truncated or padded with zero-bytes. Must be greater or
    ///                             equal to zero.
    ///     - paddingIndicator: Byte to pad the given Data, if the length not sufficient
    /// - Precondition: targetByteCount must be greater than or equal to 0
    /// - Returns: The Data with the given size
    public func normalize(to targetByteCount: Int, paddingIndicator: UInt8 = 0x0) -> Data {
        precondition(targetByteCount >= 0, "TargetByteCount to normalize a data array must not be negative.")

        let exceedingByteCount = Swift.max(targetByteCount - count, 0)
        return Data(repeating: paddingIndicator, count: exceedingByteCount) + suffix(targetByteCount)
    }
}
