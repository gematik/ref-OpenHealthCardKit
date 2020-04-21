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

internal class ForwardingFuture<T>: Future<T> {
    private let producer: (@escaping Consumer<FutureEvent<T>>) -> Void
    private var cancelled = false

    init(_ block: @escaping (@escaping Consumer<FutureEvent<T>>) -> Void) {
        self.producer = block
    }

    override internal func on(event block: @escaping Consumer<FutureEvent<T>>) {
        if !done {
            if !cancelled {
                producer { [weak self] (event: FutureEvent<T>) in
                    self?.done = true
                    block(event)
                }
            } else {
                self.done = true
                block(.cancelled())
            }
        } else {
            block(.error(from: FutureError.completed))
        }
    }

    override internal func cancel(mayInterruptIfRunning flag: Bool) -> Bool {
        if !cancelled && !done {
            cancelled = true
        }
        return cancelled
    }
}
