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

final class FutureTypeTest: XCTestCase {

    class Error: Swift.Error {
    }

    func testFutureTypeUnit() {
        let future = Future<String>.unit("String")
        expect(future.test().value) == "String"
    }

    func testFutureTypeEvaluated() {
        let future = Future<String>.unit {
            "Evaluated string"
        }
        expect(future.test().value) == "Evaluated string"
    }

    func testFutureTypeEvaluatedThrowing() {
        let future = Future<String>.unit {
            throw Error()
        }
        let event = future.test()
        expect(event.error).toNot(beNil())
        expect(event.cancelled) == false
    }

    func testFutureTypeCancelled() {
        let future: Future<String> = Future<String>.cancelled()
        expect(future.test().cancelled) == true
    }

    func testFutureTypeError() {
        let error = Error()
        let future: Future<String> = Future<String>.error(error)
        expect(future.test().error).to(beIdenticalTo(error))
    }

    func testFutureMap() {
        let future: Future<String> = Future<Int>.unit(100).map {
            String($0)
        }
        expect(future.test().value) == "100"
    }

    func testFutureMapThrowing() {
        let future: Future<String> = Future<Int>.unit(100).map { _ in
            throw Error()
        }

        let event = future.test()
        expect(event.value).to(beNil())
        expect(event.error).toNot(beNil())
        expect(event.cancelled) == false
    }

    func testFutureFlatMap() {
        let future: Future<String> = Future<Int>.unit(100).flatMap { _ in
            Future<String>.unit {
                "Not cancelled"
            }
        }
        let event = future.test()
        expect(event.value) == "Not cancelled"
        expect(event.cancelled) == false
    }

    func testFutureFlatMapErrorBeforeCancel() {
        let future: Future<String> = Future<Int>.unit(100)
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
    }

    func testFutureFlatMapCancelBeforeError() {
        let future: Future<String> = Future<Int>.unit(100).flatMap { _ -> Future<String> in
            Future<String>.cancelled().map { (_: String) -> String in
                throw Error()
            }
        }
        let event = future.test()
        expect(event.value).to(beNil())
        expect(event.cancelled) == true
        expect(event.error).to(beNil())

    }

    func testFutureGetOrElse() {
        expect { Future<Int>.unit(100).test().get(orElse: 101) } == 100
    }

    static let allTests = [
        ("testFutureTypeUnit", testFutureTypeUnit),
        ("testFutureTypeEvaluated", testFutureTypeEvaluated),
        ("testFutureTypeEvaluatedThrowing", testFutureTypeEvaluatedThrowing),
        ("testFutureTypeCancelled", testFutureTypeCancelled),
        ("testFutureTypeError", testFutureTypeError),
        ("testFutureMap", testFutureMap),
        ("testFutureMapThrowing", testFutureMapThrowing),
        ("testFutureFlatMap", testFutureFlatMap),
        ("testFutureFlatMapErrorBeforeCancel", testFutureFlatMapErrorBeforeCancel),
        ("testFutureFlatMapCancelBeforeError", testFutureFlatMapCancelBeforeError),
        ("testFutureGetOrElse", testFutureGetOrElse)
    ]
}
