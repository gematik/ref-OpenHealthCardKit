//
//  ${GEMATIK_COPYRIGHT_STATEMENT}
//

@testable import CardReaderAccess
import CardReaderProviderApi
import Nimble
import XCTest

final class CardReaderControllerManagerTest: XCTestCase {

    class MyTestImplementation: CardReaderProviderType {
        // swiftlint:disable:next unavailable_function
        class func provideCardReaderController() -> CardReaderControllerObjcWrapper {
            fatalError("provideCardReaderController() should not be called, since we are expecting lazy loading")
        }

        static let descriptor: ProviderDescriptorType = ProviderDescriptor(
                    "Test",
                    "Gematik 2019",
                    "No description",
                    "No short description either",
                    "No-name")

    }

    class MyTestImplementation2: CardReaderProviderType {
        class func provideCardReaderController() -> CardReaderControllerObjcWrapper {
            return CardReaderControllerObjcWrapper(MyTestCardReaderImplementation())
        }

        static let descriptor: ProviderDescriptorType = ProviderDescriptor(
                "Test",
                "Gematik 2019",
                "No description",
                "No short description either",
                "No-name")

    }

    func test_CardReaderControllerManager_shared() {
        let manager = CardReaderControllerManager.shared
        let manager2 = CardReaderControllerManager.shared

        expect(manager).notTo(beNil())
        expect(manager).to(beIdenticalTo(manager2))
    }

    class MyTestCardReaderImplementation: CardReaderControllerType {
        private(set) var name: String = "test-cardreader"
        private(set) var cardReaders: [CardReaderType] = []

        func add(delegate: CardReaderControllerDelegate) {
        }

        func remove(delegate: CardReaderControllerDelegate) {
        }
    }

    func test_CardReaderControllerManager_cardReaderControllers() {
        let providers: [CardReaderProviderType.Type] = [MyTestImplementation2.self]
        let manager = CardReaderControllerManager(providers)
        expect(manager.cardReaderControllers.count).to(beGreaterThan(0))
    }

    static var allTests = [
        ("test_CardReaderControllerManager_shared", test_CardReaderControllerManager_shared),
        ("test_CardReaderControllerManager_cardReaderControllers",
                test_CardReaderControllerManager_cardReaderControllers)
    ]
}
