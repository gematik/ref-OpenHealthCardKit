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

import Foundation
import GemCommonsKit
@testable import HealthCardAccess
import Nimble
import XCTest

final class ExecutorTest: XCTestCase {

    func testImmediateExecutor() {
        var executed = false
        let task = { () -> String in
            executed = true
            return "Done"
        }
        let future = Executor.trampoline.run(task)
        expect(future).toNot(beNil())
        expect(executed) == true
        expect(future.cancel(mayInterruptIfRunning: true)) == false
        expect(future.done) == true
        let event = future.test()
        expect(event.cancelled) == false
        expect(event.value) == "Done"
    }

    func testMainExecutor() {
        var executed = false
        let task = { () -> String in
            executed = Thread.isMainThread
            return "Done"
        }
        let future = Executor.main.run(task)
        expect(future).toNot(beNil())
        let event = future.test()
        expect(event.value).to(equal("Done"))
        expect(future.cancel(mayInterruptIfRunning: true)) == false
        expect(executed).to(beTrue())
        expect(future.done) == true
        expect(event.cancelled) == false
    }

    func testMainExecutorCancelled() {
        var executed = false
        let task = { () -> String in
            executed = true
            return "Done"
        }
        let future = Executor.main.run(task)
        expect(future).toNot(beNil())
        let event = future.test()
        expect(future.cancel(mayInterruptIfRunning: true)) == false
        expect(event.cancelled) == false
        expect(event.error).to(beNil())
        expect(event.value) == "Done"
        expect(executed) == true
        expect(future.done) == true
    }

    func testQueuedExecutor() {
        var executed = false
        var mainThread = Thread.isMainThread

        func task() -> String {
            mainThread = Thread.isMainThread
            executed = true
            return "Done"
        }

        let future = Executor.default.run(task)
        expect(future).toNot(beNil())
        let event = future.test()
        expect(event.value).to(equal("Done"))
        expect(future.cancel(mayInterruptIfRunning: true)) == false
        expect(executed).to(beTrue())
        expect(event.timedOut) == false
        expect(future.done) == true
        expect(mainThread) == false
        expect(event.cancelled) == false
    }

    func testSerialExecutor() {
        let syncVar = SynchronizedVar([Int]())

        let eventBlock = { (value: FutureEvent<[Int]>) -> Void in
            if let value = value.value {
                syncVar.value = value
            }
        }

        func tasks(on scheduler: Executor) -> Future<[Int]> {
            scheduler.run(task(1)).on(event: eventBlock)
            scheduler.run(task(2)).on(event: eventBlock)
            scheduler.run(task(3)).on(event: eventBlock)
            scheduler.run(task(4)).on(event: eventBlock)
            return scheduler.run(task(5))
        }

        func task(_ num: Int) -> () -> [Int] {
            return {
                return syncVar.value + [num]
            }
        }

        let future = tasks(on: Executor.serial)
        expect(future).toNot(beNil())
        let event = future.test()
        expect(event.value).to(equal([1, 2, 3, 4, 5]))
        expect(event.timedOut) == false
        expect(future.cancel(mayInterruptIfRunning: true)) == false
        expect(future.done) == true
        expect(event.cancelled) == false
    }

    func testCombinedExecutors() {
        let future: Future<String> = Executable<String>
                .evaluate {
                    "Operate it"
                }
                .schedule(on: Executor.main)
                .map { _ -> String in
                    "See it"
                }
                .schedule(on: Executor.serial)
                .map { _ -> String in
                    "Do it"
                }
                .schedule(on: Executor.main)
                .run(on: Executor.trampoline)

        let event = future.test()
        expect(event.value) == "Do it"
        expect(future.done).to(beTrue())
    }

    func testCombinedFlatMappedExecutors() {
        let executable: Executable<String> = Executable<String>
                .evaluate {
                    "[Operate it:\(String(describing: Thread.isMainThread))]"
                }
                .schedule(on: Executor.main)
                .schedule(on: Executor.serial)
                .schedule(on: Executor.background)
                .schedule(on: Executor.serial)
                .map { string in
                    string + "[See it]"
                }
                .flatMap { string -> Executable<String> in
                    Executable<String>.evaluate {
                        string + "[Eval this:\(String(describing: Thread.isMainThread))]"
                    }
                }
                .schedule(on: Executor.serial)
                .map { string -> String in
                    string + "[Do it]"
                }
                .schedule(on: Executor.main)

        let executable2: Executable<String> =
                executable
                        .flatMap { string -> Executable<String> in
                            return executable
                                    .map { other -> String in
                                        return other + string
                                    }
                                    .schedule(on: Executor.background)
                        }
                        .schedule(on: Executor.main)

        let future = executable2.run(on: Executor.trampoline)
        let event = future.test()
        expect(future.done).to(beTrue())
        expect(event.value) == "[Operate it:true][See it][Eval this:false][Do it]" +
                "[Operate it:true][See it][Eval this:false][Do it]"
        expect(event.timedOut) == false
    }

    func testDeadLockMain() {
        let future = Executor.main.run {
            return Executor.main.run {
                return Executor.main.run {
                    return "Works it"
                }
            }
        }

        let unwrappedFuture = future.flatMap {
            $0.flatMap {
                $0
            }
        }

        expect(unwrappedFuture.test().value) == "Works it"
        expect(unwrappedFuture.done).to(beTrue())
        expect(future.done).to(beTrue())
    }

    func testDeadLockDefault() {
        let future = Executor.default.run {
            return Executor.default.run {
                return Executor.default.run {
                    return "Works too"
                }
            }
        }

        let unwrappedFuture = future.flatMap {
            $0.flatMap {
                $0
            }
        }

        expect(unwrappedFuture.test().value) == "Works too"
        expect(unwrappedFuture.done).to(beTrue())
        expect(future.done).to(beTrue())
    }

    func testDeadLockSerial() {
        let future = Executor.serial.run {
            return Executor.serial.run {
                return Executor.serial.run {
                    return "Works me"
                }
            }
        }

        let unwrappedFuture = future.flatMap {
            $0.flatMap {
                $0
            }
        }
        expect(unwrappedFuture.test().value) == "Works me"
        expect(unwrappedFuture.done).to(beTrue())
        expect(future.done).to(beTrue())
    }

    func testDeadLockMixed() {
        let future = Executor.serial.run {
            return Executor.main.run {
                return Executor.serial.run {
                    return Executor.main.run {
                        return "Works 4 real"
                    }
                }
            }
        }

        let unwrappedFuture = future.flatMap {
            $0.flatMap {
                $0.flatMap {
                    $0
                }
            }
        }
        expect(unwrappedFuture.test().value) == "Works 4 real"
        expect(unwrappedFuture.done).to(beTrue())
        expect(future.done).to(beTrue())
    }

    static let allTests = [
        ("testImmediateExecutor", testImmediateExecutor),
        ("testMainExecutor", testMainExecutor),
        ("testMainExecutorCancelled", testMainExecutorCancelled),
        ("testQueuedExecutor", testQueuedExecutor),
        ("testSerialExecutor", testSerialExecutor),
        ("testCombinedExecutors", testCombinedExecutors),
        ("testCombinedFlatMappedExecutors", testCombinedFlatMappedExecutors),
        ("testDeadLockMain", testDeadLockMain),
        ("testDeadLockDefault", testDeadLockDefault),
        ("testDeadLockSerial", testDeadLockSerial),
        ("testDeadLockMixed", testDeadLockMixed)
    ]
}
