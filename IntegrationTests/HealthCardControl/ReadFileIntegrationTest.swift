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
import CardSimulationCardReaderProvider
import CardSimulationTerminalTestCase
import DataKit
import Foundation
import GemCommonsKit
import HealthCardAccess
@testable import HealthCardControl
import Nimble
import XCTest

final class ReadFileIntegrationTest: CardSimulationTerminalTestCase {
    static let thisConfigFile = "Configuration/configuration_EGK_G2_1_80276883110000095711_GuD_TCP.xml"

    override class func configFile() -> URL? {
        let bundle = Bundle(for: CardSimulationTerminalTestCase.self)
        let path = bundle.resourceFilePath(in: "Resources", for: self.thisConfigFile)
        return path.asURL
    }

    private let dedicatedFile = DedicatedFile(
            aid: EgkFileSystem.DF.ESIGN.aid,
            fid: EgkFileSystem.EF.esignCChAutR2048.fid
    )
    private var expectedCertificate: Data!

    override func setUp() {
        super.setUp()

        let bundle = Bundle(for: ReadFileIntegrationTest.self)
        let path = bundle.testResourceFilePath(in: "Resources", for: "Certificates/esignCChAutR2048.cer").asURL
        do {
            expectedCertificate = try Data(contentsOf: path)
        } catch let error {
            ALog("Could not read certificate file: \(path)\nError: \(error)")
        }

        _ = HealthCardCommand.Select.selectRoot()
                .execute(on: CardSimulationTerminalTestCase.healthCard)
                .run(on: Executor.trampoline)
                .test()
    }

    func testReadFileTillEOF() {
        guard let (responseStatus, _) = CardSimulationTerminalTestCase.healthCard.selectDedicated(file: dedicatedFile)
                .run(on: Executor.trampoline)
                .test().value else {
            Nimble.fail("Failed to select and read FCP [Preparing test-case]")
            return
        }
        expect(responseStatus) == .success

        let fileResponse = CardSimulationTerminalTestCase.healthCard.readSelectedFile(expected: nil,
                                                                                      failOnEndOfFileWarning: false)
                .run(on: Executor.trampoline)
                .test()

        expect(fileResponse.value) == expectedCertificate
    }

    func testReadFileFailOnEOF() {
        guard let (responseStatus, _) = CardSimulationTerminalTestCase.healthCard.selectDedicated(file: dedicatedFile)
                .run(on: Executor.trampoline)
                .test().value else {
            Nimble.fail("Failed to select and read FCP [Preparing test-case]")
            return
        }
        expect(responseStatus) == .success

        let error = CardSimulationTerminalTestCase.healthCard.readSelectedFile(expected: 2000)
                .run(on: Executor.trampoline)
                .test().error

        if let readError = error as? ReadError {
            expect(readError) == ReadError.unexpectedResponse(state: ResponseStatus.endOfFileWarning)
        } else {
            Nimble.fail("Unexpected error")
        }
    }

    func testReadFile() {
        guard let (responseStatus, fcp) = CardSimulationTerminalTestCase.healthCard.selectDedicated(file: dedicatedFile,
                                                                                                    fcp: true)
                .run(on: Executor.trampoline)
                .test().value else {
            Nimble.fail("Failed to select and read FCP [Preparing test-case]")
            return
        }
        expect(responseStatus) == .success
        expect(fcp).toNot(beNil())

        // swiftlint:disable:next force_unwrapping
        let fileResponse = CardSimulationTerminalTestCase.healthCard.readSelectedFile(expected: Int(fcp!.readSize!),
                                                                                      failOnEndOfFileWarning: true)
                .run(on: Executor.trampoline)
                .test()

        expect(fileResponse.value) == expectedCertificate
    }

    func testReadFileInChunks() {
        guard let card = CardSimulationTerminalTestCase.card as? SimulatorCard else {
            Nimble.fail("This test only works with CardSimulation cards")
            return
        }
        card.maxResponseLength = 256
        guard let healthCard = try? HealthCard(card: card, status: Self.healthCardStatus()) else {
            Nimble.fail("Failed to initialize HealthCard [Preparing test-case]")
            return
        }

        guard let (responseStatus, fcp) = healthCard.selectDedicated(file: dedicatedFile, fcp: true)
                .run(on: Executor.trampoline)
                .test().value else {
            Nimble.fail("Failed to select and read FCP [Preparing test-case]")
            return
        }
        expect(responseStatus) == .success
        expect(fcp).toNot(beNil())

        // swiftlint:disable:next force_unwrapping
        let fileResponse = healthCard.readSelectedFile(expected: Int(fcp!.readSize!), failOnEndOfFileWarning: true)
                .run(on: Executor.trampoline)
                .test()

        expect(fileResponse.value) == expectedCertificate
    }

    func testReadFileInChunksTillEOF() {
        guard let card = CardSimulationTerminalTestCase.card as? SimulatorCard else {
            Nimble.fail("This test only works with CardSimulation cards")
            return
        }
        card.maxResponseLength = 256
        guard let healthCard = try? HealthCard(card: card, status: Self.healthCardStatus()) else {
            Nimble.fail("Failed to initialize HealthCard [Preparing test-case]")
            return
        }

        guard let (responseStatus, fcp) = healthCard.selectDedicated(file: dedicatedFile, fcp: true)
                .run(on: Executor.trampoline)
                .test().value else {
            Nimble.fail("Failed to select and read FCP [Preparing test-case]")
            return
        }
        expect(responseStatus) == .success
        expect(fcp).toNot(beNil())

        let fileResponse = healthCard.readSelectedFile(expected: nil, failOnEndOfFileWarning: false)
                .run(on: Executor.trampoline)
                .test()

        expect(fileResponse.value) == expectedCertificate
    }

    func testReadFileInChunksFailOnEOF() {
        guard let card = CardSimulationTerminalTestCase.card as? SimulatorCard else {
            Nimble.fail("This test only works with CardSimulation cards")
            return
        }
        card.maxResponseLength = 256
        guard let healthCard = try? HealthCard(card: card, status: Self.healthCardStatus()) else {
            Nimble.fail("Failed to initialize HealthCard [Preparing test-case]")
            return
        }

        guard let (responseStatus, _) = healthCard.selectDedicated(file: dedicatedFile)
                .run(on: Executor.trampoline)
                .test().value else {
            Nimble.fail("Failed to select and read FCP [Preparing test-case]")
            return
        }

        expect(responseStatus) == .success

        let fileResponse = healthCard.readSelectedFile(expected: 2000, failOnEndOfFileWarning: true)
                .run(on: Executor.trampoline)
                .test()

        if let readError = fileResponse.error as? ReadError {
            expect(readError) == ReadError.unexpectedResponse(state: ResponseStatus.endOfFileWarning)
        } else {
            Nimble.fail("Unexpected error")
        }

        expect(fileResponse.value).to(beNil())
    }
}
