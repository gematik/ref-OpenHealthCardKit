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

@testable import CardReaderProviderApi
import Nimble
import XCTest

public class TestReader: CardReaderType {
    public private(set) var cardPresent: Bool = false

    public func onCardPresenceChanged(_ block: @escaping (CardReaderType) -> Void) {
    }

    // swiftlint:disable unavailable_function
    public func connect(_ params: [String: Any]) throws -> CardType? {
        fatalError("connect() has not been implemented")
    }

    public private(set) var name: String = ""

    init(_ name: String) {
        self.name = name
    }
}

final class CardReaderTest: XCTestCase {
    func testDisplayNameDefault() {
        let reader = TestReader("Reader's name")

        expect(reader.name).to(equal(reader.displayName))
    }

    static var allTests = [
        ("testDisplayNameDefault", testDisplayNameDefault)
    ]
}
