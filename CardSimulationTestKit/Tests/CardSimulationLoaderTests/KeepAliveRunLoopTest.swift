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

final class KeepAliveRunLoopTest: XCTestCase {
    func testRunloop() {
        let keepAliveRunloop = KeepAliveRunLoop()
        keepAliveRunloop.start()
        let runloop = keepAliveRunloop.runloop
        expect(runloop).toNot(beNil())
    }

    func testRunloopEnds() {
        var threadEnded = false
        let keepAliveRunloop = KeepAliveRunLoop()
        keepAliveRunloop.start()
        keepAliveRunloop.runloop.perform(inModes: [.default]) { [keepAliveRunloop] in
            keepAliveRunloop.cancel()
            threadEnded = true
        }

        expect(keepAliveRunloop.isCancelled).toEventually(beTrue())
        expect(keepAliveRunloop.isFinished).toEventually(beTrue())
        expect(threadEnded).toEventually(beTrue())
    }

    static var allTests = [
        ("testRunloop", testRunloop),
        ("testRunloopEnds", testRunloopEnds),
    ]
}
