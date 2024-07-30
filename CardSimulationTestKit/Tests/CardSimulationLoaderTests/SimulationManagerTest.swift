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

@testable import CardSimulationLoader
import GemCommonsKit
import Nimble
import XCTest

final class SimulationManagerTest: XCTestCase {
    private static let tempDir: URL = {
        NSTemporaryDirectory().asURL
            .appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)
    }()

    private static let manager: SimulationManager = {
        SimulationManager(tempDir: tempDir)
    }()

    typealias SimulationDelegateCallback = (manager: SimulationManagerType, simulator: SimulationRunnerType)

    class TestSimulationManagerDelegate: SimulationManagerDelegate {
        var startedSimulatorCalls = [SimulationDelegateCallback]()
        var endedSimulatorCalls = [SimulationDelegateCallback]()

        func simulation(manager: SimulationManagerType, didStart simulator: SimulationRunnerType) {
            startedSimulatorCalls.append((manager: manager, simulator: simulator))
        }

        func simulation(manager: SimulationManagerType, didEnd simulator: SimulationRunnerType) {
            endedSimulatorCalls.append((manager: manager, simulator: simulator))
        }

        var didCallStarted: Bool {
            startCallsCount > 0
        }

        var startCallsCount: Int {
            startedSimulatorCalls.count
        }

        var didCallEnded: Bool {
            endCallsCount > 0
        }

        var endCallsCount: Int {
            endedSimulatorCalls.count
        }
    }

    // swiftlint:disable:next function_body_length
    func testSimulationManager() {
        do {
            let simulatorConfig = Bundle(for: SimulationRunnerTest.self)
                .testResourceFilePath(in: "Configuration",
                                      for: "configuration_EGKG2_80276883110000017222_gema5_TCP.xml")
                .asURL
            let manager = SimulationManagerTest.manager
            let delegate = TestSimulationManagerDelegate()
            var strongDelegate = TestSimulationManagerDelegate()
            weak var weakDelegate = strongDelegate
            let deregisteredDelegate = TestSimulationManagerDelegate()
            manager.register(delegate: delegate)
            // Check for double registration
            manager.register(delegate: delegate)
            manager.register(delegate: deregisteredDelegate)
            manager.register(delegate: strongDelegate)
            manager.deregister(delegate: deregisteredDelegate)
            // Double de-registration should not be a problem
            manager.deregister(delegate: deregisteredDelegate)
            let runner = try manager.createSimulation(
                configFile: simulatorConfig,
                preprocessor: [XMLPathManipulatorHolder.tlvPortManipulator(port: "0"),
                               XMLPathManipulatorHolder.relativeToAbsolutePathManipulator(
                                   with: XMLPathManipulatorHolder.CardConfigFileXMLPath,
                                   absolutePath: simulatorConfig.deletingLastPathComponent()
                               ),
                               XMLPathManipulatorHolder.relativeToAbsolutePathManipulator(
                                   with: XMLPathManipulatorHolder.ChannelConfigFileXMLPath,
                                   absolutePath: simulatorConfig.deletingLastPathComponent()
                               )]
            )
            expect(runner).toNot(beNil())
            expect(runner.mode.isNotRunning).to(beTrue())
            runner.start(waitUntilLaunched: true)
            expect(runner.mode.isRunning).to(beTrue())
            expect(manager.runners).to(containElementSatisfying({ element in element === runner }, ""))

            // Verify delegate got notified of SimulationRunner start
            expect(delegate.didCallStarted).to(beTrue())
            // Verify no double calls despite 'double' registration
            expect(delegate.startCallsCount).to(equal(1))
            expect(weakDelegate?.didCallStarted ?? false).to(beTrue())
            expect(delegate.didCallEnded).to(beFalse())
            expect(deregisteredDelegate.didCallEnded).to(beFalse())
            expect(deregisteredDelegate.didCallStarted).to(beFalse())

            strongDelegate = TestSimulationManagerDelegate()

            let lateDelegate = TestSimulationManagerDelegate()
            manager.register(delegate: lateDelegate)
            /// Late delegate should still get notified of already running simulators
            expect(lateDelegate.startCallsCount).to(equal(1))

            runner.stop(waitUntilTerminated: true)

            // We need to wait a bit to allow for the delegate callbacks to be executed on the callback thread
            RunLoop.current.run(mode: RunLoop.Mode.default, before: Date(timeIntervalSinceNow: 0.25))

            //
            // Verify delegate got notified of SimulationRunner ended
            expect(delegate.didCallEnded).to(beTrue())
            expect(deregisteredDelegate.didCallEnded).to(beFalse())
            expect(deregisteredDelegate.didCallStarted).to(beFalse())

            expect(manager.runners).toNot(containElementSatisfying({ element in element === runner }, ""))
            // Assert that delegates are weak referenced
            expect(weakDelegate?.didCallEnded ?? false).to(beFalse())
            expect(weakDelegate).to(beNil())
        } catch {
            ALog("Exception thrown in test-case [\(error)]")
            #if os(macOS) || os(Linux)
            Nimble.fail("Failed with error \(error)")
            #else
            ALog("Skip testSimulationManager on platform other than macOS | Linux")
            #endif
        }
    }

    func testSimulationManager_fail_to_start() {
        do {
            let delegate = TestSimulationManagerDelegate()
            let manager = SimulationManagerTest.manager
            manager.register(delegate: delegate)
            /// Starting with this config file will fail this time since we don't change the image and channelContext
            /// paths and therefore the G2-Kartensimulation can't start. Although our SimulationManager should just
            /// run fine and detect this behaviour
            let simulatorConfig = Bundle(for: SimulationRunnerTest.self)
                .testResourceFilePath(in: "Configuration",
                                      for: "configuration_EGKG2_80276883110000017222_gema5_TCP.xml")
                .asURL
            let runner = try manager.createSimulation(
                configFile: simulatorConfig,
                preprocessor: []
            )
            expect(runner).toNot(beNil())
            expect(runner.mode.isNotRunning).to(beTrue())
            runner.start(waitUntilLaunched: true)
            expect(runner.mode.isTerminated).to(beTrue())

            expect(manager.runners).toNot(containElementSatisfying({ element in element === runner }, ""))

            //
            // Verify delegate did not get notified of SimulationRunner start
            expect(delegate.didCallStarted).to(beFalse())
            expect(delegate.didCallEnded).to(beTrue())

        } catch {
            ALog("Exception thrown in test-case [\(error)]")
            #if os(macOS) || os(Linux)
            Nimble.fail("Failed with error \(error)")
            #else
            ALog("Skip testSimulationManager_fail_to_start on platform other than macOS | Linux")
            #endif
        }
    }

    func testSimulationManagerClean() {
        #if os(macOS) || os(Linux)
        expect(FileManager.default.fileExists(atPath: SimulationManagerTest.tempDir.path)).to(beTrue())
        let manager = SimulationManagerTest.manager
        manager.clean()
        expect(FileManager.default.fileExists(atPath: SimulationManagerTest.tempDir.path)).toEventually(beFalse())
        #else
        ALog("Skip testSimulationManagerClean on platform other than macOS | Linux")
        #endif
    }

    static var allTests = [
        ("testSimulationManager", testSimulationManager),
        ("testSimulationManager_fail_to_start", testSimulationManager_fail_to_start),
        ("testSimulationManagerClean", testSimulationManagerClean),
    ]
}
