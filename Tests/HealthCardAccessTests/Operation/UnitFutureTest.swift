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

final class UnitFutureTest: XCTestCase {

    class Error: Swift.Error {
    }

    func testUnitFuture() {
        let future = UnitFuture("String")
        expect(future.test().value) == "String"
        expect(future.done) == true
        expect(future.cancel(mayInterruptIfRunning: true)) == false
        expect(future.test().cancelled) == false
    }

    func testUnitFutureEvent() {
        let future = UnitFuture<String>(event: .failed(.cancelled))
        let event = future.test()
        expect(event.cancelled) == true
        expect(event.error).to(beNil())
        expect(future.done) == true
    }

    func testUnitFutureEventError() {
        let error = Error()
        let future = UnitFuture<String>(event: .failed(.error(error)))
        expect(future.test().error).to(beIdenticalTo(error))
        expect(future.done) == true
    }

    func testUnitFutureMap() {
        let future: Future<String> = UnitFuture(100).map {
            String($0)
        }
        expect(future.test().value) == "100"
        expect(future.done) == true
    }

    func testUnitFutureMapThrowing() {
        let future: Future<Int> = UnitFuture(100).map { _ in
            throw Error()
        }

        let event = future.test()
        expect(event.value).to(beNil())
        expect(event.error).toNot(beNil())
        expect(event.cancelled) == false
        expect(future.done) == true

    }

    func testUnitFutureFlatMap() {
        let future: Future<String> = UnitFuture(100).flatMap { _ in
            Future<String>.unit {
                "Not cancelled"
            }
        }
        let event = future.test()
        expect(event.value) == "Not cancelled"
        expect(event.cancelled) == false
        expect(future.done) == true
    }

    func testUnitFutureFlatMapErrorBeforeCancel() {
        let future: Future<String> = UnitFuture(100)
                .map { input -> String in
                    if input == 100 {
                        throw Error()
                    }
                    return "No error"
                }
                .flatMap { _ -> Future<String> in
                    Future<String>.cancelled()
                }
                .map { _ in
                    "Mapped"
                }

        let event = future.test()
        expect(event.value).to(beNil())
        expect(event.cancelled) == false
        expect(event.error).toNot(beNil())
        expect(future.done) == true
    }

    func testUnitFutureFlatMapCancelBeforeError() {
        let future: Future<String> = UnitFuture(100).flatMap { _ in
            UnitFuture<String>(event: .failed(.cancelled)).map { _ in
                throw Error()
            }
        }

        let event = future.test()
        expect(event.value).to(beNil())
        expect(event.cancelled) == true
        expect(event.error).to(beNil())
        expect(future.done) == true

    }

    static let allTests = [
        ("testUnitFuture", testUnitFuture),
        ("testUnitFutureEvent", testUnitFutureEvent),
        ("testUnitFutureEventError", testUnitFutureEventError),
        ("testUnitFutureMap", testUnitFutureMap),
        ("testUnitFutureMapThrowing", testUnitFutureMapThrowing),
        ("testUnitFutureFlatMap", testUnitFutureFlatMap),
        ("testUnitFutureFlatMapErrorBeforeCancel", testUnitFutureFlatMapErrorBeforeCancel),
        ("testUnitFutureFlatMapCancelBeforeError", testUnitFutureFlatMapCancelBeforeError)
    ]
}
