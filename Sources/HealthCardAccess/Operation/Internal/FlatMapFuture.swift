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

internal class FlatMapFuture<A, B>: Future<B> {
    private let source: Future<A>
    private let transform: Function<A, Future<B>>

    init(_ source: Future<A>, _ transform: @escaping Function<A, Future<B>>) {
        self.source = source
        self.transform = transform
    }

    override internal func on(event block: @escaping Consumer<FutureEvent<B>>) {
        if !done {
            let mapper = transform
            source.on { [weak self] event in
                self?.done = true
                event.map(mapper).fold(
                        onComplete: { $0.on(event: block) },
                        onCancelled: { block(FutureEvent<B>.cancelled()) },
                        onTimedOut: { block(FutureEvent<B>.timedOut()) },
                        onError: { err in block(FutureEvent<B>.error(from: err)) }
                )
            }
        } else {
            block(.error(from: FutureError.completed))
        }
    }

    override internal func cancel(mayInterruptIfRunning flag: Bool) -> Bool {
        if !done {
            return source.cancel(mayInterruptIfRunning: flag)
        }
        return false
    }
}
