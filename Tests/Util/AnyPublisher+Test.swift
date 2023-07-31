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

import Combine
import Foundation
import GemCommonsKit

extension AnyPublisher {
    func test() throws -> Self.Output {
        try testWithTimeout(timeout: 0)
    }

    func testWithTimeout(timeout millis: Int = 3000, sleep interval: TimeInterval = 0.1) throws -> Self.Output {
        var done = false
        var output: Self.Output?
        var error: Self.Failure?
        let timeoutTime = DispatchTime.now() + DispatchTimeInterval.milliseconds(millis)
        let cancellable = sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished: done = true
                case let .failure(failure):
                    error = failure
                    done = true
                }
            },
            receiveValue: { receivedValue in
                output = receivedValue
            }
        )

        while !done && (timeoutTime > DispatchTime.now() || millis <= 0) {
            DLog("!done")
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: interval))
        }
        if !done {
            cancellable.cancel()
            throw AnyPublisherTestError.timeoutError
        }

        if let output = output {
            return output
        } else if let error = error {
            throw error
        } else {
            throw AnyPublisherTestError.noValuesPublished
        }
    }
}

enum AnyPublisherTestError: Error {
    case noValuesPublished
    case timeoutError
}
