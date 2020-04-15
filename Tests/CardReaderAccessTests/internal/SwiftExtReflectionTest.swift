//
//  ${GEMATIK_COPYRIGHT_STATEMENT}
//

@testable import CardReaderAccess
import Nimble
import XCTest

@objc protocol MyTestProtocol {
    init()
    func mustImplement() -> AnyObject
    static func mustStaticallyImplement() -> AnyObject
}

class MyProtocolImplementation: MyTestProtocol {
    required init() {
    }

    func mustImplement() -> AnyObject {
        return "mustImplement() has been implemented" as NSString
    }

    class func mustStaticallyImplement() -> AnyObject {
        return "mustStaticallyImplement() has been implemented" as NSString
    }
}

class MyNotProtocolImplementation {
    required init() {
    }

    func mustImplement() -> AnyObject? {
        return nil
    }

    class func mustStaticallyImplement() -> AnyObject? {
        return nil
    }
}

final class SwiftExtReflectionTest: XCTestCase {

    func test_loadClassesConformingToProtocol() {
        let classes = loadClassesConformingTo(protocol: MyTestProtocol.self)

        expect(classes.contains {
            type(of: $0) == type(of: MyProtocolImplementation.self)
        }).to(beTrue())

        expect(classes.contains {
            type(of: $0) == type(of: MyNotProtocolImplementation.self)
        }).to(beFalse())

        classes.compactMap { $0 as? MyTestProtocol.Type }
                .forEach { klazz in
                    expect(klazz.mustStaticallyImplement()).notTo(beNil())
                    expect(klazz.init().mustImplement()).notTo(beNil())
                }
    }

    static var allTests = [
        ("test_loadClassesConformingToProtocol", test_loadClassesConformingToProtocol)
    ]
}
