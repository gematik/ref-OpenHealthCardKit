//
//  Copyright (c) 2023 gematik GmbH
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
import SwiftSocket
import OSLog

extension TCPClient: TCPClientType {
    var hasBytesAvailable: Bool {
        guard let availableBytes = bytesAvailable() else {
            return false
        }
        return availableBytes > 0
    }

    func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        guard let availableBytes = bytesAvailable() else {
            return 0
        }

        let bufferSize = min(Int(availableBytes), len)
        guard let bytes = read(bufferSize) else {
            Logger.cardSimulationCardReaderProvider.fault("Read error")
            return -1
        }
        buffer.assign(from: bytes, count: bytes.count)
        return bytes.count
    }

    var hasSpaceAvailable: Bool {
        fd != nil
    }

    func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        let data = Data(bytes: buffer, count: len)
        switch send(data: data) {
        case .failure: return -1
        case .success: return data.count
        }
    }
}
