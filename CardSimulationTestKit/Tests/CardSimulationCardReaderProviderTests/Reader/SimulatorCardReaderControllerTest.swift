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

import CardReaderProviderApi
@testable import CardSimulationCardReaderProvider
import Nimble
import XCTest

final class SimulatorCardReaderControllerTest: XCTestCase {
    typealias ControllerDelegateParams = (controller: CardReaderControllerType, cardReader: CardReaderType)

    class TestCardReaderControllerDelegate: CardReaderControllerDelegate {
        var connectCalls = [ControllerDelegateParams]()
        var disconnectCalls = [ControllerDelegateParams]()

        func cardReader(controller: CardReaderControllerType, didConnect cardReader: CardReaderType) {
            connectCalls.append((controller: controller, cardReader: cardReader))
        }

        func cardReader(controller: CardReaderControllerType, didDisconnect cardReader: CardReaderType) {
            disconnectCalls.append((controller: controller, cardReader: cardReader))
        }
    }

    func testCardReaderController_registers_as_delegate() {
        let mockManager = MockSimulationManager()
        var controller = SimulatorCardReaderController(manager: mockManager)

        /// make sure SimulatorCardTerminalController registers
        expect(mockManager.delegates.array).to(containElementSatisfying({ $0 === controller }, ""))

        controller = SimulatorCardReaderController(manager: MockSimulationManager())
        /// make sure SimulatorCardTerminalController de-registers
        expect(mockManager.delegates.count).to(equal(0))
    }

    func testCardReaderController_weak_delegate() {
        let mockManager = MockSimulationManager()
        let mockRunner = MockSimulationRunner()
        let controller = SimulatorCardReaderController(manager: mockManager)

        expect(mockManager.delegates.array).to(containElementSatisfying({ $0 === controller }, ""))

        var delegate = TestCardReaderControllerDelegate()
        weak var weakDelegate = delegate

        controller.add(delegate: delegate)
        controller.simulation(manager: mockManager, didStart: mockRunner)
        // Make sure delegate was registered
        expect(delegate.connectCalls.count).to(equal(1))

        delegate = TestCardReaderControllerDelegate()
        expect(weakDelegate).to(beNil())
    }

    func testCardReaderController_registered_delegate_callbacks() {
        let mockManager = MockSimulationManager()
        let mockRunner = MockSimulationRunner()
        let controller = SimulatorCardReaderController(manager: mockManager)

        expect(mockManager.delegates.array).to(containElementSatisfying({ $0 === controller }, ""))

        let delegate = TestCardReaderControllerDelegate()
        controller.add(delegate: delegate)
        expect(delegate.connectCalls.count).to(equal(0))
        expect(delegate.disconnectCalls.count).to(equal(0))
        expect(controller.cardReaders).to(beEmpty())
        controller.simulation(manager: mockManager, didStart: mockRunner)
        expect(controller.cardReaders).to(haveCount(1))
        // Make sure delegate was registered
        expect(delegate.connectCalls.count).to(equal(1))
        expect(delegate.disconnectCalls.count).to(equal(0))

        controller.simulation(manager: mockManager, didEnd: mockRunner)
        expect(controller.cardReaders).to(beEmpty())
        expect(delegate.connectCalls.count).to(equal(1))
        expect(delegate.disconnectCalls.count).to(equal(1))

        controller.remove(delegate: delegate)
        controller.simulation(manager: mockManager, didStart: mockRunner)
        expect(delegate.connectCalls.count).to(equal(1))
        expect(delegate.disconnectCalls.count).to(equal(1))

        /// Late delegate should still get the current available runner
        let lateDelegate = TestCardReaderControllerDelegate()
        controller.add(delegate: lateDelegate)
        expect(lateDelegate.connectCalls.count).to(equal(1))
        expect(lateDelegate.disconnectCalls.count).to(equal(0))
    }

    static var allTests = [
        ("testCardReaderController_registers_as_delegate", testCardReaderController_registers_as_delegate),
        ("testCardReaderController_weak_delegate", testCardReaderController_weak_delegate),
        ("testCardReaderController_registered_delegate_callbacks",
         testCardReaderController_registered_delegate_callbacks),
    ]
}
