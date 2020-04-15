//
//  ${GEMATIK_COPYRIGHT_STATEMENT}
//

import Foundation

/// Helper functions for loading ObjC Runtime classes

/**
    Find all classes in the current Runtime environment that conform to a specific protocol.

    - note: The protocol needs to be annotated with `@objc` else it won't appear in the returned array.

    - Parameter protocol: The protocol that needs to be conformed to.

    - Returns: All found classes in the current Runtime that conform to the given protocol.
 */
internal func loadClassesConformingTo(protocol: Protocol) -> [AnyClass] {
    return load_objc_ClassList()
            .filter {
                class_conformsToProtocol($0, `protocol`)
            }
}

/// proxy for objc_getClassList()
private func load_objc_ClassList() -> [AnyClass] {
    var count = UInt32(0)
    guard let classList = objc_copyClassList(&count) else {
        return []
    }

    return convert(length: Int(count), data: classList, AnyClass.self)
}

/// Convert UnsafePointer to Swift Array
private func convert<T, P>(length: Int, data: UnsafePointer<P>, _: T.Type) -> [T] {
    let pSize = MemoryLayout<P>.stride
    let tSize = MemoryLayout<T>.stride
    let numItems = (length * pSize) / tSize
    let buffer = data.withMemoryRebound(to: T.self, capacity: numItems) {
        UnsafeBufferPointer(start: $0, count: numItems)
    }
    return Array(buffer)
}
