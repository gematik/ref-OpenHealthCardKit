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

/// SmartCard Application Protocol Data Unit - Response

public protocol ResponseType {
    /// Returns bytes in the response body. If this APDU has no body, this method returns nil
    var data: Data? { get }

    // swiftlint:disable identifier_name
    /// Returns the number of data bytes in the response body (Nr) or 0 if this APDU has no body.
    /// This call should be equivalent to <code>data.count</code>.
    var nr: Int { get }

    /// Returns the value of the status byte SW1 as a value between 0 and 255.
    var sw1: UInt8 { get }

    /// Returns the value of the status byte SW2 as a value between 0 and 255.
    var sw2: UInt8 { get }

    /// Returns the value of the status bytes SW1 and SW2 as a single status word SW.
    var sw: UInt16 { get }
}

/**
    `ResponseType` adheres to `Equatable`
*/
public func ==(lhs: ResponseType, rhs: ResponseType) -> Bool {
    //swiftlint:disable:previous operator_whitespace
    return lhs.data == rhs.data &&
            lhs.sw == rhs.sw
}
