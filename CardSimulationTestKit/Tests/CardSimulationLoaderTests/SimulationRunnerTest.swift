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
import OSLog
import XCTest

final class SimulationRunnerTest: XCTestCase {
    private static let simTempPath: URL = {
        NSTemporaryDirectory().asURL
            .appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)
    }()

    private static var simTempDependencyInfo: SimulationManager.DependencyInfo?

    override class func setUp() {
        super.setUp()
        Logger.cardSimulationLoader.debug("Start simulator test at path: \(simTempPath)")

        do {
            let pomXml = try Data(contentsOf: Bundle(for: Self.self)
                .testResourceFilePath(in: "Resources", for: "pom.xml").asURL)

            simTempDependencyInfo = try SimulationManager.loadCardSimulatorDependencies(
                version: SimulationManager.defaultVersion,
                outputDirectory: simTempPath,
                pom: pomXml
            )
            .get()
        } catch {
            ALog("Error while loading dependencies: \(error)")
        }
    }

    override class func tearDown() {
        // delete temp directory
        do {
            try FileManager.default.removeItem(at: simTempPath)
        } catch {
            ALog("Error while cleaning up test-case. \(String(describing: error))")
        }
        super.tearDown()
    }

    func testSimulationRunner() {
        guard let dependencyInfo = SimulationRunnerTest.simTempDependencyInfo,
              let classPath = dependencyInfo.simulatorClassPath
        else {
            #if os(macOS) || os(Linux)
            Nimble.fail("Could not run test while SimulationRunnerTest.simTempDependencyInfo is nil")
            #else
            ALog("Skip testSimulationRunner on platform other than macOS | Linux")
            #endif
            return
        }
        var delegate = SimulationRunnerTestDelegate()
        let processedConfigFile = Bundle(for: SimulationRunnerTest.self)
            .testResourceFilePath(in: "Configuration",
                                  for: "configuration_EGKG2_80276883110000017222_gema5_TCP.xml")
            .asURL
        let runner = SimulationRunner(
            simulator: processedConfigFile,
            classPath: classPath,
            workingDirectory: processedConfigFile.deletingLastPathComponent()
        )
        runner.delegate = delegate
        runner.start(waitUntilLaunched: true)
        expect(runner.mode.isRunning).to(beTrue())

        guard delegate.callbackStates.count > 1 else {
            Nimble.fail("Not enough callbacks")
            return
        }
        expect(delegate.callbackStates[0].isInitializing).to(beTrue())
        expect(delegate.callbackStates[1].isRunning).to(beTrue())

        runner.stop(waitUntilTerminated: true)
        // Allow for the callback to be scheduled on main
        RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.25))

        guard delegate.callbackStates.count > 2 else {
            Nimble.fail("Not enough callbacks")
            return
        }
        expect(delegate.callbackStates[2].isTerminated).to(beTrue())
        // test whether delegate is weakly retained
        delegate = SimulationRunnerTestDelegate()
        expect(runner.delegate).to(beNil())
    }

    static var allTests = [
        ("testSimulationRunner", testSimulationRunner),
    ]
}

class SimulationRunnerTestDelegate: SimulationRunnerDelegate {
    var callbackStates: [SimulationProcessMode] = []

    func simulation(runner _: SimulationRunnerType, changed mode: SimulationProcessMode) {
        callbackStates.append(mode)
    }
}
