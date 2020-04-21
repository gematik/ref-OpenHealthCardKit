// swiftlint:disable:this file_name
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

extension APDU.Command: CommandType {
    /// APDU body data
    public var data: Data? {
        let subData = self.apdu.subdata(in: self.dataOffset..<self.rawNc + self.dataOffset)
        return subData.isEmpty ? nil : subData
    }

    /// APDU class identifier
    public var cla: UInt8 {
        return self.apdu[0] & 0xff
    }

    /// APDU Instruction
    public var ins: UInt8 {
        return self.apdu[1] & 0xff
    }

    // swiftlint:disable identifier_name

    /// APDU P1
    public var p1: UInt8 {
        return self.apdu[2] & 0xff
    }

    /// APDU P2
    public var p2: UInt8 {
        return self.apdu[3] & 0xff
    }

    /// APDU Le - Expected length in response body
    public var ne: Int? {
        return self.rawNe
    }

    /// APDU Lc - Command body length
    public var nc: Int {
        return self.rawNc
    }

    /// APDU raw
    public var bytes: Data {
        return self.apdu
    }
    // swiftlint:enable identifier_name
}
