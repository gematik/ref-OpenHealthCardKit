//
//  ${GEMATIK_COPYRIGHT_STATEMENT}
//

import XCTest

#if !os(macOS) && !os(iOS)
/// Runs all tests in CardReaderProviderApi-swift.Tests.CardReaderAccessTests
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(CardReaderControllerManagerTest.allTests),
        testCase(SwiftReflectionTest.allTests)
    ]
}
#endif
