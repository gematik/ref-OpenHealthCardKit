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

import CardReaderProviderApi
import Foundation
import GemCommonsKit
import OSLog
import SwiftSocket

protocol TCPClientType: InputStreaming, OutputStreaming {
    func close() throws
}

public class SimulatorCardChannel: CardChannelType {
    public enum SimulatorError: Swift.Error, Equatable {
        case outputStreamUnavailable
        case noResponse
        case invalidResponse
        case asn1coding(Swift.Error)
        case commandSizeTooLarge(maxSize: Int, length: Int)
        case responseSizeTooLarge(maxSize: Int, length: Int)

        public var connectionError: CardError {
            CardError.connectionError(self)
        }

        public var illegalState: CardError {
            CardError.illegalState(self)
        }

        // swiftlint:disable:next operator_whitespace
        public static func ==(lhs: SimulatorError, rhs: SimulatorError) -> Bool {
            switch (lhs, rhs) {
            case (.outputStreamUnavailable, .outputStreamUnavailable): return true
            case (.noResponse, .noResponse): return true
            case (.asn1coding, .asn1coding): return true
            case let (.commandSizeTooLarge(lhsMax, lhsSize), .commandSizeTooLarge(rhsMax, rhsSize)):
                return lhsMax == rhsMax && lhsSize == rhsSize
            case let (.responseSizeTooLarge(lhsMax, lhsSize), .responseSizeTooLarge(rhsMax, rhsSize)):
                return lhsMax == rhsMax && lhsSize == rhsSize
            default:
                return false
            }
        }
    }

    public private(set) var card: CardType
    public private(set) var channelNumber: Int = 0
    public private(set) var extendedLengthSupported: Bool
    public private(set) var maxMessageLength: Int
    public private(set) var maxResponseLength: Int
    let tcpClient: TCPClientType
    var inputStream: InputStreaming {
        tcpClient
    }

    var outputStream: OutputStreaming {
        tcpClient
    }

    init(card: CardType,
         client: TCPClientType,
         messageLength: Int,
         responseLength: Int,
         extendedLengthSupport: Bool = true) {
        self.card = card
        tcpClient = client
        maxMessageLength = messageLength
        maxResponseLength = responseLength
        extendedLengthSupported = extendedLengthSupport
    }

    /// Transmit a command and return the response
    /// - Parameters:
    ///     - command: the command gets berTlv encoded and send to the Kartensimulation
    /// - throws:
    ///     - SimulatorError.outputStreamUnavailable.illegalState when the stream has no space available to write
    /// - Returns: the berTlv decoded response APDU
    public func transmit(command: CommandType, writeTimeout _: TimeInterval, readTimeout: TimeInterval) throws
        -> ResponseType {
        guard outputStream.hasSpaceAvailable else {
            throw SimulatorError.outputStreamUnavailable.illegalState
        }
        guard command.bytes.count <= maxMessageLength else {
            throw SimulatorError.commandSizeTooLarge(maxSize: maxMessageLength, length: command.bytes.count)
                .illegalState
        }
        let message = try command.bytes.berTlvEncoded()
        Logger.cardSimulationCardReaderProvider
            .debug("SEND:     \(message.map { String(format: "%02hhX", $0) }.joined())")
        _ = message.withUnsafeBytes {
            outputStream.write($0, maxLength: message.count)
        }

        var buffer = [UInt8](repeating: 0x0, count: maxResponseLength)
        var responseData = Data()
        let timeoutTime = (readTimeout == 0) ? Date.distantFuture : Date(timeIntervalSinceNow: readTimeout)
        repeat {
            guard inputStream.hasBytesAvailable else {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
                continue
            }
            let readBytes = inputStream.read(&buffer, maxLength: maxResponseLength)
            guard readBytes != -1 else {
                throw SimulatorError.noResponse.connectionError
            }
            buffer.withContiguousStorageIfAvailable { bytes in
                // swiftlint:disable:next force_unwrapping
                responseData.append(bytes.baseAddress!, count: readBytes)
            }
        } while inputStream.hasBytesAvailable || (responseData.isEmpty && Date() < timeoutTime)

        guard !responseData.isEmpty else {
            Logger.cardSimulationCardReaderProvider
                .warning(
                    // swiftlint:disable:next line_length
                    "Error when reading the response from the CardSimulator connection or there were no bytes available to be read."
                )
            throw SimulatorError.noResponse.connectionError
        }

        Logger.cardSimulationCardReaderProvider
            .debug("RESPONSE: \(responseData.map { String(format: "%02hhX", $0) }.joined())") // hexString
        let extractedResponseData = try responseData.berTlvDecoded()
        guard extractedResponseData.count <= maxResponseLength else {
            throw SimulatorError.responseSizeTooLarge(maxSize: maxResponseLength, length: responseData.count)
                .illegalState
        }

        return try APDU.Response(apdu: extractedResponseData)
    }

    public func transmitAsync(
        command: CardReaderProviderApi.CommandType,
        writeTimeout _: TimeInterval,
        readTimeout: TimeInterval
    ) async throws -> CardReaderProviderApi.ResponseType {
        guard outputStream.hasSpaceAvailable else {
            throw SimulatorError.outputStreamUnavailable.illegalState
        }
        guard command.bytes.count <= maxMessageLength else {
            throw SimulatorError.commandSizeTooLarge(maxSize: maxMessageLength, length: command.bytes.count)
                .illegalState
        }
        let message = try command.bytes.berTlvEncoded()
        Logger.cardSimulationCardReaderProvider
            .debug("SEND:     \(message.map { String(format: "%02hhX", $0) }.joined())") // hexString
        _ = message.withUnsafeBytes {
            outputStream.write($0, maxLength: message.count)
        }

        var buffer = [UInt8](repeating: 0x0, count: maxResponseLength)
        var responseData = Data()
        let timeoutTime = (readTimeout == 0) ? Date.distantFuture : Date(timeIntervalSinceNow: readTimeout)
        repeat {
            guard inputStream.hasBytesAvailable else {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
                continue
            }
            let readBytes = inputStream.read(&buffer, maxLength: maxResponseLength)
            guard readBytes != -1 else {
                throw SimulatorError.noResponse.connectionError
            }
            buffer.withContiguousStorageIfAvailable { bytes in
                // swiftlint:disable:next force_unwrapping
                responseData.append(bytes.baseAddress!, count: readBytes)
            }
        } while inputStream.hasBytesAvailable || (responseData.isEmpty && Date() < timeoutTime)

        guard !responseData.isEmpty else {
            Logger.cardSimulationCardReaderProvider
                .warning(
                    // swiftlint:disable:next line_length
                    "Error when reading the response from the CardSimulator connection or there were no bytes available to be read."
                )
            throw SimulatorError.noResponse.connectionError
        }

        Logger.cardSimulationCardReaderProvider
            .debug("RESPONSE: \(responseData.map { String(format: "%02hhX", $0) }.joined())") // hexString
        let extractedResponseData = try responseData.berTlvDecoded()
        guard extractedResponseData.count <= maxResponseLength else {
            throw SimulatorError.responseSizeTooLarge(maxSize: maxResponseLength, length: responseData.count)
                .illegalState
        }

        return try APDU.Response(apdu: extractedResponseData)
    }

    public func close() throws {
        try tcpClient.close()
    }

    public func closeAsync() async throws {
        try tcpClient.close()
    }
}
