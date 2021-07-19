//
//  Copyright (c) 2021 gematik GmbH
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

import ASN1Kit
import CardReaderProviderApi
import Foundation

extension CommandType {
    var isPaceKeyEncrypted: Bool {
        cla & 0x0F == 0xC
    }
}

/// Class representing a AES128PACE key holding a encryption secret and a MAC secret.
class AES128PaceKey: SecureMessaging {
    private var enc: Data
    internal private(set) var mac: Data

    var secureMessagingSsc: Data

    static let blockSize = 16
    // ISO/IEC 7816-4 padding tag
    static let paddingDelimiter: UInt8 = 0x80

    /// Initializer for PACE key
    /// - Parameters:
    ///     - enc: Data representing the key agreed on
    ///     - mac: Data representing the MAC agreed on
    init(enc: Data, mac: Data) {
        self.enc = enc
        self.mac = mac

        secureMessagingSsc = Data(count: 16)
    }

    func encrypt(command: CommandType) throws -> CommandType {
        secureMessagingSsc = AES128PaceKey.incrementSsc(ssc: secureMessagingSsc)
        let encryptedMessage = try AES128PaceKey.encrypt(
                command: command,
                enc: enc,
                mac: mac,
                ssc: secureMessagingSsc
        )
        secureMessagingSsc = AES128PaceKey.incrementSsc(ssc: secureMessagingSsc)
        return encryptedMessage
    }

    func decrypt(response: ResponseType) throws -> ResponseType {
        guard let data = response.data,
              data.count >= 10 else {
            throw Error.encryptedResponseMalformed
        }
        return try AES128PaceKey.decrypt(response: response, enc: enc, mac: mac, ssc: secureMessagingSsc)
    }

