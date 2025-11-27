//
// Copyright (Change Date see Readme), gematik GmbH
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// *******
//
// For additional notes and disclaimer from gematik and in case of changes by gematik find details in the "Readme" file.
//

#if os(iOS)

import CardReaderProviderApi
import CoreNFC
import Foundation
import HealthCardAccess
import OSLog

public class NFCCard: CardType {
    var tag: NFCISO7816Tag?
    private weak var basicChannel: NFCCardChannel?

    public init(isoTag tag: NFCISO7816Tag) {
        self.tag = tag
    }

    public var atr: ATR {
        tag?.historicalBytes ?? Data()
    }

    public var `protocol`: CardProtocol {
        .t1
    }

    public func openBasicChannel() throws -> CardChannelType {
        if let channel = basicChannel {
            return channel
        }
        guard let tag = tag else {
            throw NFCCardError.noCardPresent.illegalState
        }
        let nfcChannel = NFCCardChannel(card: self, tag: tag)
        basicChannel = nfcChannel
        return nfcChannel
    }

    public func openLogicChannel() throws -> CardChannelType {
        guard let tag = tag else {
            throw NFCCardError.noCardPresent.illegalState
        }

        let manageChannelCommandOpen = try APDU.Command(cla: 0x00, ins: 0x70, p1: 0x00, p2: 0x00, ne: 0x01)
        let responseSuccess = 0x9000

        let response = try openBasicChannel()
            .transmitPublisher(command: manageChannelCommandOpen, writeTimeout: 0, readTimeout: 0)
        guard response.sw == responseSuccess else {
            throw NFCCardError.transferException(
                name: String(format: "openLogicalChannel failed, response code: 0x%04x", response.sw)
            )
        }
        guard let rspData = response.data else {
            throw NFCCardError.transferException(
                name: String(format: "openLogicalChannel failed, no channel number received")
            )
        }
        return NFCCardChannel(card: self, tag: tag, channelNo: Int(rspData[0]))
    }

    public func openLogicChannelAsync() async throws -> CardChannelType {
        guard let tag = tag else {
            throw NFCCardError.noCardPresent.illegalState
        }

        let manageChannelCommandOpen = try APDU.Command(cla: 0x00, ins: 0x70, p1: 0x00, p2: 0x00, ne: 0x01)
        let responseSuccess = 0x9000

        let response = try await openBasicChannel()
            .transmitAsync(command: manageChannelCommandOpen, writeTimeout: 0, readTimeout: 0)
        guard response.sw == responseSuccess else {
            throw NFCCardError.transferException(
                name: String(format: "openLogicalChannel failed, response code: 0x%04x", response.sw)
            )
        }
        guard let rspData = response.data else {
            throw NFCCardError.transferException(
                name: String(format: "openLogicalChannel failed, no channel number received")
            )
        }
        return NFCCardChannel(card: self, tag: tag, channelNo: Int(rspData[0]))
    }

    public func initialApplicationIdentifier() throws -> Data? {
        guard let initialSelectedAID = tag?.initialSelectedAID else {
            Logger.nfcCardReaderProvider.fault("NFC tag could not deliver initialSelectedAID when expected")
            return nil
        }
        return try Data(hex: initialSelectedAID)
    }

    public func disconnect(reset _: Bool) throws {
        Logger.nfcCardReaderProvider.debug("Disconnecting card ...")
        tag = nil
        basicChannel = nil
        Logger.nfcCardReaderProvider.debug("Card disconnected")
    }

    deinit {
        do {
            try disconnect(reset: false)
        } catch {
            Logger.nfcCardReaderProvider.fault("Error while disconnecting: \(error)")
        }
    }

    public var description: String {
        "NFCCard"
    }
}

#endif
