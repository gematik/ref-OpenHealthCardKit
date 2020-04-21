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

/// SmartCard Application Protocol Data Unit - Command

public protocol CommandType {
    /// Returns bytes in the command body. If this APDU has no body, this property should return nil
    var data: Data? { get }

    // swiftlint:disable identifier_name

    /// Returns the maximum number of expected data bytes in a response APDU (Ne/Le).
    /// 0 = unlimited/unknown, nil = no output expected
    var ne: Int? { get }

    /// Returns the number of data bytes in the command body (Nc) or 0 if this APDU has no body.
    /// This call should be equivalent to `self.data.count`.
    var nc: Int { get }

    /// Returns the value of the class byte CLA.
    var cla: UInt8 { get }

    /// Returns the value of the instruction byte INS.
    var ins: UInt8 { get }

    /// Returns the value of the parameter byte P1.
    var p1: UInt8 { get }

    /// Returns the value of the parameter byte P2.
    var p2: UInt8 { get }

    // swiftlint:enable identifier_name

    /// Serialized APDU message
    var bytes: Data { get }
}

/**
    `CommandType` adheres to `Equatable`
*/
public func ==(lhs: CommandType, rhs: CommandType) -> Bool {
    //swiftlint:disable:previous operator_whitespace
    return lhs.bytes == rhs.bytes
}
