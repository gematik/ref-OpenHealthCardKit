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
import CoreNFC
import DataKit
import Foundation
import GemCommonsKit

class NFCCardChannel: CardChannelType {
    let maxMessageLength = 256
    let maxResponseLength = 256   // TODO: to be evaluated, CoreNFC should support extended length
    // swiftlint:disable:previous todo

    let channelNumber: Int
    var tag: NFCISO7816Tag?
    let extendedLengthSupported = true

    private let nfcCard: NFCCard

    init(card: NFCCard, tag: NFCISO7816Tag, channelNo: Int = 0) {
        self.nfcCard = card
        self.tag = tag
        self.channelNumber = channelNo
    }

    var card: CardType {
        return nfcCard
    }

    func transmit(command: CommandType, writeTimeout: TimeInterval, readTimeout: TimeInterval) throws -> ResponseType {
        let commandApdu: CommandType
        if channelNumber > 0 {
            commandApdu = try command.toLogicalChannel(channelNo: UInt8(channelNumber))
        } else {
            commandApdu = command
        }

        guard let tag = tag else {
            throw NFCCardReader.Error.noCardPresent.illegalState
        }

        let semaphore = DispatchSemaphore(value: 0)
        var error: Swift.Error?
        var sw1: UInt8 = 0
        var sw2: UInt8 = 0
        var data = Data()

        let apdu = NFCISO7816APDU(command: commandApdu)
        let sendHeader = Data([apdu.instructionClass] + [apdu.instructionCode] + [apdu.p1Parameter] + [apdu
                .p2Parameter]).hexString()

        DLog("SEND:     [\(sendHeader)\((apdu.data?.hexString() ?? ""))|ne:\(String(apdu.expectedResponseLength))]")

        tag.sendCommand(apdu: apdu) { lData, lSw1, lSw2, err in
            data = lData
            sw1 = lSw1
            sw2 = lSw2
            error = err
            semaphore.signal()
        }
        let timeoutTime = DispatchTime.now() + DispatchTimeInterval.seconds(Int(readTimeout))

        if case .timedOut = semaphore.wait(timeout: timeoutTime) {
            DLog("NFC send timed out [\(sendHeader)]")
            throw NFCCardReader.Error.sendTimeout.connectionError

        }
        if let error = error {
            throw error
        }
        DLog("RESPONSE: [\(Data(data + [sw1] + [sw2]).hexString())]")

        do {
            return try APDU.Response(body: data, sw1: sw1, sw2: sw2)
        } catch let error {
            throw CardError.connectionError(error)
        }
    }

    func close() throws {
        defer {
            tag = nil
        }
        guard tag != nil else {
            throw NFCCardReader.Error.transferException(name:
            "Basic channel cannot be closed or channel already closed").illegalState
        }
        guard channelNumber != 0 else {
            return // only logical channels can/should be closed
        }

        let manageChannelCommandClose = try APDU.Command(cla: 0x00, ins: 0x70, p1: 0x80, p2: 0x00)
                .toLogicalChannel(channelNo: UInt8(channelNumber))
        let responseSuccess = 0x9000

        let response = try transmit(command: manageChannelCommandClose, writeTimeout: 0, readTimeout: 0)
        if response.sw != responseSuccess {
            throw NFCCardReader.Error.transferException(name:
            String(format: "closing logical channel %d failed, response: 0x%04x", channelNumber, response.sw))
        }
    }
}
