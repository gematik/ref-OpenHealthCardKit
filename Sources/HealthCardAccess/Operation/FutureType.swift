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

/// Generic Future Type
public protocol FutureType {
    /// Type of the Element delivered with the below mentioned `event` upon .completed
    associatedtype Element

    /// Register a callback/continuation block for when the Future fulfills.
    /// - Note: this prevents blocking execution of calling thread,
    ///         the callback is invoked from the producing thread/queue
    /// - Parameter block: The callback to invoke when the event has become available
    func on(event block: @escaping Consumer<FutureEvent<Element>>)

    /// Cancel the execution (when possible)
    /// - Parameter flag: whether to send an interrupt to the executing thread when already executing
    /// - Returns: `false` when the task could not be cancelled, `true` when cancelled successfully
    func cancel(mayInterruptIfRunning flag: Bool) -> Bool

    /// Whether the execution is done (E.g. fulfilled, failed or cancelled)
    var done: Bool { get }
}

extension FutureType {
    /// Unit future that wraps a concrete value into a .completed FutureEvent
    /// - Parameters value: the value to wrap by the returned Future
    /// - Returns: a completed Future
    public static func unit<A>(_ value: A) -> Future<A> {
        return Self.unit(event: .completed(value))
    }

    internal static func unit<A>(event: FutureEvent<A>) -> Future<A> {
        return UnitFuture(event: event)
    }

    internal static func unit<A>(block: @escaping Callable<A>) -> Future<A> {
        do {
            let value = try block()
            return Self.unit(value)
        } catch let error {
            return Self.unit(event: .error(from: error))
        }
    }

    internal static func cancelled<A>() -> Future<A> {
        return Self.unit(event: FutureEvent<A>.cancelled())
    }

    internal static func timedOut<A>() -> Future<A> {
        return Self.unit(event: FutureEvent<A>.timedOut())
    }

    internal static func error<A>(_ error: Swift.Error) -> Future<A> {
        return Self.unit(event: FutureEvent<A>.error(from: error))
    }
}

/// Abstract Future class that all FutureTypes should extend from
open class Future<A>: FutureType {
    public typealias Element = A

    public internal(set) var done: Bool = false

    public func on(event block: @escaping Consumer<FutureEvent<A>>) {
        abstractError()
    }

    public func cancel(mayInterruptIfRunning flag: Bool) -> Bool {
        abstractError()
    }
}

extension Future {
    /// Transform Self.Element
    /// - Parameter transform: closure that takes Self.Element and returns F.Element
    /// - Returns: Future that maps Self to F
    public func map<B>(_ transform: @escaping Function<A, B>) -> Future<B> {
        return flatMap { element in
            Future.unit {
                try transform(element)
            }
        }
    }

    /// Transform Self.Element
    /// - Parameter transform: closure that takes Self.Element and returns a Future
    /// - Returns: the Future given by executing `transform`
    public func flatMap<B>(_ transform: @escaping Function<A, Future<B>>) -> Future<B> {
        return FlatMapFuture(self, transform)
    }
}
