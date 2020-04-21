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

@testable import CardReaderProviderApi
import Foundation
import Nimble
import XCTest

final class APDUCommandTest: XCTestCase {
    // swiftlint:disable:previous type_body_length

    //case 1:  |CLA|INS|P1 |P2 |                                 len = 4
    //case 2s: |CLA|INS|P1 |P2 |LE |                             len = 5
    //case 3s: |CLA|INS|P1 |P2 |LC |...BODY...|                  len = 6..260
    //case 4s: |CLA|INS|P1 |P2 |LC |...BODY...|LE |              len = 7..261
    //case 2e: |CLA|INS|P1 |P2 |00 |LE1|LE2|                     len = 7
    //case 3e: |CLA|INS|P1 |P2 |00 |LC1|LC2|...BODY...|          len = 8..65542
    //case 4e: |CLA|INS|P1 |P2 |00 |LC1|LC2|...BODY...|LE1|LE2|  len =10..65544
    //
    //LE, LE1, LE2 may be 0x00.
    //LC must not be 0x00 and LC1|LC2 must not be 0x00|0x00

    func testCommandAPDU_case1() {
        guard let command = try? APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4) else {
            Nimble.fail("APDU command could not be initialized")
            return
        }

        expect(command.cla).to(equal(0x1))
        expect(command.ins).to(equal(0x2))
        expect(command.p1).to(equal(0x3))
        expect(command.p2).to(equal(0x4))

        expect(command.data).to(beNil())
        expect(command.ne).to(beNil())
        expect(command.nc).to(equal(0))

