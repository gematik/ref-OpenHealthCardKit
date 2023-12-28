//
//  Copyright (c) 2023 gematik GmbH
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
import CardSimulationCardReaderProvider
import DataKit
import Foundation
import GemCommonsKit
import HealthCardAccess
@testable import HealthCardControl
import Nimble
import XCTest

final class ReadFileIntegrationTest: CardSimulationTerminalTestCase {
    override class var configFileInput: String {
        "Configuration/configuration_EGK_G2_1_80276883110000095711_GuD_TCP.xml"
    }

    override class var healthCardStatusInput: HealthCardStatus { .valid(cardType: .egk(generation: .g2_1)) }

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
        } catch {
            ALog("Could not read certificate file: \(path)\nError: \(error)")
        }

        do {
            _ = try HealthCardCommand.Select.selectRoot()
                .publisher(for: Self.healthCard)
                .test()
        } catch {
            ALog("Could not execute select root command while setup\nError: \(error)")
        }
    }

    func testReadFileTillEOF() {
        expect {
            let (responseStatus, _) = try Self.healthCard.selectDedicated(file: self.dedicatedFile)
                .test()
            return responseStatus
        } == ResponseStatus.success

        expect {
            try Self.healthCard.readSelectedFile(expected: nil, failOnEndOfFileWarning: false)
                .test()
        } == expectedCertificate
    }

    func testReadFileFailOnEOF() {
        expect {
            let (responseStatus, _) = try Self.healthCard.selectDedicated(file: self.dedicatedFile)
                .test()
            return responseStatus
        } == ResponseStatus.success

        expect {
            try Self.healthCard.readSelectedFile(expected: 2000)
                .test()
        }.to(throwError(ReadError.unexpectedResponse(state: ResponseStatus.endOfFileWarning)))
    }

    func testReadFile() {
        guard let (responseStatus, fcp) = try? Self.healthCard.selectDedicated(file: dedicatedFile, fcp: true)
            .test() else {
            Nimble.fail("Failed to select and read FCP [Preparing test-case]")
            return
        }
        expect(responseStatus) == .success
        expect(fcp).toNot(beNil())

        expect {
            // swiftlint:disable:next force_unwrapping
            try Self.healthCard.readSelectedFile(expected: Int(fcp!.readSize!),
                                                 failOnEndOfFileWarning: true)
                .test()
        } == expectedCertificate
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

        guard let (responseStatus, fcp) = try? healthCard.selectDedicated(file: dedicatedFile, fcp: true)
            .test() else {
            Nimble.fail("Failed to select and read FCP [Preparing test-case]")
            return
        }
        expect(responseStatus) == .success
        expect(fcp).toNot(beNil())

        expect {
            // swiftlint:disable:next force_unwrapping
            try healthCard.readSelectedFile(expected: Int(fcp!.readSize!), failOnEndOfFileWarning: true)
                .test()
        } == expectedCertificate
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

        guard let (responseStatus, fcp) = try? healthCard.selectDedicated(file: dedicatedFile, fcp: true)
            .test() else {
            Nimble.fail("Failed to select and read FCP [Preparing test-case]")
            return
        }
        expect(responseStatus) == .success
        expect(fcp).toNot(beNil())

        expect {
            try healthCard.readSelectedFile(expected: nil, failOnEndOfFileWarning: false)
                .test()
        } == expectedCertificate
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

        expect {
            let (responseStatus, _) = try healthCard.selectDedicated(file: self.dedicatedFile)
                .test()
            return responseStatus
        } == ResponseStatus.success

        expect {
            try healthCard.readSelectedFile(expected: 2000, failOnEndOfFileWarning: true)
                .test()
        }.to(throwError(ReadError.unexpectedResponse(state: ResponseStatus.endOfFileWarning)))
    }
}
