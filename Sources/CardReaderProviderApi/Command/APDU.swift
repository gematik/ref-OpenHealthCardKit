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

/// Concrete APDU command + response implementation
public class APDU {
    public enum Error: Swift.Error {
        /// when the APDU body exceeds 65535
        case commandBodyDataTooLarge
        /// when the expected APDU response length is out of bounds [0, 65536]
        case expectedResponseLengthOutOfBounds
        /// when the APDU response data is not at least two bytes long
        case insufficientResponseData(data: Data)

        var data: Data? {
            if case .insufficientResponseData(let data) = self {
                return data
            }
            return nil
        }
    }

    /// Value for when wildcardShort for expected length encoding is needed
    public static let expectedLengthWildcardShort: Int = 256
    /// Value for when wildcardExtended for expected length encoding is needed
    public static let expectedLengthWildcardExtended: Int = 65536

    /// An  APDU response per ISO/IEC 7816-4. It consists of a conditional body and a two byte trailer.
    /// This class does not attempt to semantically verify an APDU response.
    /// - SeeAlso: `ResponseType`
    public struct Response {
        /// APDU serialized data
        let apdu: Data

        /**
            Initialize APDU response with raw Data.

            - Parameter data: the raw APDU response data
        */
        public init(apdu data: Data) throws {
            guard Response.check(bytes: data) else {
                throw APDU.Error.insufficientResponseData(data: data)
            }
            self.apdu = data
        }

        /// apdu must be at least 2 bytes long
        static func check(bytes: Data) -> Bool {
            return bytes.count > 1
        }

        /// Success response [0x9000]
        public static let OK = try! Response(apdu: [0x90, 0x0].data)
        // swiftlint:disable:previous identifier_name force_try
    }

    //swiftlint:disable identifier_name
    /**
        An APDU Command per ISO/IEC 7816-4.
        Command APDU encoding options:

        ```
            case 1:  |CLA|INS|P1 |P2 |                                 len = 4
            case 2s: |CLA|INS|P1 |P2 |LE |                             len = 5
            case 3s: |CLA|INS|P1 |P2 |LC |...BODY...|                  len = 6..260
            case 4s: |CLA|INS|P1 |P2 |LC |...BODY...|LE |              len = 7..261
            case 2e: |CLA|INS|P1 |P2 |00 |LE1|LE2|                     len = 7
            case 3e: |CLA|INS|P1 |P2 |00 |LC1|LC2|...BODY...|          len = 8..65542
            case 4e: |CLA|INS|P1 |P2 |00 |LC1|LC2|...BODY...|LE1|LE2|  len =10..65544

            LE, LE1, LE2 may be 0x00.
            LC must not be 0x00 and LC1|LC2 must not be 0x00|0x00
        ```
    */
    public struct Command {
        let apdu: Data
        let rawNc: Int
        let rawNe: Int?
        let dataOffset: Int

        /**
        Construct an APDU Command with all its internals prepared and proper formatted according to the class
        description.
        We assume the integrity of the parameters of this internal constructor used by the convenience constructors in
         the extension.

        - Parameters:
            - data: apdu data including headers and optional additional data
            - nc: Nr of bytes in body
            - ne: Nr of expected bytes in response
            - dataOffset: start of the data within the apdu
        */
        init(apdu data: Data, nc: Int, ne: Int?, dataOffset: Int) {
            self.apdu = data
            self.rawNc = nc
            self.rawNe = ne
            self.dataOffset = dataOffset
        }
    }
}

extension APDU.Command {
    /**
        Constructs a CommandAPDU from the four header bytes.
        This is **case 1** in ISO 7816, no command body.

        - Parameters:
            - cla: CLA byte
            - ins: Instruction byte
            - p1: P1 byte
            - p2: P2 byte
            - ne: Nr of expected bytes in response. Default: 0
    */
    public init(cla: UInt8, ins: UInt8, p1: UInt8, p2: UInt8, ne: Int? = nil) throws {
        try self.init(cla: cla, ins: ins, p1: p1, p2: p2, data: nil, ne: ne)
    }

