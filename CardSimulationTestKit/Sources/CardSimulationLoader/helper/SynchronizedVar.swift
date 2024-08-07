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
