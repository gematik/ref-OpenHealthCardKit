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
@testable import CardSimulationCardReaderProvider
import Foundation
import Nimble
import XCTest

final class SimulatorCardChannelTest: XCTestCase {
    class MockSimulatorCard: CardType {
        var atr: ATR = Data.empty
        var `protocol`: CardProtocol = .t1

        func openBasicChannel() throws -> CardChannelType {
            throw CardError.illegalState("openBasicChannel() has not been implemented")
        }

        func openLogicChannel() throws -> CardChannelType {
            throw CardError.illegalState("openLogicChannel() has not been implemented")
        }

        func openLogicChannelAsync() async throws -> CardChannelType {
            throw CardError.illegalState("openLogicChannel() has not been implemented")
        }

        func disconnect(reset _: Bool) throws {}

        var description: String {
            "MockSimulatorCard"
        }
    }

    class MockStreaming: TCPClientType {
        var closedInputStream = false
        var closedOutputStream = false

        var bytesWritten = Data()
        /// When bytes have written, unlock responses
        var availableBytes: Data?

        var hasBytesAvailable: Bool {
            let writtenCount = bytesWritten.count
            guard !closedInputStream,
                  writtenCount > 0,
                  (availableBytes?.count ?? 0) > 0 else {
                return false
            }
            return true
        }

        func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
            guard hasBytesAvailable, let bytes = availableBytes else {
                return 0
            }
            let count = Swift.min(bytes.count, len)

            bytes.withUnsafeBytes {
                buffer.assign(from: $0, count: count)
            }
            availableBytes?.removeFirst(count)
            return count
        }

        var hasSpaceAvailable: Bool {
            !closedOutputStream
        }

        func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
            let data = Data(bytes: buffer, count: len)
            bytesWritten.append(data)
            return data.count
        }

        func close() throws {
            closedInputStream = true
            closedOutputStream = true
        }
    }

    struct MockCommand: CommandType {
        private(set) var data: Data?
        // swiftlint:disable identifier_name
        private(set) var ne: Int?
        private(set) var nc: Int = 0
        private(set) var cla: UInt8 = 0
        private(set) var ins: UInt8 = 0
        private(set) var p1: UInt8 = 0
        private(set) var p2: UInt8 = 0
        // swiftlint:enable identifier_name
        private(set) var bytes: Data

        init(bytes: Data) {
            self.bytes = bytes
        }
    }

    func testTransmit() {
        let stream = MockStreaming()
        guard let responseData = try? Data([0x90, 0x00]).berTlvEncoded() else {
            Nimble.fail("Failed to berTlv Encode responseData")
            return
        }
        stream.availableBytes = responseData
        let cardChannel = SimulatorCardChannel(
            card: MockSimulatorCard(),
            client: stream,
            messageLength: 4096,
            responseLength: 4096
        )
        let commandData = Data([0x1, 0x2, 0x3, 0x4])
        let command: CommandType = MockCommand(bytes: commandData)
        do {
            let response = try cardChannel.transmit(command: command, writeTimeout: 0, readTimeout: 0)
            // Verify response has been decoded
            expect(response.sw).to(equal(APDU.Response.OK.sw))
            // Verify command has been ber TLV encoded and written to output stream
            let berTlvData = try commandData.berTlvEncoded()
            expect(berTlvData).to(equal(stream.bytesWritten))
            // Close channel
            try cardChannel.close()
            expect(stream.closedInputStream).to(beTrue())
            expect(stream.closedOutputStream).to(beTrue())
        } catch {
            Nimble.fail("Transmit failed: [\(error)]")
        }
    }

    func testCommandTooLarge() {
        let stream = MockStreaming()
        let cardChannel = SimulatorCardChannel(
            card: MockSimulatorCard(),
            client: stream,
            messageLength: 10,
            responseLength: 10
        )
        let commandData = Data([UInt8](repeating: 0x8, count: 11))
        let command: CommandType = MockCommand(bytes: commandData)
        expect {
            try cardChannel.transmit(command: command, writeTimeout: 0, readTimeout: 0)
        }.to(throwError(SimulatorCardChannel.SimulatorError.commandSizeTooLarge(maxSize: 10, length: 11).illegalState))
    }

    func testResponseTooLarge() {
        let stream = MockStreaming()
        guard let responseData = try? Data([UInt8](repeating: 0x8, count: 11)).berTlvEncoded() else {
            Nimble.fail("Failed to berTlv Encode responseData")
            return
        }
        stream.availableBytes = responseData

        let cardChannel = SimulatorCardChannel(
            card: MockSimulatorCard(),
            client: stream,
            messageLength: 10,
            responseLength: 10
        )
        let commandData = Data([0x0, 0x2])
        let command: CommandType = MockCommand(bytes: commandData)
        expect {
            try cardChannel.transmit(command: command, writeTimeout: 0, readTimeout: 0)
        }.to(throwError(
            SimulatorCardChannel.SimulatorError.responseSizeTooLarge(maxSize: 10, length: responseData.count)
                .illegalState
        ))
    }

    func testNoResponse() {
        let stream = MockStreaming()
        let cardChannel = SimulatorCardChannel(
            card: MockSimulatorCard(),
            client: stream,
            messageLength: 10,
            responseLength: 10
        )

        let commandData = Data([0x0, 0x2])
        let command: CommandType = MockCommand(bytes: commandData)
        expect {
            try cardChannel.transmit(command: command, writeTimeout: 0, readTimeout: 0.5)
        }.to(throwError(SimulatorCardChannel.SimulatorError.noResponse.connectionError))
    }

    func testEmptyResponse() {
        let stream = MockStreaming()
        let cardChannel = SimulatorCardChannel(
            card: MockSimulatorCard(),
            client: stream,
            messageLength: 10,
            responseLength: 10
        )
        stream.availableBytes = Data()

        let commandData = Data([0x0, 0x2])
        let command: CommandType = MockCommand(bytes: commandData)
        expect {
            try cardChannel.transmit(command: command, writeTimeout: 0, readTimeout: 0.5)
        }.to(throwError(SimulatorCardChannel.SimulatorError.noResponse.connectionError))
    }

    static let allTests = [
        ("testTransmit", testTransmit),
        ("testCommandTooLarge", testCommandTooLarge),
        ("testResponseTooLarge", testResponseTooLarge),
        ("testNoResponse", testNoResponse),
        ("testEmptyResponse", testEmptyResponse),
    ]
}
