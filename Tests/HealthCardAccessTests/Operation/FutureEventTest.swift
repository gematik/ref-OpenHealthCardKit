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

final class FutureEventTest: XCTestCase {

    class Error: Swift.Error {
    }

    func testFutureEventCompleted() {
        let event = FutureEvent.completed("Completed")

        expect(event.value) == "Completed"
        expect(event.error).to(beNil())
        expect(event.cancelled) == false

        expect { event.map { $0 + $0 } } == .completed("CompletedCompleted")
        expect { event.flatMap { _ in FutureEvent<String>.failed(.cancelled) } } == .failed(.cancelled)
        expect { event.flatMap { _ in .completed("FlatMapped") } } == .completed("FlatMapped")
        expect { event.flatMap { _ in FutureEvent<String>.failed(.error(Error())) } } == .failed(.error(Error()))
        expect { event.map { _ -> String in throw Error() } } == .failed(.error(Error()))
        expect { event.flatMap { _ -> FutureEvent<String> in throw Error() } } == .failed(.error(Error()))

        expect {
            event.fold(
                onComplete: { _ in "completed" },
                onCancelled: { "cancelled" },
                onTimedOut: { "timeout" },
                onError: { _ in "error" }
            )
        } == "completed"

        expect { event.get(orElse: "Else") } == "Completed"
    }

    func testFutureEventCancelled() {
        let event = FutureEvent<String>.failed(.cancelled)

        expect(event.value).to(beNil())
        expect(event.error).to(beNil())
        expect(event.cancelled) == true

        expect { event.map { $0 + $0 } } == .failed(.cancelled)
        expect { event.flatMap { _ in FutureEvent<String>.failed(.cancelled) } } == .failed(.cancelled)
        expect { event.flatMap { _ in .completed("FlatMapped") } } == .failed(.cancelled)
        expect { event.flatMap { _ in FutureEvent<String>.failed(.error(Error())) } } == .failed(.cancelled)
        expect { event.map { _ -> String in throw Error() } } == .failed(.cancelled)
        expect { event.flatMap { _ -> FutureEvent<String> in throw Error() } } == .failed(.cancelled)

        expect {
            event.fold(
                    onComplete: { _ in "completed" },
                    onCancelled: { "cancelled" },
                    onTimedOut: { "timeout" },
                    onError: { _ in "error" }
            )
        } == "cancelled"

        expect { event.get(orElse: "Else") } == "Else"
    }

    func testFutureEventError() {
        let event = FutureEvent<String>.failed(.error(Error()))

        expect(event.value).to(beNil())
        expect(event.error).toNot(beNil())
        expect(event.cancelled) == false

        expect { event.map { $0 + $0 } } == .failed(.error(Error()))
        expect { event.flatMap { _ in FutureEvent<String>.failed(.cancelled) } } == .failed(.error(Error()))
        expect { event.flatMap { _ in .completed("FlatMapped") } } == .failed(.error(Error()))
        expect { event.flatMap { _ in FutureEvent<String>.failed(.error(Error())) } } == .failed(.error(Error()))
        expect { event.map { _ -> String in throw Error() } } == .failed(.error(Error()))
        expect { event.flatMap { _ -> FutureEvent<String> in throw Error() } } == .failed(.error(Error()))

        expect {
            event.fold(
                    onComplete: { _ in "completed" },
                    onCancelled: { "cancelled" },
                    onTimedOut: { "timeout" },
                    onError: { _ in "error" }
            )
        } == "error"

        expect { event.get(orElse: "Else") } == "Else"
    }

    static let allTests = [
        ("testFutureEventCompleted", testFutureEventCompleted),
        ("testFutureEventCancelled", testFutureEventCancelled),
        ("testFutureEventError", testFutureEventError)
    ]
}
