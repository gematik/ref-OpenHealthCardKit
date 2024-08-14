//
//  Copyright (c) 2024 gematik GmbH
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

import Foundation

/**
    Thread-Safe variable wrapper.

    Makes sure the get and set are happening synchronously by using
    a Mutex for reader/writing to the wrapped value
 */
class SynchronizedVar<T> {
    private var _value: T
    private let mutex = NSRecursiveLock()

    /// Canonical constructor
    init(_ value: T) {
        _value = value
    }

    /**
        Get/Set the value for this SynchronizedVar in a
        thread-safe (blocking) manner
     */
    var value: T {
        mutex.lock()
        defer {
            mutex.unlock()
        }
        return _value
    }

    /// Set a new value in a transaction to make sure there is no potential 'gap' between get and consecutive set
    ///
    /// - Parameter block: the transaction that gets the oldValue and must return the newValue that will be stored
    ///                    in the backing value.
    func set(transaction block: @escaping (T) -> T) {
        mutex.lock()
        _value = block(_value)
        mutex.unlock()
    }
}
