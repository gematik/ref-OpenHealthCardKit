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
import CardSimulationLoader
import Foundation
import GemCommonsKit
import HealthCardAccess
import XCTest

/// 'Abstract' `XCTestCase` that prepares and sets up a G2-Kartensimulator (through `CardSimulationLoader`)
/// and a CardReaderProvider (through CardSimulationCardReaderProvider) to access the `CardType` and `CardChannelType`.
///
/// - Note: The card type and the content of the image that the card simulation uses is configurable.
///     The conveniently overridable properties are `configFileInput` and `healthCardStatusInput`,
///     for more sophisticated configuration you can override the functions `configFile()` and `healthCardStatus()`
class CardSimulationTerminalTestCase: XCTestCase {
    // Convenience default config input - override these in subclasses if needed
    class var configFileInput: String { "Configuration/configuration_EGKG2_80276883110000017222_gema5_TCP.xml" }
    class var healthCardStatusInput: HealthCardStatus { .valid(cardType: .egk(generation: .g2)) }

    #if os(macOS) || os(Linux)
    static var terminalResource: CardSimulationTerminalResource!
    static var reader: CardReaderType!
    static var card: CardType!
    static var healthCard: HealthCard!
    #endif

    class func configFile() -> URL? {
        let bundle = Bundle(for: CardSimulationTerminalTestCase.self)
        guard let url = bundle.resourceURL?
            .appendingPathComponent("Resources.bundle")
            .appendingPathComponent(configFileInput) else {
            return nil
        }
        return url
    }

    class func healthCardStatus() -> HealthCardStatus {
        healthCardStatusInput
    }

    #if os(macOS) || os(Linux)
    class func createTerminalResource() -> CardSimulationTerminalResource {
        guard let config = configFile() else {
            fatalError("No configFile")
        }
        let absolutePath = config.deletingLastPathComponent()
        let cardImagePath = XMLPathManipulatorHolder.relativeToAbsolutePathManipulator(
            with: XMLPathManipulatorHolder.CardConfigFileXMLPath,
            absolutePath: absolutePath
        )
        let channelContextPath = XMLPathManipulatorHolder.relativeToAbsolutePathManipulator(
            with: XMLPathManipulatorHolder.ChannelConfigFileXMLPath,
            absolutePath: absolutePath
        )
        let manipulators = [cardImagePath, channelContextPath]
        return CardSimulationTerminalResource(url: config,
                                              configManipulators: manipulators,
                                              simulatorVersion: "2.8.4-436")
    }
    #endif

    #if os(macOS) || os(Linux)
    override class func setUp() {
        super.setUp()
        terminalResource = createTerminalResource()
        do {
            try terminalResource.startUp()
        } catch {
            preconditionFailure("We cant start simulation runner: \(error)")
        }

        reader = CardSimulationTerminalTestCase.terminalResource.reader
        do {
            try connectCard()
        } catch {
            preconditionFailure("CardTerminal could not connect card [\(error)]")
        }
    }

    override class func tearDown() {
        terminalResource.shutDown()

        RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 3))
        SimulationManager.shared.clean()

        super.tearDown()
    }
    #endif

    override func setUp() {
        super.setUp()
        do {
            try createHealthCard()
        } catch {
            ALog("Could not create HealthCard: \(error)")
        }
    }

    override func tearDown() {
        do {
            try disconnectCard()
        } catch {
            ALog("Could not disconnect card: \(error)")
        }
        super.tearDown()
    }

    #if os(macOS) || os(Linux)
    class func connectCard() throws {
        card = try reader.connect([:])
    }

    func createHealthCard() throws {
        Self.healthCard = try HealthCard(card: Self.card, status: Self.healthCardStatus())
    }

    func disconnectCard() throws {
        try Self.card.disconnect(reset: true)
    }
    #endif
}
