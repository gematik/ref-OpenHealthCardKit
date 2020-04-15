//
//  ${GEMATIK_COPYRIGHT_STATEMENT}
//

import XCTest

#if !os(macOS) && !os(iOS)
/// Run all tests in CardReaderProviderApiTests
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(APDUResponseTest.allTests),
        testCase(APDUCommandTest.allTests)
    ]
}
#endif