        expect(command.bytes).to(equal([0x1, 0x2, 0x3, 0x4].data))
    }

    func testCommandAPDU_case2s() {
        guard let command = try? APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, ne: 6) else {
            Nimble.fail("APDU command could not be initialized")
            return
        }

        expect(command.cla).to(equal(0x1))
        expect(command.ins).to(equal(0x2))
        expect(command.p1).to(equal(0x3))
        expect(command.p2).to(equal(0x4))

        expect(command.data).to(beNil())
        expect(command.ne).to(equal(6))
        expect(command.nc).to(equal(0))

        expect(command.bytes).to(equal([0x1, 0x2, 0x3, 0x4, 0x6].data))
    }

    func testCommandAPDU_case2s_max() {
        guard let command = try? APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, ne: 256) else {
            Nimble.fail("APDU command could not be initialized")
            return
        }

        expect(command.cla).to(equal(0x1))
        expect(command.ins).to(equal(0x2))
        expect(command.p1).to(equal(0x3))
        expect(command.p2).to(equal(0x4))

        expect(command.data).to(beNil())
        expect(command.ne).to(equal(256))
        expect(command.nc).to(equal(0))

        expect(command.bytes).to(equal([0x1, 0x2, 0x3, 0x4, 0x00].data))
    }

    func testCommandAPDU_case3s() {
        // Data length <= 255 | no expected response length

        let data = Data([0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0])
        guard let command = try? APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, data: data, ne: nil) else {
            Nimble.fail("APDU command could not be initialized")
            return
        }

        expect(command.cla).to(equal(0x1))
        expect(command.ins).to(equal(0x2))
        expect(command.p1).to(equal(0x3))
        expect(command.p2).to(equal(0x4))

        expect(command.data).to(equal(data))
        expect(command.ne).to(beNil())
        expect(command.nc).to(equal(10))

        let expectedCommandData = [0x1, 0x2, 0x3, 0x4, 0xa] + data
        expect(command.bytes).to(equal(expectedCommandData.data))
    }

    func testCommandAPDU_case4s() {
        // Data length <= 255 and expected response length <= 256

        let data = Data([0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0])
        guard let command = try? APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, data: data, ne: 12) else {
            Nimble.fail("APDU command could not be initialized")
            return
        }

        expect(command.cla).to(equal(0x1))
        expect(command.ins).to(equal(0x2))
        expect(command.p1).to(equal(0x3))
        expect(command.p2).to(equal(0x4))

        expect(command.data).to(equal(data))
        expect(command.ne).to(equal(12))
        expect(command.nc).to(equal(10))

        let expectedCommandData = [0x1, 0x2, 0x3, 0x4, 0xa] + data + [0xc]
        expect(command.bytes).to(equal(expectedCommandData.data))
    }

    func testCommandAPDU_case4s_max() {
        // Data length <= 255 and expected response length <= 256

        let data = Data([0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0])
        guard let command = try? APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, data: data, ne: 256) else {
            Nimble.fail("APDU command could not be initialized")
            return
        }

        expect(command.cla).to(equal(0x1))
        expect(command.ins).to(equal(0x2))
        expect(command.p1).to(equal(0x3))
        expect(command.p2).to(equal(0x4))

        expect(command.data).to(equal(data))
        expect(command.ne).to(equal(256))
        expect(command.nc).to(equal(10))

        let expectedCommandData = [0x1, 0x2, 0x3, 0x4, 0xa] + data + [0x00]
        expect(command.bytes).to(equal(expectedCommandData.data))
    }

    func testCommandAPDU_case2e() {
        guard let command = try? APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, ne: 30000) else {
            Nimble.fail("APDU command could not be initialized")
            return
        }

        expect(command.cla).to(equal(0x1))
        expect(command.ins).to(equal(0x2))
        expect(command.p1).to(equal(0x3))
        expect(command.p2).to(equal(0x4))

        expect(command.data).to(beNil())
        expect(command.ne).to(equal(30000))
        expect(command.nc).to(equal(0))

        expect(command.bytes).to(equal([0x1, 0x2, 0x3, 0x4, 0x00, 0x75, 0x30].data))
    }

    func testCommandAPDU_case2e_max() {
        guard let command =
            try? APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, ne: APDU.expectedLengthWildcardExtended)
                else {
            Nimble.fail("APDU command could not be initialized")
            return
        }

        expect(command.cla).to(equal(0x1))
        expect(command.ins).to(equal(0x2))
        expect(command.p1).to(equal(0x3))
        expect(command.p2).to(equal(0x4))

        expect(command.data).to(beNil())
        expect(command.ne).to(equal(APDU.expectedLengthWildcardExtended))
        expect(command.nc).to(equal(0))

        expect(command.bytes).to(equal([0x1, 0x2, 0x3, 0x4, 0x0, 0x0, 0x0].data))
    }

    func testCommandAPDU_case3e() {
        // Data length > 255 | no expected response length

        //case 3e: |CLA|INS|P1 |P2 |00 |LC1|LC2|...BODY...|          len = 8..65542
        var data = Data()
        repeat {
            data.append(Data([0xf1, 0x80, 0xa, 0xa0, 0x0a]))
        } while (data.count < 30000)
        guard let command = try? APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, data: data, ne: nil) else {
            Nimble.fail("APDU command could not be initialized")
            return
        }

        expect(command.cla).to(equal(0x1))
        expect(command.ins).to(equal(0x2))
        expect(command.p1).to(equal(0x3))
        expect(command.p2).to(equal(0x4))

        expect(command.data).to(equal(data))
        expect(command.ne).to(beNil())
        expect(command.nc).to(equal(data.count))

        let size = UInt16(data.count)
        let lc1 = UInt8(size >> 8)
        let lc2 = UInt8(size & 0xff)

        let expectedCommandData = [0x1, 0x2, 0x3, 0x4, 0x00, lc1, lc2] + data
        expect(command.bytes).to(equal(expectedCommandData.data))
    }

    func testCommandAPDU_case4e_ne_512() {
        // Data length > 255 OR expected response length > 256

        //case 4e: |CLA|INS|P1 |P2 |00 |LC1|LC2|...BODY...|LE1|LE2|  len =10..65544
        let data = Data([0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0])
        guard let command = try? APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, data: data, ne: 512) else {
            Nimble.fail("APDU command could not be initialized")
            return
        }

        expect(command.cla).to(equal(0x1))
        expect(command.ins).to(equal(0x2))
        expect(command.p1).to(equal(0x3))
        expect(command.p2).to(equal(0x4))

        expect(command.data).to(equal(data))
        expect(command.ne).to(equal(512))
        expect(command.nc).to(equal(10))

        let size = UInt16(data.count)
        let lc1 = UInt8(size >> 8)
        let lc2 = UInt8(size)

        let expectedCommandData = [0x1, 0x2, 0x3, 0x4, 0x00, lc1, lc2] + data + [0x2, 0x0]
        expect(command.bytes).to(equal(expectedCommandData.data))
    }

    func testCommandAPDU_case4e_big_data() {
        var data = Data()
        repeat {
            data.append(Data([0xf1, 0x80, 0xa, 0xa0, 0x0a]))
        } while (data.count < 30000)
        guard let command = try? APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, data: data, ne: 256) else {
            Nimble.fail("APDU command could not be initialized")
            return
        }

        expect(command.cla).to(equal(0x1))
        expect(command.ins).to(equal(0x2))
        expect(command.p1).to(equal(0x3))
        expect(command.p2).to(equal(0x4))

        expect(command.data).to(equal(data))
        expect(command.ne).to(equal(256))
        expect(command.nc).to(equal(data.count))

        let size = UInt16(data.count)
        let lc1 = UInt8(size >> 8)
        let lc2 = UInt8(size & 0xff)

        let expectedCommandData = [0x1, 0x2, 0x3, 0x4, 0x00, lc1, lc2] + data + [0x1, 0x0]
        expect(command.bytes).to(equal(expectedCommandData.data))
    }

    func testCommandAPDU_case4e_small_data() {
        let data = Data([0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0])
        guard let command = try? APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, data: data, ne: 512) else {
            Nimble.fail("APDU command could not be initialized")
            return
        }

        expect(command.cla).to(equal(0x1))
        expect(command.ins).to(equal(0x2))
        expect(command.p1).to(equal(0x3))
        expect(command.p2).to(equal(0x4))

        expect(command.data).to(equal(data))
        expect(command.ne).to(equal(512))
        expect(command.nc).to(equal(data.count))

        let lc1: UInt8 = 0x0
        let lc2: UInt8 = 0xa

        let expectedCommandData = [0x1, 0x2, 0x3, 0x4, 0x00, lc1, lc2] + data + [0x2, 0x0]
        expect(command.bytes).to(equal(expectedCommandData.data))
    }

    func testCommandAPDU_case4e_too_big_data() {
        var data = Data()
        repeat {
            data.append(Data([0xf1, 0x80, 0xa, 0xa0, 0x0a]))
        } while (data.count < 65535 + 5)

        expect(try APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, data: data, ne: 256)).to(throwError())
        expect(try APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, data: data, ne: 256))
                .to(throwError(APDU.Error.commandBodyDataTooLarge))
    }

    func testCommandAPDU_expectedLengthWildcardEncoding_short() {
        let data = Data([0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0, 0xa0])

        // test with ne = static wildcard variables short
        expect {
            try APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, data: data, ne: APDU.expectedLengthWildcardShort)
                    .bytes
        } == [0x1, 0x2, 0x3, 0x4] + [0xa] + data + [0x0]

        // test with ne = extended wildcard
        expect {
            try APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, data: data, ne: APDU.expectedLengthWildcardExtended)
                    .bytes
        } == [0x1, 0x2, 0x3, 0x4] + [0x0, 0x0, 0xa] + data + [0x0, 0x0]

        // test with ne = 0 (wildcard short)
        expect {
            try APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, data: data, ne: 0).bytes
        } == [0x1, 0x2, 0x3, 0x4] + [0xa] + data + [0x0]

        // ne = nil
        expect {
            try APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, data: data).bytes
        } == [0x1, 0x2, 0x3, 0x4] + [0xa] + data
    }

    func testCommandAPDU_expectedLengthWildcardEncoding_extended() {
        let dataLong = Data(repeating: 0xfa, count: 30000)
        let size = UInt16(dataLong.count)
        let lc1 = UInt8(size >> 8)
        let lc2 = UInt8(size & 0xff)
        // ne = 0 - wildcard extended
        expect {
            try APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, data: dataLong, ne: 0).bytes
        } == [0x1, 0x2, 0x3, 0x4, 0x00, lc1, lc2] + dataLong + [0x0, 0x0]

        // ne = nil
        expect {
            try APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, data: dataLong).bytes
        } == [0x1, 0x2, 0x3, 0x4, 0x00, lc1, lc2] + dataLong

        // ne = 0 -> wildcard short
        expect {
            try APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, data: nil, ne: 0).bytes
        } == Data([0x1, 0x2, 0x3, 0x4, 0x0])

        // ne = nil
        expect {
            try APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, data: nil).bytes
        } == Data([0x1, 0x2, 0x3, 0x4])
    }

    func testCommandAPDU_ErrorExpectedLengthOutOfBounds() {
        expect {
            try APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, ne: -1)
        }.to(throwError(APDU.Error.expectedResponseLengthOutOfBounds))

        expect {
            try APDU.Command(cla: 0x1, ins: 0x2, p1: 0x3, p2: 0x4, ne: 65537)
        }.to(throwError(APDU.Error.expectedResponseLengthOutOfBounds))
    }

    static var allTests = [
        ("testCommandAPDU_case1", testCommandAPDU_case1),
        ("testCommandAPDU_case2s", testCommandAPDU_case2s),
        ("testCommandAPDU_case2s_max", testCommandAPDU_case2s_max),
        ("testCommandAPDU_case3s", testCommandAPDU_case3s),
        ("testCommandAPDU_case4s", testCommandAPDU_case4s),
        ("testCommandAPDU_case4s_max", testCommandAPDU_case4s_max),
        ("testCommandAPDU_case2e", testCommandAPDU_case2e),
        ("testCommandAPDU_case2e_max", testCommandAPDU_case2e_max),
        ("testCommandAPDU_case3e", testCommandAPDU_case3e),
        ("testCommandAPDU_case4e_ne_512", testCommandAPDU_case4e_ne_512),
        ("testCommandAPDU_case4e_big_data", testCommandAPDU_case4e_big_data),
        ("testCommandAPDU_case4e_small_data", testCommandAPDU_case4e_small_data),
        ("testCommandAPDU_case4e_too_big_data", testCommandAPDU_case4e_too_big_data),
        ("testCommandAPDU_expectedLengthWildcardEncoding_short", testCommandAPDU_expectedLengthWildcardEncoding_short),
        ("testCommandAPDU_expectedLengthWildcardEncoding_extended", testCommandAPDU_expectedLengthWildcardEncoding_extended),  // swiftlint:disable:this line_length
        ("testCommandAPDU_ErrorExpectedLengthOutOfBounds", testCommandAPDU_ErrorExpectedLengthOutOfBounds)
    ]

}
