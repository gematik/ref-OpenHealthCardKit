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
import Nimble
import XCTest

class CommandTypeExtLogicChannelTests: XCTestCase {
    func testCommandAPDU_toChannel1() {
        guard let originalCommand = try? APDU.Command(cla: 0x0, ins: 0x2, p1: 0x3, p2: 0x4, ne: 256),
              let command = try? originalCommand.toLogicalChannel(channelNo: 1) else {
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

    func testCommandAPDU_toChannel4() {
        guard let originalCommand = try? APDU.Command(cla: 0x0, ins: 0x2, p1: 0x3, p2: 0x4, ne: 256),
              let command = try? originalCommand.toLogicalChannel(channelNo: 4) else {
            Nimble.fail("APDU command could not be initialized")
            return
        }

        expect(command.cla).to(equal(0x40))
        expect(command.ins).to(equal(0x2))
        expect(command.p1).to(equal(0x3))
        expect(command.p2).to(equal(0x4))

        expect(command.data).to(beNil())
        expect(command.ne).to(equal(256))
        expect(command.nc).to(equal(0))

        expect(command.bytes).to(equal([0x40, 0x2, 0x3, 0x4, 0x00].data))
    }

    func testCommandAPDU_toChannel19() {
        guard let originalCommand = try? APDU.Command(cla: 0x0, ins: 0x2, p1: 0x3, p2: 0x4, ne: 256),
              let command = try? originalCommand.toLogicalChannel(channelNo: 19) else {
            Nimble.fail("APDU command could not be initialized")
            return
        }

        expect(command.cla).to(equal(0x4F))
        expect(command.ins).to(equal(0x2))
        expect(command.p1).to(equal(0x3))
        expect(command.p2).to(equal(0x4))

        expect(command.data).to(beNil())
        expect(command.ne).to(equal(256))
        expect(command.nc).to(equal(0))

        expect(command.bytes).to(equal([0x4F, 0x2, 0x3, 0x4, 0x00].data))
    }

    func testCommandAPDU_toChannel20() {
        guard let originalCommand = try? APDU.Command(cla: 0x0, ins: 0x2, p1: 0x3, p2: 0x4, ne: 256) else {
            Nimble.fail("APDU command could not be initialized")
            return
        }
        expect {
            try originalCommand.toLogicalChannel(channelNo: 20)
        }.to(throwError(CardError.illegalState(InvalidCommandChannel(channelNo: 20))))
    }
}
