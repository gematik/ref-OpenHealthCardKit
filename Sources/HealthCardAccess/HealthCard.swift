//
//  Copyright (c) 2023 gematik GmbH
//
//  Licensed under the Apache License, Version 2.0 (the License);
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an 'AS IS' BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import CardReaderProviderApi
import Foundation

/// HealthCard is the class that is used to bind the CardReaderProviderAPI channel to the HealthCardControl layer
public class HealthCard: HealthCardType {
    /// The current card channel to use to send/receive APDUs over
    public private(set) var currentCardChannel: CardChannelType

    private let card: CardType
    private var channels = [CardChannelType]()

    /// The status of the card and channel
    public private(set) var status: HealthCardStatus

    /**
        Initialize a HealthCard with a card channel and set its initial status

        - Parameters:
            - card: The associated Card
            - status: Initial status (default: .unknown)

        - Throws: `CardError` when opening the basic channel throws
     */
    public init(card: CardType, status: HealthCardStatus = .unknown) throws {
        self.card = card
        self.status = status
        currentCardChannel = try card.openBasicChannel()
    }

    /// The number of the current card channel.
    public var channelNumber: Int {
        currentCardChannel.channelNumber
    }

    /// Identify whether the current card channel supports APDU extended length commands/responses.
    public var extendedLengthSupported: Bool {
        currentCardChannel.extendedLengthSupported
    }

    /// Max length of a APDU body in bytes supported by the current card channel.
    public var maxMessageLength: Int {
        currentCardChannel.maxMessageLength
    }

    /// Max length of a APDU response supported by the current card channel.
    public var maxResponseLength: Int {
        currentCardChannel.maxResponseLength
    }
}
