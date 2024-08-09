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
import Combine
import HealthCardAccess
@testable import HealthCardControl
import Nimble
import Util
import XCTest

final class HealthCardTypeExtESIGNTest: XCTestCase {
    typealias CommandMessageHandler = (CommandType, CardChannelType, TimeInterval, TimeInterval) throws -> ResponseType

    class MockChannel: CardChannelType {
        var card: CardType {
            fatalError("Not implemented")
        }

        var channelNumber: Int = 0
        var extendedLengthSupported = false
        var maxMessageLength: Int = 0x1000
        var maxResponseLength: Int = 0x1000

        let handler: CommandMessageHandler

        init(messageHandler: @escaping CommandMessageHandler) {
            handler = messageHandler
        }

        func transmit(
            command: CommandType,
            writeTimeout: TimeInterval,
            readTimeout: TimeInterval
        ) throws -> ResponseType {
            try handler(command, self, writeTimeout, readTimeout)
        }

        func transmitAsync(
            command: CommandType,
            writeTimeout: TimeInterval,
            readTimeout: TimeInterval
        ) async throws -> ResponseType {
            try handler(command, self, writeTimeout, readTimeout)
        }

        func close() throws {}

        func closeAsync() async throws {}
    }

    class MockHealthCard: HealthCardType {
        private(set) var status: HealthCardStatus
        private(set) var currentCardChannel: CardChannelType

        init(status: HealthCardStatus, currentCardChannel: CardChannelType) {
            self.status = status
            self.currentCardChannel = currentCardChannel
        }
    }

    enum TestError: Swift.Error {
        case unsupportedCommand
    }

    func testReadAutCertificate_publisher() {
        let fcpResourcesPath =
            URL(fileURLWithPath: #file)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Resources.bundle")
                .appendingPathComponent("FCP")
                .appendingPathComponent("fcp_A000000167455349474E.dat")

        // swiftlint:disable:next force_try
        let fcp = try! FileControlParameter.parse(data: fcpResourcesPath.readFileContents())
        let certSize = Int(fcp.size)
        let mockCertificate = Data([UInt8](repeating: 0x55, count: certSize))

        let egkCardStatus = HealthCardStatus.valid(cardType: HealthCardPropertyType.egk(generation: .g2_1))
        let commandHandler: CommandMessageHandler = { command, channel, _, _ in
            let selectCommand = HealthCardCommand.Select.selectFile(with: AutCertInfo.efAutE256.certificate.aid)
                .apduCommand
            let selectEfCommand = try HealthCardCommand.Select.selectEfRequestingFcp(
                with: AutCertInfo.efAutE256.certificate.fid!, // swiftlint:disable:this force_unwrapping
                expectedLength: channel.maxResponseLength
            ).apduCommand
            let readCommand = try HealthCardCommand.Read.readFileCommand(ne: certSize, offset: 0)
            if command == selectCommand {
                return try APDU.Response(body: Data(), sw1: 0x90, sw2: 0x0)
            } else if command == selectEfCommand {
                return try APDU.Response(body: fcpResourcesPath.readFileContents(), sw1: 0x90, sw2: 0x0)
            } else if command == readCommand {
                return try APDU.Response(body: mockCertificate, sw1: 0x90, sw2: 0x0)
            }
            throw TestError.unsupportedCommand
        }
        let channel = MockChannel(messageHandler: commandHandler)
        let card = MockHealthCard(status: egkCardStatus, currentCardChannel: channel)

        var autCertificateResponse: AutCertificateResponse?
        expect {
            autCertificateResponse = try card
                .readAutCertificate()
                .test()
        }.toNot(throwError())
        expect(autCertificateResponse?.info) == .efAutE256
        expect(autCertificateResponse?.certificate) == mockCertificate
    }

    func testReadAutCertificate() async throws {
        let fcpResourcesPath =
            URL(fileURLWithPath: #file)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Resources.bundle")
                .appendingPathComponent("FCP")
                .appendingPathComponent("fcp_A000000167455349474E.dat")

        // swiftlint:disable:next force_try
        let fcp = try! FileControlParameter.parse(data: fcpResourcesPath.readFileContents())
        let certSize = Int(fcp.size)
        let mockCertificate = Data([UInt8](repeating: 0x55, count: certSize))

        let egkCardStatus = HealthCardStatus.valid(cardType: HealthCardPropertyType.egk(generation: .g2_1))
        let commandHandler: CommandMessageHandler = { command, channel, _, _ in
            let selectCommand = HealthCardCommand.Select.selectFile(with: AutCertInfo.efAutE256.certificate.aid)
                .apduCommand
            let selectEfCommand = try HealthCardCommand.Select.selectEfRequestingFcp(
                with: AutCertInfo.efAutE256.certificate.fid!, // swiftlint:disable:this force_unwrapping
                expectedLength: channel.maxResponseLength
            ).apduCommand
            let readCommand = try HealthCardCommand.Read.readFileCommand(ne: certSize, offset: 0)
            if command == selectCommand {
                return try APDU.Response(body: Data(), sw1: 0x90, sw2: 0x0)
            } else if command == selectEfCommand {
                return try APDU.Response(body: fcpResourcesPath.readFileContents(), sw1: 0x90, sw2: 0x0)
            } else if command == readCommand {
                return try APDU.Response(body: mockCertificate, sw1: 0x90, sw2: 0x0)
            }
            throw TestError.unsupportedCommand
        }
        let channel = MockChannel(messageHandler: commandHandler)
        let card = MockHealthCard(status: egkCardStatus, currentCardChannel: channel)

        var autCertificateResponse: AutCertificateResponse?
        autCertificateResponse = try await card.readAutCertificateAsync()
        expect(autCertificateResponse?.info) == .efAutE256
        expect(autCertificateResponse?.certificate) == mockCertificate
    }

    func testReadAutCertificate_unsupportedCardType_publisher() {
        let egkCardStatus = HealthCardStatus.valid(cardType: HealthCardPropertyType.hba(generation: .g2_1))
        let channel = MockChannel { _, _, _, _ in
            throw TestError.unsupportedCommand
        }
        let card = MockHealthCard(status: egkCardStatus, currentCardChannel: channel)

        expect {
            try card.readAutCertificate().test()
        }.to(throwError(HealthCard.Error.unsupportedCardType))
    }

    func testReadAutCertificate_unsupportedCardType() async throws {
        let egkCardStatus = HealthCardStatus.valid(cardType: HealthCardPropertyType.hba(generation: .g2_1))
        let channel = MockChannel { _, _, _, _ in
            throw TestError.unsupportedCommand
        }
        let card = MockHealthCard(status: egkCardStatus, currentCardChannel: channel)

        // todo-nimble update
        expect {
            try card.readAutCertificate().test()
        }.to(throwError(HealthCard.Error.unsupportedCardType))
    }
}
