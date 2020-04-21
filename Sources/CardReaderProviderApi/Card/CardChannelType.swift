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
