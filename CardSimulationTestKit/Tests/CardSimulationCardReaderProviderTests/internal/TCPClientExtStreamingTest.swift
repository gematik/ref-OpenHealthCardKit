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

@testable import CardSimulationCardReaderProvider
import Nimble
import SwiftSocket
import XCTest

final class TCPClientExtStreamingTest: XCTestCase {
    var serverSocket: TCPServer!
    var listenPort: Int32 {
        serverSocket.port
    }

    var client: TCPClient!

    override func setUp() {
        super.setUp()

        serverSocket = TCPServer(address: "127.0.0.1", port: 0)
        if case let .failure(error) = serverSocket.listen() {
            Nimble.fail("Failed to setup TCP socket: [\(error)]")
        }
        client = TCPClient(address: "localhost", port: listenPort)
    }

    override func tearDown() {
        serverSocket.close()
        client.close()
        super.tearDown()
    }

    func testTCPClient_input_streaming() {
        if case let .failure(error) = client.connect(timeout: 1) {
            Nimble.fail("Could not connect client socket: \(error)")
        }
        guard let server = serverSocket.accept() else {
            Nimble.fail("Server could not accept")
            return
        }
        let inputStream = client as InputStreaming
        expect(inputStream.hasBytesAvailable).to(beFalse())

        let message = Data([0x1, 0x2, 0x3, 0x4])
        _ = server.send(data: message)

        expect(inputStream.hasBytesAvailable).toEventually(beTrue())
        var receivedMessage = [UInt8](repeating: 0x0, count: 100)
        let readBytes = inputStream.read(&receivedMessage, maxLength: receivedMessage.count)

        expect(readBytes).to(equal(4))
        expect(inputStream.hasBytesAvailable).to(beFalse())
        expect(Data(Array(receivedMessage[0 ..< readBytes]))).to(equal(message))
    }

    func testTCPClient_output_streaming() {
        if case let .failure(error) = client.connect(timeout: 1) {
            Nimble.fail("Could not connect client socket: \(error)")
        }
        let outputStream = client as OutputStreaming

        guard let server = serverSocket.accept(timeout: 1) else {
            Nimble.fail("Server could not accept")
            return
        }
        expect(outputStream.hasSpaceAvailable).to(beTrue())

        let message = Data([0x8, 0x7, 0x6, 0x5, 0x4, 0x3, 0x2, 0x1])
        let bytesWritten = message.withUnsafeBytes { bytes in
            outputStream.write(bytes, maxLength: message.count)
        }
        expect(bytesWritten).to(equal(message.count))
        let serverRead = Data(server.read(message.count, timeout: 1)!) // swiftlint:disable:this force_unwrapping
        expect(serverRead).to(equal(message))
        expect(outputStream.hasSpaceAvailable).to(beTrue())

        server.close()
    }

    static var allTests = [
        ("testTCPClient_input_streaming", testTCPClient_input_streaming),
        ("testTCPClient_output_streaming", testTCPClient_output_streaming),
    ]
}
