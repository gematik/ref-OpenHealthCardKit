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

import CardReaderProviderApi
import Foundation
import HealthCardAccess

public class SecureCardChannel: CardChannelType {
    private let channel: CardChannelType
    private let session: SecureMessaging

    public var card: CardType {
        return channel.card
    }

    public var channelNumber: Int {
        return channel.channelNumber
    }

    public var extendedLengthSupported: Bool {
        return channel.extendedLengthSupported
    }

    public var maxMessageLength: Int {
        return channel.maxMessageLength
    }

    public var maxResponseLength: Int {
        return channel.maxResponseLength
    }

    public init(session: SecureMessaging, card: HealthCardType) {
        self.session = session
        self.channel = card.currentCardChannel
    }

    public func transmit(command: CommandType, writeTimeout: TimeInterval, readTimeout: TimeInterval) throws ->
            ResponseType {
        let encryptedCommand = try session.encrypt(command: command)
        let encryptedResponse = try channel.transmit(command: encryptedCommand,
                                                     writeTimeout: writeTimeout,
                                                     readTimeout: readTimeout)
        return try session.decrypt(response: encryptedResponse)
    }

    public func close() throws {
        session.invalidate()
        try channel.close()
    }
}
