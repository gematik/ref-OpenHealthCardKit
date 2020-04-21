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
import Foundation
@testable import HealthCardAccess
import Nimble
import XCTest

final class HCCExtObjectSystemManagementTest: XCTestCase {

    func testActivate() {
        let hccActivate = HealthCardCommand.Activate.activateCurrentFile()
        expect(hccActivate.cla).to(equal(0x0))
        expect(hccActivate.ins).to(equal(0x44))
        expect(hccActivate.p1).to(equal(0x0))
        expect(hccActivate.p2).to(equal(0x0))
        expect(hccActivate.ne).to(beNil())
        expect(hccActivate.responseStatuses.keys).to(contain(ResponseStatus.keyOrPwdNotFound.code))
    }

    func testDeactivate() {
        guard let key = try? Key(0x3) else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }
        let hccDeactivate = HealthCardCommand.Deactivate.deactivate(privateOrSymmetricKey: key, dfSpecific: true)
        expect(hccDeactivate.ins).to(equal(0x04))
        expect(hccDeactivate.p1).to(equal(0x20))
        expect(hccDeactivate.p2).to(equal(0x83))
    }

    func testDelete() {
        let reference = Data([0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7])
        guard let hccDelete = try? HealthCardCommand.Delete.deletePublicKey(reference: reference) else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }
        expect(hccDelete.ins).to(equal(0xe4))
        expect(hccDelete.p1).to(equal(0x21))
        expect(hccDelete.p2).to(equal(0x00))
        expect(hccDelete.data).to(equal(Data([0x83, 0x8, 0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7])))
    }

    func testLoadApplication() {
        let data = Data([0xd2, 0x76, 0x0, 0x0, 0x1, 0x2])
        let hccLoadApplication = HealthCardCommand.LoadApplication.loadApplication(useChaining: true, data: data)
        expect(hccLoadApplication.cla).to(equal(0x10))
        expect(hccLoadApplication.ins).to(equal(0xea))
        expect(hccLoadApplication.p1).to(equal(0x0))
        expect(hccLoadApplication.p2).to(equal(0x0))
        expect(hccLoadApplication.data).to(equal(data))
        expect(hccLoadApplication.responseStatuses.keys).to(contain([ResponseStatus.dfNameExists.code]))

        let hccLoadApplication2 = HealthCardCommand.LoadApplication.loadApplication(useChaining: false, data: data)
        expect(hccLoadApplication2.cla).to(equal(0x0))
        expect(hccLoadApplication2.ins).to(equal(0xea))
        expect(hccLoadApplication2.p1).to(equal(0x0))
        expect(hccLoadApplication2.p2).to(equal(0x0))
        expect(hccLoadApplication2.data).to(equal(data))
    }

    func testSelectRoot() {
        let hccSelect = HealthCardCommand.Select.selectRoot()
        expect(hccSelect.cla).to(equal(0x0))
        expect(hccSelect.ins).to(equal(0xa4))
        expect(hccSelect.p1).to(equal(0x4))
        expect(hccSelect.p2).to(equal(0xc))
        expect(hccSelect.data).to(beNil())
        expect(hccSelect.ne).to(beNil())
        expect(hccSelect.responseStatuses.keys).to(contain([ResponseStatus.fileTerminated.code]))

        guard let hccSelect2 = try? HealthCardCommand.Select.selectRootRequestingFcp(expectedLength: 15) else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }
        expect(hccSelect2.p1).to(equal(0x4))
        expect(hccSelect2.p2).to(equal(0x4))
        expect(hccSelect2.ne).to(equal(0xf))
    }

    func testSelectWithAid() {
        let aid = "D27600000102" as ApplicationIdentifier
        let hccSelect = HealthCardCommand.Select.selectFile(with: aid)
        expect(hccSelect.p1).to(equal(0x4))
        expect(hccSelect.p2).to(equal(0xc))
        expect(hccSelect.data).to(equal(aid.rawValue))
        expect(hccSelect.ne).to(beNil())

        let hccSelect2 = HealthCardCommand .Select.selectFile(with: aid, next: true)
        expect(hccSelect2.p1).to(equal(0x4))
        expect(hccSelect2.p2).to(equal(0xe))

        guard let hccSelect3 = try? HealthCardCommand.Select.selectFileRequestingFcp(with: aid,
                                                                                     expectedLength: 15,
                                                                                     next: true) else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }
        expect(hccSelect3.p1).to(equal(0x4))
        expect(hccSelect3.p2).to(equal(0x6))
        expect(hccSelect3.ne).to(equal(0xf))
    }

    func testSelectDF() {
        let fid = "D276" as FileIdentifier
        let hccSelect = HealthCardCommand.Select.selectDf(with: fid)
        expect(hccSelect.p1).to(equal(0x1))
        expect(hccSelect.p2).to(equal(0xc))
    }

    func testSelectParent() {
        guard let hccSelect = try? HealthCardCommand.Select.selectParentRequestingFcp(expectedLength: 15) else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }
        expect(hccSelect.p1).to(equal(0x3))
        expect(hccSelect.p2).to(equal(0x4))
    }

    func testSelectEF() {
        let fid = "D276" as FileIdentifier
        guard let hccSelect = try? HealthCardCommand.Select.selectEfRequestingFcp(with: fid, expectedLength: 15) else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }
        expect(hccSelect.p1).to(equal(0x2))
        expect(hccSelect.p2).to(equal(0x4))
        expect(hccSelect.ne).to(equal(0xf))
    }

    func testTerminateCardUsage() {
        let hccTerminateCardUsage = HealthCardCommand.TerminateCardUsage.terminateCardUsage()
        expect(hccTerminateCardUsage.cla).to(equal(0x0))
        expect(hccTerminateCardUsage.ins).to(equal(0xfe))
        expect(hccTerminateCardUsage.p1).to(equal(0x0))
        expect(hccTerminateCardUsage.p2).to(equal(0x0))
        expect(hccTerminateCardUsage.ne).to(beNil())
    }

    func testTerminateDf() {
        let hccTerminateDf = HealthCardCommand.TerminateDf.terminateDf()
        expect(hccTerminateDf.cla).to(equal(0x0))
        expect(hccTerminateDf.ins).to(equal(0xe6))
        expect(hccTerminateDf.p1).to(equal(0x0))
        expect(hccTerminateDf.p2).to(equal(0x0))
        expect(hccTerminateDf.ne).to(beNil())
    }

    func testTerminate() {

        let hccTerminate = HealthCardCommand.Terminate.terminateCurrentFile()
        expect(hccTerminate.cla).to(equal(0x0))
        expect(hccTerminate.ins).to(equal(0xe8))
        expect(hccTerminate.p1).to(equal(0x0))
        expect(hccTerminate.p2).to(equal(0x0))
        expect(hccTerminate.ne).to(beNil())
        expect(hccTerminate.responseStatuses.keys).to(contain(ResponseStatus.keyOrPwdNotFound.code))

        guard let key = try? Key(0x3) else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }
        let hccTerminateKeyObject = HealthCardCommand.Terminate.terminate(privateOrSymmetricKey: key, dfSpecific: true)
        expect(hccTerminateKeyObject.ins).to(equal(0xe8))
        expect(hccTerminateKeyObject.p1).to(equal(0x20))
        expect(hccTerminateKeyObject.p2).to(equal(0x83))

        let reference = Data([0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7])
        guard let hccTerminateReference = try? HealthCardCommand
                .Terminate.terminatePublicKey(reference: reference) else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }
        expect(hccTerminateReference.p1).to(equal(0x21))
        expect(hccTerminateReference.p2).to(equal(0x00))
        expect(hccTerminateReference.data).to(equal(Data([0x83, 0x8, 0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7])))

        guard let password = try? Password(0x3) else {
            Nimble.fail("Could not create HealthCardCommand")
            return
        }
        let hccTerminatePassword = HealthCardCommand.Terminate.terminate(password: password, dfSpecific: false)
        expect(hccTerminatePassword.p1).to(equal(0x10))
        expect(hccTerminatePassword.p2).to(equal(0x3))
    }

    static let allTests = [
        ("testActivate", testActivate),
        ("testDeactivate", testDeactivate),
        ("testDelete", testDelete),
        ("testLoadApplication", testLoadApplication),
        ("testSelectRoot", testSelectRoot),
        ("testSelectWithAid", testSelectWithAid),
        ("testSelectDF", testSelectDF),
        ("testSelectParent", testSelectParent),
        ("testSelectEF", testSelectEF),
        ("testTerminateCardUsage", testTerminateCardUsage),
        ("testTerminateDf", testTerminateDf),
        ("testTerminate", testTerminate)
    ]
}
