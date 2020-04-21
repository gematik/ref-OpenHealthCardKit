//
//  Copyright (c) 2020 gematik GmbH
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//     http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

@testable import HealthCardAccess
import Nimble
import XCTest

final class ExecutableTest: XCTestCase {

    class Runner: ExecutorType {
        var executionCounter = 0

        func run<A>(_ block: @escaping Callable<A>) -> Future<A> {
            executionCounter += 1
            return Future<A>.unit(block: block)
        }
    }

    class Error: Swift.Error {
    }

    func testExecutableUnit() {
        let value = "Value"
        let executable = Executable<String>.unit(value)
        let runner = Runner()

        expect {
            executable.run(on: runner).test().get(orElse: "Else")
        } == value
        expect(runner.executionCounter) == 0
    }

    func testExecutableEvaluated() {
        let value = "Value"
        let executable = Executable<String>.evaluate {
            value
        }
        let runner = Runner()

        expect {
            executable.run(on: runner).test().get(orElse: "Else")
        } == value
        expect(runner.executionCounter) == 1
    }

    func testExecutableEvaluatedThrowing() {
        let executable = Executable<String>.evaluate { () -> String in
            throw Error()
        }
        let runner = Runner()

        expect {
            executable.run(on: runner).test().get(orElse: "Else")
        } == "Else"
        expect(runner.executionCounter) == 1
    }

    func testExecutableMap() {
        let value = "Value"
        let executable = Executable<String>.unit(value).map {
            $0 + $0
        }
        let runner = Runner()

        expect {
            executable.run(on: runner).test().get(orElse: "Else")
        } == (value + value)
        expect(runner.executionCounter) == 0
    }

    func testExecutableMapThrowing() {
        let value = "Value"
        let executable = Executable<String>.unit(value).map { _ -> String in
            throw Error()
        }
        let runner = Runner()

        expect {
            executable.run(on: runner).test().get(orElse: "Else")
        } == "Else"
        expect(runner.executionCounter) == 0
    }

    func testExecutableFlatMap() {
        let value = "Value"
        let executable = Executable<String>.unit(value)
                .flatMap { element in
                    Executable<String>.evaluate {
                        element + element
                    }
                }
        let runner = Runner()

        expect {
            executable.run(on: runner).test().get(orElse: "Else")
        } == "ValueValue"
        expect(runner.executionCounter) == 1
    }

    func testExecutableFlatMapThrowing() {
        let value = "Value"
        let executable = Executable<String>.unit(value)
                .flatMap { _ -> Executable<String> in
                    throw Error()
                }
                .flatMap { _ in
                    Executable<String>.evaluate {
                        "Evaluated"
                    }
                }
        let runner = Runner()

        expect {
            executable.run(on: runner).test().get(orElse: "Else")
        } == "Else"
        expect(runner.executionCounter) == 0
    }

    func testExecutableScheduling() { //swiftlint:disable:this function_body_length
        let value = "Value"
        let runner = Runner()
        let runner2 = Runner()
        let runner3 = Runner()
        let executable = Executable<String>
                .evaluate {
                    value
                }
                .map {
                    $0 + $0
                }
                .flatMap { element in
                    Executable<String>.evaluate {
                        element + "[FlatMap evaluated]"
                    }
                }
                .schedule(on: runner)
                .flatMap { (element: String) -> Executable<String> in
                    Executable<String>.evaluate {
                        element + "[Evaluate on runner 2]"
                    }
                }
                .schedule(on: runner2)
                .flatMap { (element: String) -> Executable<String> in
                    Executable<String>.evaluate {
                        element + "[Evaluate on provided runner]"
                    }
                }

        expect {
            executable.run(on: runner3).test().get(orElse: "Else")
        } == "ValueValue[FlatMap evaluated][Evaluate on runner 2][Evaluate on provided runner]"
        expect(runner.executionCounter) == 3
        expect(runner2.executionCounter) == 3
        expect(runner3.executionCounter) == 2

        // Assert that a failed Executable isn't scheduling down stream
        let runner4 = Runner()
        expect {
            Executable<String>
                    .evaluate {
                        "Second test"
                    }
                    .map { _ -> String in
                        throw Error()
                    }
                    .flatMap { _ in
                        executable
                    }
                    .run(on: runner4)
                    .test()
                    .get(orElse: "Else")
        } == "Else"

        expect(runner.executionCounter) == 3
        expect(runner2.executionCounter) == 3
        expect(runner3.executionCounter) == 2
        expect(runner4.executionCounter) == 1
    }

    static let allTests = [
        ("testExecutableUnit", testExecutableUnit),
        ("testExecutableEvaluated", testExecutableEvaluated),
        ("testExecutableEvaluatedThrowing", testExecutableEvaluatedThrowing),
        ("testExecutableMap", testExecutableMap),
        ("testExecutableMapThrowing", testExecutableMapThrowing),
        ("testExecutableFlatMap", testExecutableFlatMap),
        ("testExecutableFlatMapThrowing", testExecutableFlatMapThrowing),
        ("testExecutableScheduling", testExecutableScheduling)
    ]
}
