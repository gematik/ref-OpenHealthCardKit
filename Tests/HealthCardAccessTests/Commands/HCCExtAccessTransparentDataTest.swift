//
//  Copyright (c) 2022 gematik GmbH
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
@testable import HealthCardAccess
import Nimble
import XCTest

final class HCCExtAccessTransparentDataTest: XCTestCase {
    func testEraseWithoutShortFileIdentifier() {
        guard let hccErase = try? HealthCardCommand.Erase.eraseFileCommand() else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }
        expect(hccErase.cla).to(equal(0x0))
        expect(hccErase.ins).to(equal(0xE0))
        expect(hccErase.p1).to(equal(0x0))
        expect(hccErase.p2).to(equal(0x0))
        expect(hccErase.data).to(beNil())
        expect(hccErase.ne).to(beNil())
        expect(hccErase.responseStatuses.keys).to(contain([ResponseStatus.noCurrentEf.code]))

        guard let hccErase2 = try? HealthCardCommand.Erase.eraseFileCommand(offset: 10) else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }
        expect(hccErase2.p1).to(equal(0x0))
        expect(hccErase2.p2).to(equal(0xA))

        guard let hccErase4 = try? HealthCardCommand.Erase.eraseFileCommand() else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }
        expect(hccErase4.cla).to(equal(0x0))
    }

    func testEraseWithShortFileIdentifier() {
        let sfid = "0E" as ShortFileIdentifier
        guard let hccErase = try? HealthCardCommand.Erase.eraseFileCommand(with: sfid) else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }

        expect(hccErase.cla).to(equal(0x0))
        expect(hccErase.ins).to(equal(0xE0))
        expect(hccErase.p1).to(equal(0x8E))
        expect(hccErase.p2).to(equal(0x0))
        expect(hccErase.data).to(beNil())
        expect(hccErase.responseStatuses.keys).to(contain([0x9000]))
    }

    func testEraseThrowing() {
        expect(try HealthCardCommand.Erase.eraseFileCommand(offset: 32767))
            .toNot(throwError())
        expect(try HealthCardCommand.Erase.eraseFileCommand(offset: 32768))
            .to(throwError(HealthCardCommandBuilder.InvalidArgument
                    .offsetOutOfBounds(32768, usingShortFileIdentifier: false)))
        expect(try HealthCardCommand.Erase.eraseFileCommand(offset: -1))
            .to(throwError(HealthCardCommandBuilder.InvalidArgument
                    .offsetOutOfBounds(-1, usingShortFileIdentifier: false)))
    }

    func testReadWithoutShortFileIdentifier() {
        guard let hccRead = try? HealthCardCommand.Read.readFileCommand(ne: 15) else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }
        expect(hccRead.cla).to(equal(0x0))
        expect(hccRead.ins).to(equal(0xB0))
        expect(hccRead.p1).to(equal(0x0))
        expect(hccRead.p2).to(equal(0x0))
        expect(hccRead.data).to(beNil())
        expect(hccRead.ne).to(equal(0xF))
        expect(hccRead.responseStatuses.keys).to(contain([ResponseStatus.wrongFileType.code]))

        guard let hccRead2 = try? HealthCardCommand.Read.readFileCommand(ne: 15, offset: 10) else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }
        expect(hccRead2.p1).to(equal(0x0))
        expect(hccRead2.p2).to(equal(0xA))
        expect(hccRead2.ne).to(equal(0xF))
        expect(hccRead2.responseStatuses.keys).to(contain([ResponseStatus.wrongFileType.code]))
    }

    func testReadWithShortFileIdentifier() {
        let sfid = "0E" as ShortFileIdentifier
        guard let hccRead = try? HealthCardCommand.Read.readFileCommand(with: sfid, ne: 15) else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }

        expect(hccRead.cla).to(equal(0x0))
        expect(hccRead.ins).to(equal(0xB0))
        expect(hccRead.p1).to(equal(0x8E))
        expect(hccRead.p2).to(equal(0x0))
        expect(hccRead.data).to(beNil())
        expect(hccRead.ne).to(equal(0xF))
        expect(hccRead.responseStatuses.keys).to(contain([0x9000]))

        guard let hccRead2 = try? HealthCardCommand.Read.readFileCommand(with: sfid, ne: 15, offset: 10) else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }
        expect(hccRead2.cla).to(equal(0x0))
        expect(hccRead2.ins).to(equal(0xB0))
        expect(hccRead2.p1).to(equal(0x8E))
        expect(hccRead2.p2).to(equal(0xA))
        expect(hccRead2.data).to(beNil())
        expect(hccRead2.ne).to(equal(0xF))
        expect(hccRead2.responseStatuses.keys).to(contain([0x9000]))
    }

    func testReadThrowing() {
        expect(try HealthCardCommand.Read.readFileCommand(ne: 0))
            .to(throwError(HealthCardCommandBuilder.InvalidArgument.expectedLengthMustNotBeZero))
        expect(try HealthCardCommand.Read.readFileCommand(ne: 15, offset: 32767))
            .toNot(throwError())
        expect(try HealthCardCommand.Read.readFileCommand(ne: 15, offset: 32768))
            .to(throwError(HealthCardCommandBuilder.InvalidArgument
                    .offsetOutOfBounds(32768, usingShortFileIdentifier: false)))
    }

    func testSetLogicalEofWithoutShortFileIdentifier() {
        guard let hccSetLogicalEof = try? HealthCardCommand.SetLogicalEof.setLogicalEofCommand() else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }
        expect(hccSetLogicalEof.cla).to(equal(0x80))
        expect(hccSetLogicalEof.ins).to(equal(0xE))
        expect(hccSetLogicalEof.p1).to(equal(0x0))
        expect(hccSetLogicalEof.p2).to(equal(0x0))
        expect(hccSetLogicalEof.data).to(beNil())
        expect(hccSetLogicalEof.ne).to(beNil())
        expect(hccSetLogicalEof.responseStatuses.keys).to(contain([ResponseStatus.noCurrentEf.code]))
    }

    func testSetLogicalEofWithShortFileIdentifier() {
        let sfid = "0E" as ShortFileIdentifier
        guard let hccSetLogicalEof = try? HealthCardCommand.SetLogicalEof.setLogicalEofCommand(with: sfid, offset: 11)
        else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }
        expect(hccSetLogicalEof.cla).to(equal(0x80))
        expect(hccSetLogicalEof.ins).to(equal(0xE))
        expect(hccSetLogicalEof.p1).to(equal(0x8E))
        expect(hccSetLogicalEof.p2).to(equal(0xB))
    }

    func testUpdateWithoutShortFileIdentifier() {
        let data = Data([0xD2, 0x76, 0x0, 0x0, 0x1, 0x2])
        guard let hccUpdate = try? HealthCardCommand.Update.updateCommand(data: data) else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }

        expect(hccUpdate.cla).to(equal(0x0))
        expect(hccUpdate.ins).to(equal(0xD6))
        expect(hccUpdate.p1).to(equal(0x0))
        expect(hccUpdate.p2).to(equal(0x0))
        expect(hccUpdate.data).to(equal(data))
        expect(hccUpdate.ne).to(beNil())
        expect(hccUpdate.responseStatuses.keys).to(contain([ResponseStatus.noCurrentEf.code]))
    }

    func testUpdateWithShortFileIdentifier() {
        let sfid = "0E" as ShortFileIdentifier
        let data = Data([0xD2, 0x76, 0x0, 0x0, 0x1, 0x2])
        guard let hccUpdate = try? HealthCardCommand.Update.updateCommand(with: sfid, data: data, offset: 11) else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }

        expect(hccUpdate.p1).to(equal(0x8E))
        expect(hccUpdate.p2).to(equal(0xB))
        expect(hccUpdate.data).to(equal(data))
    }

    func testUpdateThrowing() {
        let sfid = "0E" as ShortFileIdentifier
        let data = Data([0xD2, 0x76, 0x0, 0x0, 0x1, 0x2])
        expect(try HealthCardCommand.Update.updateCommand(data: data, offset: 32767)).toNot(throwError())
        expect(try HealthCardCommand.Update.updateCommand(with: sfid, data: data, offset: 256))
            .to(throwError(HealthCardCommandBuilder.InvalidArgument
                    .offsetOutOfBounds(256, usingShortFileIdentifier: true)))
    }

    func testWriteWithoutShortFileIdentifier() {
        let data = Data([0xD2, 0x76, 0x0, 0x0, 0x1, 0x2])
        guard let hccWrite = try? HealthCardCommand.Write.writeCommand(data: data) else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }

        expect(hccWrite.p1).to(equal(0x0))
        expect(hccWrite.p2).to(equal(0x0))
        expect(hccWrite.data).to(equal(data))
    }

    func testWriteWithShortFileIdentifier() {
        let sfid = "0E" as ShortFileIdentifier
        let data = Data([0xD2, 0x76, 0x0, 0x0, 0x1, 0x2])
        guard let hccWrite = try? HealthCardCommand.Write.writeCommand(with: sfid, data: data) else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }

        expect(hccWrite.p1).to(equal(0x8E))
        expect(hccWrite.p2).to(equal(0x0))
        expect(hccWrite.data).to(equal(data))
    }

    static let allTests = [
        ("testEraseWithoutShortFileIdentifier", testEraseWithoutShortFileIdentifier),
        ("testEraseWithShortFileIdentifier", testEraseWithShortFileIdentifier),
        ("testEraseThrowing", testEraseThrowing),
        ("testReadWithoutShortFileIdentifier", testReadWithoutShortFileIdentifier),
        ("testReadWithShortFileIdentifier", testReadWithShortFileIdentifier),
        ("testReadThrowing", testReadThrowing),
        ("testSetLogicalEofWithoutShortFileIdentifier", testSetLogicalEofWithoutShortFileIdentifier),
        ("testSetLogicalEofWithShortFileIdentifier", testSetLogicalEofWithShortFileIdentifier),
        ("testUpdateWithoutShortFileIdentifier", testUpdateWithoutShortFileIdentifier),
        ("testUpdateWithShortFileIdentifier", testUpdateWithShortFileIdentifier),
        ("testUpdateThrowing", testUpdateThrowing),
        ("testWriteWithoutShortFileIdentifier", testWriteWithoutShortFileIdentifier),
        ("testWriteWithShortFileIdentifier", testWriteWithShortFileIdentifier),
    ]
}