    func invalidate() {
        enc = Data(repeating: 0x0, count: enc.count)
        mac = Data(repeating: 0x0, count: mac.count)
        secureMessagingSsc = Data(repeating: 0x0, count: secureMessagingSsc.count)
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    private static func encrypt(command: CommandType, enc: Data, mac: Data, ssc: Data) throws -> CommandType {
        if command.isPaceKeyEncrypted {
            throw Error.apduAlreadyEncrypted
        }

        var header = Data([command.cla, command.ins, command.p1, command.p2])

        let dataObject: Data
        if let data = command.data {
            // gemSpec_COS#N032.300
            // use CBC mode here instead of specified ECB mode, since only one block has to be encrypted
            let initVector = try AES.CBC128.encrypt(data: ssc, key: enc)
            let paddedData = data.addPadding()
            let paddedDataEncrypted = try AES.CBC128.encrypt(data: paddedData, key: enc, initVector: initVector)
            dataObject = try create(tag: .taggedTag(7), data: .primitive([0x1] + paddedDataEncrypted)).serialize()
        } else {
            dataObject = Data()
        }

        let lengthObject: Data
        if let le = command.ne { // swiftlint:disable:this identifier_name
            let leValue: Data
            if le == 0x100 {
                leValue = Data([0x0])
            } else if le == 0x10000 {
                leValue = Data([0x0, 0x0])
            } else if le > 0x100 {
                leValue = Data([UInt8(le >> 8) & 0xFF, UInt8(le & 0xFF)])
            } else {
                leValue = Data([UInt8(le & 0xFF)])
            }
            lengthObject = try create(tag: .taggedTag(0x17), data: .primitive(leValue)).serialize()
        } else {
            lengthObject = Data()
        }

        // [REQ:gemSpec_COS:N032.500] Indicate Secure Messaging (Caution: we assume CLA in [0,3]!)
        header[0] |= 0x0C

        // [REQ:gemSpec_COS:N032.800] Calculate MAC
        let calculatedMac: Data
        let tmpData = dataObject + lengthObject
        if tmpData.isEmpty {
            calculatedMac = try AES128PaceKey.calculateMac(key: mac, ssc: ssc, macIn: header)
        } else {
            let padHeader = header.addPadding()
            calculatedMac = try AES128PaceKey.calculateMac(key: mac, ssc: ssc, macIn: padHeader + tmpData)
        }

        // [REQ:gemSpec_COS:N032.900] Build APDU
        let mDo = try create(tag: .taggedTag(0xE), data: .primitive(calculatedMac)).serialize()

        // [REQ:gemSpec_COS:N033.000]
        let newD = tmpData + mDo

        let setLe: Int
        // [REQ:gemSpec_COS:N033.100,N033.200,N033.300,N033.400]
        switch (command.data, command.ne) {
        case (nil, nil): setLe = APDU.expectedLengthWildcardShort
        case (nil, _): setLe = APDU.expectedLengthWildcardExtended
        case (_, nil):
            if newD.count <= 255 {
                setLe = APDU.expectedLengthWildcardShort
            } else {
                setLe = APDU.expectedLengthWildcardExtended
            }
        case (_, _): setLe = APDU.expectedLengthWildcardExtended
        }

        return try APDU.Command(cla: header[0], ins: header[1], p1: header[2], p2: header[3], data: newD, ne: setLe)
    }

    private static func decrypt(response: ResponseType, enc: Data, mac: Data, ssc: Data) throws -> ResponseType {
        /**
             Read APDU structure - gemSpec_COS#13.3
             Case 1: DO99|DO8E|SW1SW2
             Case 2: DO87|DO99|DO8E|SW1SW2
             Case 3: DO99|DO8E|SW1SW2
             Case 4: DO87|DO99|DO8E|SW1SW2
         */
        guard let responseData = response.data,
              responseData.count >= 14 else {
            throw Error.encryptedResponseMalformed
        }

        let tagData = Data(responseData[(responseData.count - 10)...])
        let protectedData = Data(responseData[0 ..< (responseData.count - 10)])

        // Read mac (required)
        guard let tag = try? ASN1Decoder.decode(asn1: tagData),
              tag.tagNo == 0xE,
              tag.length == 8,
              let macBytes = tag.data.primitive else {
            throw Error.encryptedResponseMalformed
        }

        // Calculate mac for verification
        let calculatedMac = try AES128PaceKey.calculateMac(key: mac, ssc: ssc, macIn: protectedData)
        if macBytes != calculatedMac {
            throw Error.secureMessagingMacVerificationFailed
        }

        // Read processing status (required)
        let statusData = Data(protectedData[(protectedData.count - 4)...])
        guard let status = try? ASN1Decoder.decode(asn1: statusData),
              status.tagNo == 0x19,
              status.length == 2,
              let statusBytes = status.data.primitive else {
            throw Error.encryptedResponseMalformed
        }

        // Decrypt data
        let messageData = protectedData[0 ..< protectedData.count - 4]
        if !messageData.isEmpty {
            guard let messageBody = try? ASN1Decoder.decode(asn1: messageData),
                  messageBody.length > 0,
                  let messageBodyData = messageBody.data.primitive else {
                throw Error.encryptedResponseMalformed
            }
            if messageBody.tagNo == 0x7 {
                // Encrypted data - N033.800
                let initVector = try AES.CBC128.encrypt(data: ssc, key: enc)
                let paddedDecryptedData =
                        try AES.CBC128.decrypt(data: messageBodyData[1...], key: enc, initVector: initVector)
                let decryptedData = paddedDecryptedData.removePadding()
                return try APDU.Response(apdu: decryptedData + statusBytes)
            } else if messageBody.tagNo == 0x1 {
                // Data not encrypted - N033.600
                return try APDU.Response(apdu: messageBodyData + statusBytes)
            } else {
                throw Error.encryptedResponseMalformed
            }
        } else {
            return try APDU.Response(apdu: statusBytes)
        }
    }

    private static func calculateMac(key: Data, ssc: Data, macIn: Data) throws -> Data {
        let sscNormalized = ssc.normalize(to: AES128PaceKey.blockSize, paddingIndicator: 0x0)
        let macInPadded = macIn.addPadding()
        let cmac = try AES.CMAC(key: key, data: sscNormalized + macInPadded)
        return cmac.prefix(8)
    }

    /// Increment the Send Sequence Counter (SSC).
    /// - Parameter:
    ///     - ssc: the Send Sequence Counter to increment
    /// - Returns: the incremented Send Sequence Counter
    static func incrementSsc(ssc: Data) -> Data {
        var result = Data(count: ssc.count)
        var temp: UInt8

        for index in stride(from: ssc.count - 1, through: 0, by: -1) {
            temp = ssc[index]
            if temp == 0xFF {
                result[index] = 0
            } else {
                result[index] = temp + 1
                break
            }
        }
        return result
    }
}

extension Data {
    // ISO/IEC 7816-4 padding functions
    fileprivate func addPadding(_ delimiter: UInt8 = AES128PaceKey.paddingDelimiter,
                                blockSize: Int = AES128PaceKey.blockSize) -> Data {
        var padded = self + Data(repeating: 0x0, count: blockSize - count % blockSize)
        assert(padded.count % blockSize == 0)
        assert(padded.count >= count)
        padded[count] = delimiter
        return padded
    }

    fileprivate func removePadding(afterLast delimiter: UInt8 = AES128PaceKey.paddingDelimiter) -> Data {
        let result: Data
        if let lastIndex = lastIndex(of: delimiter) {
            result = self[0 ..< lastIndex]
        } else {
            result = Data()
        }
        return result
    }
}

extension AES128PaceKey {
    enum Error: Swift.Error {
        case apduAlreadyEncrypted
        case encryptedResponseMalformed
        case secureMessagingMacVerificationFailed
    }
}
