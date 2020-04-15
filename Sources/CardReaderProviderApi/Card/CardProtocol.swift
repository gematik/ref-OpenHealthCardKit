//
//  ${GEMATIK_COPYRIGHT_STATEMENT}
//

import Foundation

/// SmartCard comms protocol representation
public struct CardProtocol: OptionSet {
    /// Bitmask encoded protocols
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    // swiftlint:disable identifier_name
    /// T=0 protocol
    public static let t0 = CardProtocol(rawValue: 1 << 0)
    /// T=1 protocol
    public static let t1 = CardProtocol(rawValue: 1 << 1)
    /// T=15 protocol
    public static let t15 = CardProtocol(rawValue: 1 << 2)
    /// T=* protocol
    public static let any = CardProtocol(rawValue: 1 << 3)
    // swiftlint:enable identifier_name
}
