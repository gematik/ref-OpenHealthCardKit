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

/// Closure that takes no arguments and either throws or returns a `A`
public typealias Callable<A> = () throws -> A
/// Closure that takes one argument of `A` and either throws or returns a `B`
public typealias Function<A, B> = (A) throws -> B
/// Consumer callback/continuation
public typealias Consumer<A> = (A) -> Void

/// Operation wrapping class to allow for closure mapping and scheduling Future
public class Executable<A> {
    typealias ExecutableOperation = (ExecutorType) -> Future<A>
    private let operation: ExecutableOperation

    private init(_ block: @escaping ExecutableOperation) {
        operation = block
    }

    /// Apply function to execute the ExecutableOperation
    /// - Parameters
    ///     - scheduler: executor to pass down the operation
    /// - Returns: Future<A> for the scheduled operation
    public func run(on scheduler: ExecutorType) -> Future<A> {
        return operation(scheduler)
    }

    /// Unit operation that lazy initializes its value when scheduled on an Executor
    /// - Note: lazy evaluated: It's not scheduled or evaluated on the given Executor, but on the calling one
    ///     (e.g. the thread where the Executable (sub)chain is instantiated)
    /// - SeeAlso: `Self.evaluate`
    /// - Parameter value: autoclosure that produces the value the Future (complete) event will contain
    /// - Returns: Executable<F> where F.Element is the element produced by the `value` block closure
    public static func unit<A>(_ value: @autoclosure @escaping () -> A) -> Executable<A> {
        return Executable<A> { _ in
            Future<A>.unit(block: value)
        }
    }

    /// Executable operation that schedules/forks a Callable<A>
    /// - Parameter block: closure to evaluate when the operation is run
    /// - Returns: Executable<F> where F.Element is the element produced by the `block` closure
    public static func evaluate<A>(_ block: @escaping Callable<A>) -> Executable<A> {
        return Executable<A> { exc in
            exc.run(block)
        }
    }
}

extension Executable {
    /// Map an Executable to new Executable transforming the F.Element self produced to F2.Element using the
    /// `transform` block.
    /// - Parameter transform: closure that transforms F.Element to F2.Element
    /// - Returns: Executable<E, F2> that allows for scheduling the mapping on an Executor
    public func map<B>(_ transform: @escaping Function<A, B>) -> Executable<B> {
        return flatMap { element in
            let mapped = try transform(element)
            return Executable.unit(mapped)
        }
    }

    /// Map an Executable to the given Executable by `transform` using the produced `A`
    /// - Parameter transform: closure that takes `A` and should return an `Executable<B>`
    /// - Returns: the Executable given by `transform`
    public func flatMap<B>(_ transform: @escaping Function<A, Executable<B>>) -> Executable<B> {
        return Executable<B> { exc in
            return self.operation(exc).map(transform).flatMap { executable in
                executable.operation(exc)
            }
        }
    }

    /// Schedule `self` Executable (and/or its sub-chain) for execution on the given Executor
    /// - Parameter executor: the executor to schedule `self.execute(on:)` on
    /// - Returns: Executable<A> that ignores its (down stream) passed in executor
    ///     and uses the executor given by this function
    public func schedule(on executor: ExecutorType) -> Executable<A> {
        return Executable<A> { callbackExecutor in
            return ForwardingFuture<A> { (callback: @escaping Consumer<FutureEvent<A>>) in
                _ = executor.run {
                    self.operation(executor).on { event in
                        _ = callbackExecutor.run { callback(event) }
                    }
                }
            }
        }
    }
}
