//
//  ${GEMATIK_COPYRIGHT_STATEMENT}
//

import Foundation

/// General card communications protocol
public protocol CardChannelType {
    /// The associated card with this channel
    /// Note: implementers may choose to hold a weak reference
    var card: CardType { get }

    /// The channel number
    var channelNumber: Int { get }

    /// Identify whether a channel supports APDU extended length commands/responses
    var extendedLengthSupported: Bool { get }

    /// Max length of APDU body in bytes.
    /// - Note: HealthCards COS typically support up to max 4096 byte body-length
    var maxMessageLength: Int { get }

    /// Max length of a APDU response.
    var maxResponseLength: Int { get }

    /**
        Transceive a (APDU) command

        - Parameters:
            - command: the prepared command
            - writeTimeout: the max waiting time in seconds before the first byte should have been sent.
                            (<= 0 = no timeout)
            - readTimeout: the max waiting time in seconds before the first byte should have been received.
                            (<= 0 = no timeout)

        - Throws: `CardError` when transmitting and/or receiving the response failed

        - Returns: the Command APDU Response or CardError on failure
    */
    func transmit(command: CommandType, writeTimeout: TimeInterval, readTimeout: TimeInterval) throws -> ResponseType

    /**
        Close the channel for subsequent actions.

        - Throws `CardError`
     */
    func close() throws
}
