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

import ASN1Kit
import CardReaderProviderApi
import Foundation

extension CommandType {
    var isPaceKeyEncrypted: Bool {
        return self.cla & 0x0f == 0xc
    }
}

/// Class representing a AES128PACE key holding a encryption secret and a MAC secret.
class AES128PaceKey: SecureMessaging {
    private var enc: Data
    internal private(set) var mac: Data

    var secureMessagingSsc: Data

    static let blockSize = 16
    // ISO/IEC 7816-4 padding tag
    private static let pad: UInt8 = 0x80

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
                enc: self.enc,
                mac: self.mac,
                ssc: self.secureMessagingSsc
        )
        secureMessagingSsc = AES128PaceKey.incrementSsc(ssc: secureMessagingSsc)
        return encryptedMessage
    }

    func decrypt(response: ResponseType) throws -> ResponseType {
        guard let data = response.data,
              data.count >= 10 else {
            throw Error.encryptedResponseMalformed
        }
        return try AES128PaceKey.decrypt(response: response, enc: self.enc, mac: self.mac, ssc: self.secureMessagingSsc)
    }

    func invalidate() {
        self.enc = Data(repeating: 0x0, count: self.enc.count)
        self.mac = Data(repeating: 0x0, count: self.mac.count)
        self.secureMessagingSsc = Data(repeating: 0x0, count: self.secureMessagingSsc.count)
    }

    // swiftlint:disable:next function_body_length
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
            let paddedData = AES128PaceKey.pad(data: data, blockSize: AES128PaceKey.blockSize)
            let paddedDataEncrypted = try AES.CBC128.encrypt(data: paddedData, key: enc, initVector: initVector)
            dataObject = try create(tag: .taggedTag(7), data: .primitive([0x1] + paddedDataEncrypted)).serialize()
        } else {
            dataObject = Data()
        }

        let lengthObject: Data
        if let le = command.ne { //swiftlint:disable:this identifier_name
            let leValue: Data
            if le == 0x100 {
                leValue = Data([0x0])
            } else if le == 0x10000 {
                leValue = Data([0x0, 0x0])
            } else if le > 0x100 {
                leValue = Data([UInt8(le >> 8) & 0xff, UInt8(le & 0xff)])
            } else {
                leValue = Data([UInt8(le & 0xff)])
            }
            lengthObject = try create(tag: .taggedTag(0x17), data: .primitive(leValue)).serialize()
        } else {
            lengthObject = Data()
        }

        // Indicate Secure Messaging
        // note: must be done before mac calculation
        // gemSpec_COS#N032.500
        header[0] |= 0x0C

        //Calculate MAC
        // gemSpec_COS#N032.800
        let calculatedMac: Data
        let tmpData = dataObject + lengthObject
        if tmpData.isEmpty {
            calculatedMac = try AES128PaceKey.calculateMac(key: mac, ssc: ssc, macIn: header)
        } else {
            let padHeader = AES128PaceKey.pad(data: header, blockSize: AES128PaceKey.blockSize)
            calculatedMac = try AES128PaceKey.calculateMac(key: mac, ssc: ssc, macIn: padHeader + tmpData)
        }

        // Build Apdu
        let mDo = try create(tag: .taggedTag(0xE), data: .primitive(calculatedMac)).serialize()
        let secureData = tmpData + mDo

        let setLe = (command.nc > 0xFF) || (command.ne ?? 0 > 0x100) ?
                APDU.expectedLengthWildcardExtended :
                APDU.expectedLengthWildcardShort

        return try APDU.Command(cla: header[0],
                ins: header[1],
                p1: header[2],
                p2: header[3],
                data: secureData,
                ne: setLe)
    }

    private static func decrypt(response: ResponseType, enc: Data, mac: Data, ssc: Data) throws -> ResponseType {
        /**
            Read APDU structure
            Case 1: DO99|DO8E|SW1SW2
            Case 2: DO87|DO99|DO8E|SW1SW2
            Case 3: DO99|DO8E|SW1SW2
            Case 4: DO87|DO99|DO8E|SW1SW2
        */
        guard let responseData = response.data,
              responseData.count >= 14 else {
            throw Error.encryptedResponseMalformed
        }

        // Scan the encrypted response data [DO87]|DO99|DO8E
        var scanPosition = 0

        // Read data object (optional)
        let dataDo, dataDoValue: Data
        if responseData[scanPosition] == 0x87 {
            (dataDo, dataDoValue) = try AES128PaceKey.decodeDo0x87(from: responseData, startIndex: scanPosition)
        } else {
            dataDo = Data()
            dataDoValue = Data()
        }

        scanPosition += dataDo.count
        if responseData.count != scanPosition + 4 + 10 { // scanPosition + status.count + mac.count
            throw Error.encryptedResponseMalformed
        }

        // Read processing status (required)
        guard responseData[scanPosition] == 0x99,
              responseData[scanPosition + 1] == 0x2 else {
            throw Error.encryptedResponseMalformed
        }

        let statusDo = responseData[scanPosition..<scanPosition + 4]
        let statusBytes = responseData[scanPosition + 2..<scanPosition + 4]
        scanPosition += 4

        // Read mac (required)
        guard responseData[scanPosition] == 0x8e,
              responseData[scanPosition + 1] == 0x8 else {
            throw Error.encryptedResponseMalformed
        }
        let macBytes = responseData[scanPosition + 2..<scanPosition + 10]

        // Calculate mac for verification
        let calculatedMac = try AES128PaceKey.calculateMac(key: mac, ssc: ssc, macIn: dataDo + statusDo)
        if macBytes != calculatedMac {
            throw Error.secureMessagingMacVerificationFailed
        }

        // Decrypt data
        let unpaddedDataDecrypted: Data
        if !dataDoValue.isEmpty {
            let initVector = try AES.CBC128.encrypt(data: ssc, key: enc)
            let paddedDataDecrypted = try AES.CBC128.decrypt(data: dataDoValue, key: enc, initVector: initVector)
            unpaddedDataDecrypted = AES128PaceKey.unpad(data: paddedDataDecrypted)
        } else {
            unpaddedDataDecrypted = Data()
        }

        let tempResult = unpaddedDataDecrypted + statusBytes
        return try APDU.Response(apdu: Data(tempResult))
    }

    private static func calculateMac(key: Data, ssc: Data, macIn: Data) throws -> Data {
        let sscNormalized = ssc.normalize(to: AES128PaceKey.blockSize, paddingIndicator: 0x0)
        let macInPadded = AES128PaceKey.pad(data: macIn, blockSize: AES128PaceKey.blockSize)
        let cmac = try AES.CMAC(key: key, data: sscNormalized + macInPadded)
        return cmac.prefix(8)
    }

    private static func decodeDo0x87(from data: Data, startIndex: Int) throws -> (Data, Data) {
        precondition(data[startIndex] == 0x87)
        let scanPosition = startIndex

        // Read data object (optional)
        let dataDo: Data
        let dataDoValue: Data
        let decodedDataLength: Int

        let firstLengthByte = data[scanPosition + 1]
        if firstLengthByte > 0x80 {
            // long
            let octetsCount = firstLengthByte & 0x7f

            let lengthBytes = data[2..<2 + octetsCount]
            guard let unsignedLengthBytes = lengthBytes.unsignedIntValue else {
                throw Error.encryptedResponseMalformed
            }
            decodedDataLength = Int(unsignedLengthBytes)
            dataDo = data[scanPosition..<2 + Int(octetsCount) + decodedDataLength]
            dataDoValue = data[scanPosition + 2 + Int(octetsCount) + 1..<2 + Int(octetsCount) + decodedDataLength]
        } else {
            // short
            decodedDataLength = Int(firstLengthByte)
            dataDo = data[scanPosition..<2 + decodedDataLength]
            dataDoValue = data[scanPosition + 2 + 1..<2 + decodedDataLength]
        }

        return (dataDo, dataDoValue)
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
            if temp == 0xff {
                result[index] = 0
            } else {
                result[index] = temp + 1
                break
            }
        }
        return result
    }

    // ISO/IEC 7816-4 padding functions
    private static func pad(data: Data, blockSize: Int = AES128PaceKey.blockSize) -> Data {
        var padded = data + Data(repeating: 0x0, count: (blockSize - data.count % blockSize))
        assert(padded.count % blockSize == 0)
        assert(padded.count > data.count)
        padded[data.count] = pad
        return padded
    }

    private static func unpad(data: Data) -> Data {
        let result: Data
        if let lastIndex = data.lastIndex(of: AES128PaceKey.pad) {
            result = data[0..<lastIndex]
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
