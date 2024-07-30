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
import Nimble
import XCTest

final class JavaProcessTest: XCTestCase {
    class Delegate: JavaProcessUpdateDelegate {
        var launchedCalls = [(process: JavaProcess, pid: Int32)]()

        func processDidLaunch(_ process: JavaProcess, pid: Int32) {
            launchedCalls.append((process: process, pid: pid))
        }

        var terminateCalls = [(process: JavaProcess, status: Int32)]()

        func processDidTerminate(_ process: JavaProcess, with status: Int32) {
            terminateCalls.append((process: process, status: status))
        }
    }

    func testJavaProcessRun() {
        let pipe = Pipe()
        let config = JavaProcess.Config.build(workingDirectory: FileManager.default.currentDirectoryPath,
                                              classPath: "./*")
        let process = JavaProcess(config: config, stdout: pipe, stderr: pipe, stdin: pipe)
        let delegate = Delegate()
        process.run(delegate: delegate)

        RunLoop.current.run(mode: RunLoop.Mode.default, before: Date(timeIntervalSinceNow: 0.5))
        expect(delegate.launchedCalls.count).to(equal(1))
        expect(delegate.terminateCalls.count).to(equal(1))
    }

    static var allTests = [
        ("testJavaProcessRun", testJavaProcessRun),
    ]
}
