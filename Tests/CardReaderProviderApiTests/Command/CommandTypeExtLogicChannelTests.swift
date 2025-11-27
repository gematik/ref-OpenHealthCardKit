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

@testable import CardReaderProviderApi
import Nimble
import XCTest

class CommandTypeExtLogicChannelTests: XCTestCase {
    func testCommandAPDU_toChannel1() throws {
        let originalCommand = try APDU.Command(cla: 0x0, ins: 0x2, p1: 0x3, p2: 0x4, ne: 256)
        let command = try originalCommand.toLogicalChannel(channelNo: 1)

        expect(command.cla).to(equal(0x1))
        expect(command.ins).to(equal(0x2))
        expect(command.p1).to(equal(0x3))
        expect(command.p2).to(equal(0x4))

        expect(command.data).to(beNil())
        expect(command.ne).to(equal(256))
        expect(command.nc).to(equal(0))

        expect(command.bytes).to(equal(Data([0x1, 0x2, 0x3, 0x4, 0x00])))
    }

    func testCommandAPDU_toChannel4() throws {
        let originalCommand = try APDU.Command(cla: 0x0, ins: 0x2, p1: 0x3, p2: 0x4, ne: 256)
        let command = try originalCommand.toLogicalChannel(channelNo: 4)

        expect(command.cla).to(equal(0x40))
        expect(command.ins).to(equal(0x2))
        expect(command.p1).to(equal(0x3))
        expect(command.p2).to(equal(0x4))

        expect(command.data).to(beNil())
        expect(command.ne).to(equal(256))
        expect(command.nc).to(equal(0))

        expect(command.bytes).to(equal(Data([0x40, 0x2, 0x3, 0x4, 0x00])))
    }

    func testCommandAPDU_toChannel19() throws {
        let originalCommand = try APDU.Command(cla: 0x0, ins: 0x2, p1: 0x3, p2: 0x4, ne: 256)
        let command = try originalCommand.toLogicalChannel(channelNo: 19)

        expect(command.cla).to(equal(0x4F))
        expect(command.ins).to(equal(0x2))
        expect(command.p1).to(equal(0x3))
        expect(command.p2).to(equal(0x4))

        expect(command.data).to(beNil())
        expect(command.ne).to(equal(256))
        expect(command.nc).to(equal(0))

        expect(command.bytes).to(equal(Data([0x4F, 0x2, 0x3, 0x4, 0x00])))
    }

    func testCommandAPDU_toChannel20() throws {
        let originalCommand = try APDU.Command(cla: 0x0, ins: 0x2, p1: 0x3, p2: 0x4, ne: 256)
        expect {
            try originalCommand.toLogicalChannel(channelNo: 20)
        }.to(throwError(CardError.illegalState(InvalidCommandChannel(channelNo: 20))))
    }
}
