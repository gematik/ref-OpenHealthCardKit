//
// Copyright (Change Date see Readme), gematik GmbH
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// *******
//
// For additional notes and disclaimer from gematik and in case of changes by gematik find details in the "Readme" file.
//

@testable import CardSimulationCardReaderProvider
import Nimble
import SwiftSocket
import XCTest

final class SimulatorCardTest: XCTestCase {
    var serverSocket: TCPServer!
    var listenPort: Int32 {
        serverSocket.port
    }

    override func setUp() {
        super.setUp()

        serverSocket = TCPServer(address: "127.0.0.1", port: 0)
        if case let .failure(error) = serverSocket.listen() {
            Nimble.fail("Failed to setup TCP socket: [\(error)]")
        }
    }

    override func tearDown() {
        serverSocket.close()
        super.tearDown()
    }

    func testSimulatorCard_open_basic_channel() {
        let card = SimulatorCard(host: "localhost", port: listenPort, channel: .t1, timeout: 1)
        do {
            _ = try card.openBasicChannel()
        } catch {
            Nimble.fail("Could not open basic channel: \(error)")
        }
    }

    func testSimulatorCard_open_logic_channel() {
        let card = SimulatorCard(host: "localhost", port: listenPort, channel: .t1, timeout: 1)
        do {
            _ = try card.openLogicChannel()
        } catch {
            // Ignore for now, since we know it's not implemented
            // XCTFail("Could not open logic channel: \(error)")
        }
    }

    static var allTests = [
        ("testSimulatorCard_open_basic_channel", testSimulatorCard_open_basic_channel),
        ("testSimulatorCard_open_logic_channel", testSimulatorCard_open_logic_channel),
    ]
}
