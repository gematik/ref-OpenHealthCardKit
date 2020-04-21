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
import HealthCardAccess

extension FutureType {

    func test(timeout millis: Int = 3000, sleep interval: TimeInterval = 0.1) -> FutureEvent<Self.Element> {
        var done = false
        var futureEvent: FutureEvent<Self.Element>!

        on { event in
            futureEvent = event
            done = true
        }
        let timeoutTime = DispatchTime.now() + DispatchTimeInterval.milliseconds(millis)
        while !done && (timeoutTime > DispatchTime.now() || millis <= 0) {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: interval))
        }
        if !done {
            DLog("Timeout by Test observer")
            futureEvent = FutureEvent.failed(.timeout)
        }
        return futureEvent
    }
}
