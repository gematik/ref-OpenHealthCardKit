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
import Security

/// This class provides functionality to derive (de-/ encryption) keys from given data.
public class KeyDerivationFunction {

    /// Type of en-/decryption function
    public enum KeyFuncType {
        /// Target function of family AES128
        case aes128

        var checksumLength: Int {
            switch self {
            case .aes128: return 20
            }
        }

        var length: Int {
            switch self {
            case .aes128: return 16
            }
        }
    }

    /// Mode of use of derived key
    public enum Mode {
        /// Mode key derivation for encoding
        case enc
        /// Mode key derivation for MAC calculation
        case mac
        /// Mode key derivation for password
        case password

        var lastByte: UInt8 {
            switch self {
            case .enc: return 1
            case .mac: return 2
            case .password: return 3
            }
        }
    }

    /// Derives a key from a (shared) secret.
    /// The derived key has the mode of further usage already encoded and is suited to use it in a determined
    /// de-/encryption function.
    ///
    /// - Parameters:
    ///     - from: sharedSecret Data with shared secret value
    ///     - funcType: type of key deriving function, defaults to aes128
    ///     - mode: key derivation for usage modes ENC, MAC or derivation from password
    /// - Returns: The derived Key
    public static func deriveKey(from sharedSecret: Data, funcType: KeyFuncType = .aes128, mode: Mode) -> Data {
        precondition(!sharedSecret.isEmpty, "Secret data to derive a key from must not be empty!")

        // pad according to key deriving function
        let padded = sharedSecret + Data(count: max(0, funcType.checksumLength - funcType.length))
        // replace last bit according to mode of usage of derived key
        let paddedWithMode: Data = padded.dropLast() + [mode.lastByte]

        let hash = paddedWithMode.sha1()
        // pad or truncate result according to key deriving function
        let result = hash.subdata(in: Range(uncheckedBounds: (0, min(hash.count, funcType.length))))
                + Data(count: max(0, funcType.length - funcType.checksumLength))
        return result
    }
}