    /**
        Constructs a CommandAPDU from the four header bytes, command data,
        and expected response data length. This is case 4 in ISO 7816,
        command data and Le present. The value Nc is taken as
        `dataLength`.
        If Ne or Nc are zero, the APDU is encoded as case 1, 2, or 3 per ISO 7816.

        - Parameters:
            - cla: CLA byte
            - ins: Instruction byte
            - p1: P1 byte
            - p2: P2 byte
            - ne: Nr of expected bytes in response. Default: 0
    */
    public init(cla: UInt8, ins: UInt8, p1: UInt8, p2: UInt8, data: Data?, ne: Int? = nil) throws {
        // swiftlint:disable:previous function_body_length

        if let len = ne, (len > APDU.expectedLengthWildcardExtended || len < 0) {
            throw APDU.Error.expectedResponseLengthOutOfBounds
        }

        if let data = data, !data.isEmpty {
            let nc = data.count
            if nc > 65535 {
                throw APDU.Error.commandBodyDataTooLarge
            }
            let dataOffset: Int
            var bytes = APDU.Command.header(cla: cla, ins: ins, p1: p1, p2: p2)
            let le: Int?
            if let ne = ne {
               le = ne
                // case 4s or 4e
                if nc <= 255 && ne <= APDU.expectedLengthWildcardShort {
                    // case 4s
                    dataOffset = 5
                    bytes.append(APDU.Command.encodeDataLength(short: nc))
                    bytes.append(data)
                    bytes.append(APDU.Command.encodeExpectedLength(short: ne))
                } else {
                    // case 4e
                    dataOffset = 7
                    bytes.append(APDU.Command.encodeDataLength(extended: nc))
                    bytes.append(data)
                    bytes.append(APDU.Command.encodeExpectedLength(extended: ne))
                }
            } else {
                // case 3s or 3e
                le = nil
                if nc <= 255 {
                    // case 3s
                    dataOffset = 5
                    bytes.append(APDU.Command.encodeDataLength(short: nc))
                } else {
                    // case 3e
                    dataOffset = 7
                    bytes.append(APDU.Command.encodeDataLength(extended: nc))
                }
                bytes.append(data)
            }
            self.init(apdu: bytes, nc: nc, ne: le, dataOffset: dataOffset)

        } else {
            // data empty
            var bytes = APDU.Command.header(cla: cla, ins: ins, p1: p1, p2: p2)
            if let ne = ne {
                // case 2s or 2e
                if ne <= APDU.expectedLengthWildcardShort {
                    // case 2s
                    // 256 is encoded 0x0
                    bytes.append(APDU.Command.encodeExpectedLength(short: ne))
                } else {
                    // case 2e
                    bytes.append(0x0)
                    bytes.append(APDU.Command.encodeExpectedLength(extended: ne))
                }
                self.init(apdu: bytes, nc: 0, ne: ne, dataOffset: 0)
            } else {
                // case 1
                self.init(apdu: bytes, nc: 0, ne: nil, dataOffset: 0)
            }
        }
    }

    private static func header(cla: UInt8, ins: UInt8, p1: UInt8, p2: UInt8) -> Data {
        return Data([cla, ins, p1, p2])
    }

    private static func encodeExpectedLength(extended ne: Int) -> Data {
        let l1, l2: UInt8
        if ne == APDU.expectedLengthWildcardExtended { // == 65536
            l1 = 0
            l2 = 0
        } else {
            l1 = UInt8(ne >> 8)
            l2 = UInt8(ne & 0xff)
        }
        return Data([l1, l2])
    }

    private static func encodeExpectedLength(short ne: Int) -> Data {
        let len = (ne != APDU.expectedLengthWildcardShort) ? UInt8(ne) : 0x0
        return Data([len])
    }

    private static func encodeDataLength(extended nc: Int) -> Data {
        let l1 = UInt8(nc >> 8)
        let l2 = UInt8(nc & 0xff)
        return Data([0x0, l1, l2])
    }

    private static func encodeDataLength(short nc: Int) -> Data {
        return Data([UInt8(nc)])
    }
    //swiftlint:enable identifier_name
}

extension APDU.Response {
    /// Convenience initializer for APDU repsonses that come in three parts
    /// - Parameters:
    ///     - body: response body, may be empty
    ///     - sw1: the SW1 command processing byte
    ///     - sw2: the SW2 command processing byte
    /// - Throws: `APDU.Error`
    public init(body: Data, sw1: UInt8, sw2: UInt8) throws {
        try self.init(apdu: body + [sw1, sw2])
    }
}
