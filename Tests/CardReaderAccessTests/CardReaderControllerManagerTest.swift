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
