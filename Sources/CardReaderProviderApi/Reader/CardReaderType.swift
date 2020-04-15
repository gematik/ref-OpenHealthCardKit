//
//  ${GEMATIK_COPYRIGHT_STATEMENT}
//

import Foundation

/// General card reader representation.
///
/// A card reader represents only one (logical) slot, when a CardReader supports multiple
/// cards at the same time it needs to provide a CardReaderType for each slot.
public protocol CardReaderType: class {
    /// CardReader name
    var name: String { get }

    /// Returns the system displayable name of this reader.
    var displayName: String { get }

    /// Whether there is a SmartCard present (mute or not) at the time of reading the property
    var cardPresent: Bool { get }

    /**
        Add an execution block for when a card is presented

        - Parameter block: Block that takes the CardReader as parameter
     */
    func onCardPresenceChanged(_ block: @escaping (CardReaderType) -> Void)

    /**
        Connect to the currently present SmartCard.

        - Parameter params: Map with arbitrary parameters that might be necessary to connect
                            the specific reader to a Card/Channel. E.g. NFC Card Reader

        - Throws: `CardError` when the connection could not be established

        - Returns: instance of the CardType that has been connected or nil on mute (there is a card inserted but no
                   communication with it is possible, e.g. it is inserted upside down)
     */
    func connect(_ params: [String: Any]) throws -> CardType?
}

extension CardReaderType {
    /// if there is no distinction necessary, displayName returns CardReader name per default
    public var displayName: String {
        return name
    }
}
