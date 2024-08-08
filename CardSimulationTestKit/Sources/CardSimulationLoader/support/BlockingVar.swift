//
//  Copyright (c) 2022 gematik GmbH
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
import OSLog

/**
    BlockingVar blocks the [value.get] call until the [value.set] has set the value.

    Note: be aware of blocking the main-thread when the getter is
    invoked from the main-thread.
 */
class BlockingVar<T> {
    private enum State: Int {
        case empty = 0
        case fulfilled
    }

    private var _value: T!
    private let lock: NSConditionLock

    /// Initialize w/o value
     init() {
        lock = NSConditionLock(condition: State.empty.rawValue)
    }

    /// Initialize w/ value value
     init(_ value: T) {
        _value = value
        lock = NSConditionLock(condition: State.fulfilled.rawValue)
    }

    /// Access value
     var value: T {
        get {
            if Thread.isMainThread {
                // wait for self.isFulfilled
                while !isFulfilled {
                    Logger.cardSimulationLoader.info("Caution: trying to obtain a lock on the main thread")
                    RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.001))
                }
            }
            /// Obtain a lock when the condition is fulfilled. This may seem counter intuitive since,
            /// we want to wait/lock while empty and continue when fulfilled.
            /// So what lock(whenCondition:) actually does, is waiting/blocking execution until the lock
            /// unlocks with fulfilled. Then and only then the lock can be obtained and execution resumed.
            lock.lock(whenCondition: State.fulfilled.rawValue)
            defer {
                /// Of course we unlock the lock so consecutive calls make it through as well.
                lock.unlock(withCondition: State.fulfilled.rawValue)
            }
            return _value
        }
        set {
            /// Obtain a lock before writing the value
            lock.lock()
            _value = newValue
            /// Unlock stating that we have fulfilled the value
            lock.unlock(withCondition: State.fulfilled.rawValue)
        }
    }

    /// Non-blocking check whether self has been fulfilled or not
    /// - Returns: `true` on .fulfilled `false` when .empty
    var isFulfilled: Bool {
        return lock.condition == State.fulfilled.rawValue
    }
}
