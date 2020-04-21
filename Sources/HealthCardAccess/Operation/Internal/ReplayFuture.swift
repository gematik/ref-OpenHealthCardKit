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

internal class ReplayFuture<A>: Future<A> {
    private var callback: Consumer<FutureEvent<A>>?
    private var event: FutureEvent<A>?

    var cancelled: Bool {
        return event?.cancelled ?? false
    }

    override func on(event block: @escaping Consumer<FutureEvent<A>>) {
        if let event = event {
            block(event)
        } else {
            callback = block
        }
    }

    override func cancel(mayInterruptIfRunning flag: Bool) -> Bool {
        if !done {
            event = .cancelled()
            done = true
            return true
        }
        return false
    }

    func complete(with event: FutureEvent<A>) {
        self.event = event
        done = true
        callback?(event)
    }
}
