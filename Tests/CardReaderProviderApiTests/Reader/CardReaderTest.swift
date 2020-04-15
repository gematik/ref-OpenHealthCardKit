//
//  ${GEMATIK_COPYRIGHT_STATEMENT}
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
