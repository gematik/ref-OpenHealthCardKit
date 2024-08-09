//
//  Copyright (c) 2023 gematik GmbH
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

import CardReaderProviderApi
import CardSimulationLoader
import Foundation

public class SimulatorCardReaderController: CardReaderControllerType {
    public let name = SimulatorCardReaderProvider.name

    private let simulationManager: SimulationManagerType
    private let cardReaderDelegates = WeakArray<CardReaderControllerDelegate>()
    private var simulatorCardReaders = [SimulatorCardReader]()

    init(manager: SimulationManagerType) {
        simulationManager = manager

        simulationManager.register(delegate: self)
    }

    deinit {
        simulationManager.deregister(delegate: self)
    }

    public var cardReaders: [CardReaderType] {
        simulatorCardReaders.map { $0 }
    }

    public func add(delegate: CardReaderControllerDelegate) {
        if cardReaderDelegates.index(of: delegate) == nil {
            cardReaderDelegates.add(object: delegate)
            simulatorCardReaders.forEach { cardReader in
                delegate.cardReader(controller: self, didConnect: cardReader)
            }
        }
    }

    public func remove(delegate: CardReaderControllerDelegate) {
        guard let index = cardReaderDelegates.index(of: delegate) else {
            return
        }
        cardReaderDelegates.removeObject(at: index)
    }
}

extension SimulatorCardReaderController: SimulationManagerDelegate {
    public func simulation(manager _: SimulationManagerType, didStart simulator: SimulationRunnerType) {
        let cardReader = SimulatorCardReader(cardReader: simulator)
        simulatorCardReaders.append(cardReader)
        cardReaderDelegates.array.forEach {
            $0.cardReader(controller: self, didConnect: cardReader)
        }
    }

    public func simulation(manager _: SimulationManagerType, didEnd simulator: SimulationRunnerType) {
        let predicate: (SimulatorCardReader) -> Bool = { cardReader in cardReader.simulationRunner === simulator }
        if let cardReader = simulatorCardReaders.first(where: predicate) {
            cardReaderDelegates.array.forEach { delegate in
                delegate.cardReader(controller: self, didDisconnect: cardReader)
            }
        }
        simulatorCardReaders.removeAll {
            $0.simulationRunner === simulator
        }
    }
}

/// A Collection similar to an array, but wraps its Elements in a `WeakRef`.
class WeakArray<T: Any> {
    private var _array = [WeakRef<AnyObject>]()

    /// Initialize an empty WeakArray
    init() {}

    /// Add an object reference to the array
    /// - Parameter object: the object to weak reference before adding it to the array
    func add(object: T) {
        let ref = makePointer(object)
        _array.append(ref)
    }

    /// Dereference the object at index when not released
    /// - Parameter index: index to get
    /// - Returns: The object when not deinitialized
    func object(at index: Int) -> T? {
        guard index < count, let pointer = _array[index].value else {
            return nil
        }
        guard let object = pointer as? T else {
            return nil
        }
        return object
    }

    /// Insert an object reference at a specified index
    /// - Parameters:
    ///     - object: the object to weak reference before adding it to the array
    ///     - index: the index to insert at
    func insert(object: T, at index: Int) {
        guard index < count else {
            return
        }
        _array.insert(makePointer(object), at: index)
    }

    /// Replace a weak reference with a new object
    /// - Parameters:
    ///     - index: the index to replace
    ///     - object: the object to weak reference before replacing the reference at index
    func replaceObject(at index: Int, with object: T) {
        guard index < count else {
            return
        }
        _array[index] = makePointer(object)
    }

    /// Remove an object reference at a specified index
    /// - Parameter index: index of the reference to remove
    func removeObject(at index: Int) {
        guard index < count else {
            return
        }
        _array.remove(at: index)
    }

    /// Get the current count of available (not-released) object references
    /// - Note: complexity O(n) - since we filter out the zeroed `WeakRef`s
    /// - Returns: the current active reference count
    var count: Int {
        _array = _array.filter { $0.value != nil }
        return _array.count
    }

    /// Dereference the object at index when not released
    /// - Parameter index: index to get
    /// - See: object(at:)
    /// - Returns: The object when not deinitialized
    subscript(index: Int) -> T? {
        object(at: index)
    }

    /// Find the index of an object in the array
    /// - Parameter object: the object to search for
    /// - Note: complexity O(2n)
    /// - Returns: the index when found else nil
    func index(of object: T) -> Int? {
        let anyObject = object as AnyObject
        for index in 0 ..< count {
            if let current = self[index] as AnyObject?, current === anyObject {
                return index
            }
        }
        return nil
    }
}

private func makePointer(_ object: Any) -> WeakRef<AnyObject> {
    let strongObject = object as AnyObject
    let ref = WeakRef(strongObject)
    return ref
}

extension WeakArray {
    /// Convenience initializer for weak referencing an entire array
    /// - Parameter objects: the object to weak reference in the newly initialized WeakArray
    convenience init(objects: [T]) {
        self.init()
        objects.forEach {
            add(object: $0)
        }
    }

    /// Get objects referenced by `Self` as a strong array
    /// - Returns: Array with available objects
    var array: [T] {
        _array.compactMap {
            $0.value as? T
        }
    }
}

extension Array where Element: AnyObject {
    /// Create a WeakArray with elements from `Self`
    /// - Returns: WeakArray with references to all Elements in `Self`
    var weakArray: WeakArray<Element> {
        WeakArray(objects: self)
    }
}

/// Swift object that holds a weak reference to an Object like its Java counter-part WeakReference.
class WeakRef<T: AnyObject> {
    /// The weak referenced object
    private(set) weak var value: T?

    /// Initialize a weak reference.
    /// - Parameter obj: the object to weak reference
    required init(_ obj: T) {
        value = obj
    }
}
