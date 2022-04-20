//
//  Copyright (c) 2022 gematik GmbH
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

import CommonCrypto
import Foundation
import OpenSSL

/// Helper class providing AES functions for handling PACE key exchange
/// to establish a trusted channel between a card and the phone
enum AES {
    case CBC128

    func decrypt(data: Data, key: Data, initVector: Data = Data(repeating: 0x0, count: 16)) throws -> Data {
        var numOfBytesDecrypted: Int = 0
        let bufferSize = data.count
        var buffer = Data(count: bufferSize)

        let status = withUnsafePointers(key, data, initVector, &buffer) { keyPtr, bytes, initVector, outPtr in
            CCCrypt(
                CCOperation(kCCDecrypt),
                CCAlgorithm(kCCAlgorithmAES128),
                0,
                keyPtr,
                kCCKeySizeAES128,
                initVector,
                bytes,
                data.count,
                outPtr,
                bufferSize,
                &numOfBytesDecrypted
            )
        }
        guard status == 0 else {
            throw CipherError.aesDecryptionFailed(status: status)
        }
        return Data(buffer[0 ..< numOfBytesDecrypted])
    }

    func encrypt(data: Data, key: Data, initVector: Data = Data(repeating: 0x0, count: 16)) throws -> Data {
        var numBytesEncrypted: Int = 0
        let bufferSize = data.count
        var buffer = Data(count: bufferSize)

        let status = withUnsafePointers(key, data, initVector, &buffer) { keyPtr, bytes, initVector, outPtr in
            CCCrypt(
                CCOperation(kCCEncrypt),
                CCAlgorithm(kCCAlgorithmAES128),
                0,
                keyPtr,
                kCCKeySizeAES128,
                initVector,
                bytes,
                data.count,
                outPtr,
                bufferSize,
                &numBytesEncrypted
            )
        }
        guard status == 0 else {
            throw CipherError.aesEncryptionFailed(status: status)
        }
        return Data(buffer[0 ..< numBytesEncrypted])
    }

    static func CMAC(key: Data, data: Data) throws -> Data {
        try OpenSSL.CMAC.aes128cbc(key: key, data: data)
    }
}

@inline(__always)
private func withUnsafePointers<R>(
    _ arg0: Data,
    _ arg1: Data,
    _ arg2: inout Data,
    _ body: (
        UnsafeRawPointer,
        UnsafeRawPointer,
        UnsafeMutableRawPointer
    ) throws -> R
) rethrows -> R {
    try arg0.withUnsafeBytes { param0 in
        try arg1.withUnsafeBytes { param1 in
            try arg2.withUnsafeMutableBytes { param2 in
                // swiftlint:disable:next force_unwrapping
                try body(param0.baseAddress!, param1.baseAddress!, param2.baseAddress!)
            }
        }
    }
}

@inline(__always)
private func withUnsafePointers<R>(
    _ arg0: Data,
    _ arg1: Data,
    _ arg2: Data,
    _ arg3: inout Data,
    _ body: (
        UnsafeRawPointer,
        UnsafeRawPointer,
        UnsafeRawPointer,
        UnsafeMutableRawPointer
    ) throws -> R
) rethrows -> R {
    try arg0.withUnsafeBytes { param0 in
        try arg1.withUnsafeBytes { param1 in
            try arg2.withUnsafeBytes { param2 in
                try arg3.withUnsafeMutableBytes { param3 in
                    // swiftlint:disable:next force_unwrapping
                    try body(param0.baseAddress!, param1.baseAddress!, param2.baseAddress!, param3.baseAddress!)
                }
            }
        }
    }
}

extension AES {
    enum CipherError: Swift.Error {
        case aesDecryptionFailed(status: Int32) // CCCryptorStatus
        case aesEncryptionFailed(status: Int32) // CCCryptorStatus
        case cmacAuthenticationFailed
    }
}
