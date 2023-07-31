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
import GemCommonsKit
import HealthCardAccess
import Helper

internal class SecureCardChannel: CardChannelType {
    private let channel: CardChannelType
    private let session: SecureMessaging

    var card: CardType {
        channel.card
    }

    var channelNumber: Int {
        channel.channelNumber
    }

    var extendedLengthSupported: Bool {
        channel.extendedLengthSupported
    }

    var maxMessageLength: Int {
        channel.maxMessageLength
    }

    var maxResponseLength: Int {
        channel.maxResponseLength
    }

    init(session: SecureMessaging, card: HealthCardType) {
        self.session = session
        channel = card.currentCardChannel
    }

    func transmit(command: CommandType, writeTimeout: TimeInterval, readTimeout: TimeInterval) throws -> ResponseType {
        DLog(">> \(command.bytes.hexString())")
        // we only log the header bytes to prevent logging user's PIN
        CommandLogger.commands.append(
            Command(message: ">> \(command.bytes.prefix(4).hexString())", type: .sendSecureChannel)
        )
        let encryptedCommand = try session.encrypt(command: command)
        let encryptedResponse = try channel.transmit(command: encryptedCommand,
                                                     writeTimeout: writeTimeout,
                                                     readTimeout: readTimeout)
        let decryptedAPDU = try session.decrypt(response: encryptedResponse)
        DLog("<< \(decryptedAPDU.sw.hexString()) | [\(decryptedAPDU.data?.hexString() ?? "")]")
        CommandLogger.commands.append(
            Command(
                message: "<< \(decryptedAPDU.sw.hexString())",
                type: .responseSecureChannel
            )
        )
        return decryptedAPDU
    }

    func close() throws {
        session.invalidate()
        try channel.close()
    }
}

extension UInt16 {
    func hexString(separator: String = "") -> String {
        Data([UInt8(self >> 8 & 0xFF), UInt8(self & 0xFF)]).hexString(separator: separator)
    }
}
