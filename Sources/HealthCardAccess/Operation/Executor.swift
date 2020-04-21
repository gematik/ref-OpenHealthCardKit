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

public enum Executor: ExecutorType {
    /// Trampoline (e.g. not scheduling, immediate execution)
    case trampoline
    /// Execute on the main thread/queue
    case main
    /// Execute on the given queue
    case queued(DispatchQueue)

    public func run<A>(_ block: @escaping Callable<A>) -> Future<A> {
        switch self {
        case .trampoline:
            return Future<A>.unit(block: block)
        case .main:
            return Executor.schedule(on: DispatchQueue.main, block: block)
        case .queued(let queue):
            return Executor.schedule(on: queue, block: block)
        }
    }

    private static func schedule<A>(on queue: DispatchQueue, block: @escaping Callable<A>) -> Future<A> {
        let future = ReplayFuture<A>()
        queue.async {
            execute(block, with: future)
        }
        return future
    }

    private static func execute<A>(_ action: @escaping Callable<A>, with future: ReplayFuture<A>) {
        do {
            if !future.cancelled {
                let value = try action()
                future.complete(with: .completed(value))
            } else {
                future.complete(with: .cancelled())
            }
        } catch let error {
            future.complete(with: .error(from: error))
        }
    }
}

extension Executor {
    /// Serial queue executor
    public static let serial = Executor.queued(OS_dispatch_queue_serial(label: "Serial"))
    /// Queue on dispatch queue with `.userInteractive` qos
    public static let userInteractive = Executor.queued(DispatchQueue.global(qos: .userInteractive))
    /// Queue on dispatch queue with `.userInitiated` qos
    public static let userInitiated = Executor.queued(DispatchQueue.global(qos: .userInitiated))
    /// Queue on default dispatch queue
    public static let `default` = Executor.queued(DispatchQueue.global(qos: .default))
    /// Queue on utility dispatch queue
    public static let utility = Executor.queued(DispatchQueue.global(qos: .utility))
    /// Queue on background dispatch queue
    public static let background = Executor.queued(DispatchQueue.global(qos: .background))
}
