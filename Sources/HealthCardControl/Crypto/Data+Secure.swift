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

import CommonCrypto
import Foundation

/**
    Data extension Data+Secure
*/
extension Data {
    /// The 128-bit Secure Hash (SHA1) of Data block `self`
    /// - Returns: SHA1 hash
    func sha1() -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        self.withUnsafeBytes { bytes in
            _ = CC_SHA1(bytes.baseAddress!, CC_LONG(self.count), &hash) //swiftlint:disable:this force_unwrapping
        }
        return Data(hash)
    }
}
