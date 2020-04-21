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

extension APDU.Response: ResponseType {
    /// The response body
    /// - SeeAlso: `ResponseType.data`
    public var data: Data? {
        let len = self.nr
        guard len > 0 else {
            return nil
        }
        return apdu.subdata(in: 0..<len)
    }

    /// The response body length
    /// - SeeAlso: `ResponseType.nr`
    // swiftlint:disable identifier_name
    public var nr: Int {
        return self.apdu.count - 2
    }

    /// The response status word - upper byte
    /// - SeeAlso: `ResponseType.sw1`
    public var sw1: UInt8 {
        return self.apdu[self.apdu.count - 2] & 0xff
    }

    /// The response status word - lower byte
    /// - SeeAlso: `ResponseType.sw2`
    public var sw2: UInt8 {
        return self.apdu[self.apdu.count - 1] & 0xff
    }

    /// The response status word
    /// - SeeAlso: `ResponseType.sw`
    public var sw: UInt16 {
        let lsw1 = UInt16(self.sw1) << 8
        let lsw2 = UInt16(self.sw2 & 0xff)
        return lsw1 | lsw2
    }
    // swiftlint:enable identifier_name
}
