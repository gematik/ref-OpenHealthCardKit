//
//  ${GEMATIK_COPYRIGHT_STATEMENT}
//

import Foundation

/// SmartCard Application Protocol Data Unit - Response

public protocol ResponseType {
    /// Returns bytes in the response body. If this APDU has no body, this method returns nil
    var data: Data? { get }

    // swiftlint:disable identifier_name
    /// Returns the number of data bytes in the response body (Nr) or 0 if this APDU has no body.
    /// This call should be equivalent to <code>data.count</code>.
    var nr: Int { get }

    /// Returns the value of the status byte SW1 as a value between 0 and 255.
    var sw1: UInt8 { get }

    /// Returns the value of the status byte SW2 as a value between 0 and 255.
    var sw2: UInt8 { get }

    /// Returns the value of the status bytes SW1 and SW2 as a single status word SW.
    var sw: UInt16 { get }
}

/**
    `ResponseType` adheres to `Equatable`
*/
public func ==(lhs: ResponseType, rhs: ResponseType) -> Bool {
    //swiftlint:disable:previous operator_whitespace
    return lhs.data == rhs.data &&
            lhs.sw == rhs.sw
}
