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

/// Event cases for Future result
public enum FutureEvent<T> {
    /// FutureEvent can fail with a Swift Error or because it was cancelled
    public enum Error: Swift.Error {
        /// Indicate a Future was cancelled before completion
        case cancelled
        /// Indicate a Future could not be completed due to an exception/Error
        case error(Swift.Error)
        /// Indicate a Future timed out
        case timeout

        /// Convenience for folding over a FutureEvent
        func fold<B>(_ onCancelled: () -> B, _ onTimeout: () -> B, _ onError: (Swift.Error) -> B) -> B {
            switch self {
            case .cancelled: return onCancelled()
            case .timeout: return onTimeout()
            case .error(let error): return onError(error)
            }
        }
    }

    /// Indicate a Future has completed with an Element of type T
    case completed(T)
    /// Indicate a Future could not complete due to `FutureEvent.Error`
    case failed(Error)

    static func cancelled<T>() -> FutureEvent<T> {
        return .failed(.cancelled)
    }

    static func timedOut<T>() -> FutureEvent<T> {
        return .failed(.timeout)
    }

    static func error<T>(from error: Swift.Error) -> FutureEvent<T> {
        if let futureError = error as? FutureEvent<T>.Error {
            return .failed(futureError)
        }
        return .failed(.error(error))
    }
}

extension FutureEvent {
    /// Fold FutureEvent
    /// - Parameters:
    ///     - onComplete: block to execute when event is .completed
    ///     - onCancelled: block to execute when event is .failed(.cancelled)
    ///     - onError: block to execute when event is .failed(.error) and/or when onComplete throws
    /// - Returns: the given `B`
    public func fold<B>(
            onComplete: @escaping Function<T, B>,
            onCancelled: @escaping () -> B,
            onTimedOut: @escaping () -> B,
            onError: @escaping (Swift.Error) -> B
    ) -> B {
        switch self {
        case .completed(let value): do {
            return try onComplete(value)
        } catch let error {
            return onError(error)
        }
        case .failed(let error): return error.fold(onCancelled, onTimedOut, onError)
        }
    }

    /// Map (transform) the event value
    /// - Parameter transform: the block to transform a completed event with
    /// - Returns: transformed `FutureEvent<B>`
    public func map<B>(_ transform: @escaping Function<T, B>) -> FutureEvent<B> {
        return flatMap { value in
            .completed(try transform(value))
        }
    }

    /// FlatMap (transform) the event
    /// - Parameter transform: the block that transforms a value to a FutureEvent<B>
    /// - Returns: the transformed `FutureEvent<B>` on .completed or forwarded .failed case
    public func flatMap<B>(_ transform: @escaping Function<T, FutureEvent<B>>) -> FutureEvent<B> {
        return fold(
                onComplete: transform,
                onCancelled: { .failed(.cancelled) },
                onTimedOut: { .failed(.timeout) },
                onError: { error in .failed(.error(error)) }
        )
    }

    /// Get the `.completed` value or the provided one when `.failed`
    /// - Parameter block: the closure to provide T in case `self` is not .completed
    /// - Returns: the completed value or provided by closure
    public func get(orElse block: @escaping @autoclosure () -> T) -> T {
        return fold(onComplete: { $0 }, onCancelled: block, onTimedOut: block, onError: { _ in block() })
    }
}

extension FutureEvent {
    /// Convenience value getter
    /// - Return: value T or nil when not completed
    public var value: T? {
        return fold(onComplete: { $0 }, onCancelled: { nil }, onTimedOut: { nil }, onError: { _ in nil })
    }

    /// Convenience error getter
    /// - Return: error or nil when completed or cancelled
    public var error: Swift.Error? {
        return fold(onComplete: { _ in nil }, onCancelled: { nil }, onTimedOut: { nil }, onError: { $0 })
    }

    /// Convenience cancelled state getter
    /// - Return: `true` when cancelled
    public var cancelled: Bool {
        return fold(onComplete: { _ in false }, onCancelled: { true }, onTimedOut: { false }, onError: { _ in false })
    }

    /// Convenience timeout state getter
    /// - Return: `true` when timed-out
    public var timedOut: Bool {
        return fold(onComplete: { _ in false }, onCancelled: { false }, onTimedOut: { true }, onError: { _ in false })
    }

    /// Convenience for getting the `.failed` case value
    var failure: FutureEvent.Error? {
        if case .failed(let error) = self {
            return error
        } else {
            return nil
        }
    }
}
