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

@testable import CardSimulationLoader
import Nimble
import XCTest

final class SimulationProcessModeTest: XCTestCase {
    func testMode_notStarted() {
        let mode = SimulationProcessMode.notStarted

        expect(mode.isNotRunning).to(beTrue())
        expect(mode.isTerminated).to(beFalse())
        expect(mode.isInitializing).to(beFalse())
        expect(mode.isRunning).to(beFalse())

        expect(mode.tlvPort).to(beNil())
        expect(mode.terminationStatus).to(beNil())

        expect(mode).toNot(equal(SimulationProcessMode.initializing))
        expect(mode).to(equal(SimulationProcessMode.notStarted))
        expect(mode).toNot(equal(SimulationProcessMode.running(onTCPPort: 500)))
        expect(mode).toNot(equal(SimulationProcessMode.terminated(terminationStatus: -1)))
    }

    func testMode_initializing() {
        let mode = SimulationProcessMode.initializing

        expect(mode.isNotRunning).to(beFalse())
        expect(mode.isTerminated).to(beFalse())
        expect(mode.isInitializing).to(beTrue())
        expect(mode.isRunning).to(beFalse())

        expect(mode.tlvPort).to(beNil())
        expect(mode.terminationStatus).to(beNil())

        expect(mode).to(equal(SimulationProcessMode.initializing))
        expect(mode).toNot(equal(SimulationProcessMode.notStarted))
        expect(mode).toNot(equal(SimulationProcessMode.running(onTCPPort: 500)))
        expect(mode).toNot(equal(SimulationProcessMode.terminated(terminationStatus: -1)))
    }

    func testMode_running() {
        let mode = SimulationProcessMode.running(onTCPPort: 9)

        expect(mode.isNotRunning).to(beFalse())
        expect(mode.isTerminated).to(beFalse())
        expect(mode.isInitializing).to(beFalse())
        expect(mode.isRunning).to(beTrue())

        expect(mode.tlvPort).to(equal(9))
        expect(mode.terminationStatus).to(beNil())

        expect(mode).toNot(equal(SimulationProcessMode.initializing))
        expect(mode).toNot(equal(SimulationProcessMode.notStarted))
        expect(mode).toNot(equal(SimulationProcessMode.running(onTCPPort: 500)))
        expect(mode).to(equal(SimulationProcessMode.running(onTCPPort: 9)))
        expect(mode).toNot(equal(SimulationProcessMode.terminated(terminationStatus: -1)))
    }

    func testMode_terminated() {
        let mode = SimulationProcessMode.terminated(terminationStatus: -1)

        expect(mode.isNotRunning).to(beFalse())
        expect(mode.isTerminated).to(beTrue())
        expect(mode.isInitializing).to(beFalse())
        expect(mode.isRunning).to(beFalse())

        expect(mode.tlvPort).to(beNil())
        expect(mode.terminationStatus).to(equal(-1))

        expect(mode).toNot(equal(SimulationProcessMode.initializing))
        expect(mode).toNot(equal(SimulationProcessMode.notStarted))
        expect(mode).toNot(equal(SimulationProcessMode.running(onTCPPort: 500)))
        expect(mode).to(equal(SimulationProcessMode.terminated(terminationStatus: -1)))
        expect(mode).toNot(equal(SimulationProcessMode.terminated(terminationStatus: 10)))
    }

    static var allTests = [
        ("testMode_notStarted", testMode_notStarted),
        ("testMode_initializing", testMode_initializing),
        ("testMode_running", testMode_running),
        ("testMode_terminated", testMode_terminated),
    ]
}
