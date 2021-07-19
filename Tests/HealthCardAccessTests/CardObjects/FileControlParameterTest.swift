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

import GemCommonsKit
@testable import HealthCardAccess
import Nimble
import XCTest

final class FileControlParameterTest: XCTestCase {
    func testUnknownLCS() {
        expect(FileControlParameter.LifeCycleState.parseLifeCycle(byte: 0x0)) == .unknown
    }

    func testActivatedLCS() {
        expect(FileControlParameter.LifeCycleState.parseLifeCycle(byte: 0x5)) == .activated
        expect(FileControlParameter.LifeCycleState.parseLifeCycle(byte: 0x7)) == .activated
    }

    func testCreatedLCS() {
        expect(FileControlParameter.LifeCycleState.parseLifeCycle(byte: 0x1)) == .creation
    }

    func testInitialisedLCS() {
        expect(FileControlParameter.LifeCycleState.parseLifeCycle(byte: 0x3)) == .initialisation
    }

    func testDeactivatedLCS() {
        expect(FileControlParameter.LifeCycleState.parseLifeCycle(byte: 0x4)) == .deactivated
        expect(FileControlParameter.LifeCycleState.parseLifeCycle(byte: 0x6)) == .deactivated
    }

    func testProprietaryLCS() {
        for byte: UInt8 in 0x10 ... 0xFF {
            expect(FileControlParameter.LifeCycleState.parseLifeCycle(byte: byte)) == .proprietary
        }
    }

    func testTerminatedLCS() {
        expect(FileControlParameter.LifeCycleState.parseLifeCycle(byte: 0xC)) == .terminated
        expect(FileControlParameter.LifeCycleState.parseLifeCycle(byte: 0xD)) == .terminated
        expect(FileControlParameter.LifeCycleState.parseLifeCycle(byte: 0xE)) == .terminated
        expect(FileControlParameter.LifeCycleState.parseLifeCycle(byte: 0xF)) == .terminated
    }

    func testInvalidLCS() {
        expect(FileControlParameter.LifeCycleState.parseLifeCycle(byte: 0x8)).to(beNil())
        expect(FileControlParameter.LifeCycleState.parseLifeCycle(byte: 0x2)).to(beNil())
    }

    private let bundle = Bundle(for: FileControlParameterTest.self)

    func testFCP_DF() {
        // dfName == 0xD2760001448000
        // fileDescriptor == 0x78
        // life cycle == 5 activated
        // nettLength  == 0xFFFFFFFF
        // totalLength == 0xFFFFFFFF
        // fileIdentifier == 0x3F00

        let filePath = bundle.testResourceFilePath(in: "Resources", for: "FCP/fcp_df_A000000167455349474E_apdu.dat")
        guard let responseData = try? filePath.readFileContents() else {
            fatalError("FCP/fcp_df_A000000167455349474E_apdu.dat could not be read")
        }

        guard let fcp = try? FileControlParameter.parse(data: responseData) else {
            Nimble.fail("Could not parse FCP")
            return
        }

        expect(fcp.applicationIdentifier) == "D2760001448000"
        expect(fcp.fileDescriptor) == "78"
        expect(fcp.status) == .activated
        expect(fcp.size) == 0
        expect(fcp.readSize).to(beNil())
        expect(fcp.fileIdentifier) == "3F00"
        expect(fcp.shortFileIdentifier).to(beNil())
    }

    func testFCP_ADF() {
        // dfName == 0xA000000167455349474E
        // fileDescriptor == 0x78
        // life cycle == 5 (activated)
        // nettLength  == 0xFFFFFFFF
        // totalLength == 0xFFFFFFFF
        // fileIdentifier == NULL

        let filePath = bundle.testResourceFilePath(in: "Resources", for: "FCP/fcp_adf_A000000167455349474E_apdu.dat")
        guard let responseData = try? filePath.readFileContents() else {
            fatalError("FCP/fcp_adf_A000000167455349474E_apdu.dat could not be read")
        }
        guard let fcp = try? FileControlParameter.parse(data: responseData) else {
            Nimble.fail("Could not parse FCP")
            return
        }
        expect(fcp.applicationIdentifier) == "A000000167455349474E"
        expect(fcp.fileDescriptor) == "78"
        expect(fcp.status) == .activated
        expect(fcp.size) == 0
        expect(fcp.readSize).to(beNil())
        expect(fcp.fileIdentifier).to(beNil())
    }

    func testFCP_nettLength() {
        // dfName == NULL
        // fileDescriptor == 0x41
        // life cycle == 5 activated
        // nettLength  == 0x0C
        // totalLength == 0xFFFFFFFF
        // fileIdentifier == 0x2F02

        let filePath = bundle.testResourceFilePath(in: "Resources", for: "FCP/fcp_nett_length_apdu.dat")
        guard let responseData = try? filePath.readFileContents() else {
            fatalError("FCP/fcp_nett_length_apdu.dat could not be read")
        }

        guard let fcp = try? FileControlParameter.parse(data: responseData) else {
            Nimble.fail("Could not parse FCP")
            return
        }
        expect(fcp.applicationIdentifier).to(beNil())
        expect(fcp.fileDescriptor) == "41"
        expect(fcp.status) == .activated
        expect(fcp.size) == 0xD
        expect(fcp.readSize) == 0xC
        expect(fcp.fileIdentifier) == "2F02"
        expect(fcp.shortFileIdentifier) == "02"
    }

    static let allTests = [
        ("testUnknownLCS", testUnknownLCS),
        ("testCreatedLCS", testCreatedLCS),
        ("testInitialisedLCS", testInitialisedLCS),
        ("testActivatedLCS", testActivatedLCS),
        ("testDeactivatedLCS", testDeactivatedLCS),
        ("testProprietaryLCS", testProprietaryLCS),
        ("testTerminatedLCS", testTerminatedLCS),
        ("testInvalidLCS", testInvalidLCS),
        ("testFCP_DF", testFCP_DF),
        ("testFCP_ADF", testFCP_ADF),
        ("testFCP_nettLength", testFCP_nettLength),
    ]
}
