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

import CardReaderAccess
import CardReaderProviderApi
import CardSimulationCardReaderProvider
import CardSimulationLoader
import Foundation
import GemCommonsKit

/// Wrapper around a resource that holds the configuration for a G2-Kartensimulation Runner
/// which features startUp and shutDown the SimulationRunner
public class CardSimulationTerminalResource {
    private let configFile: URL
    private var runner: SimulationRunnerType?
    private let configManipulators: [XMLPathManipulator]
    private let version: String

    private let _connectedReader = BlockingVar<CardReaderType>()
    var reader: CardReaderType {
        _connectedReader.value
    }

    /// Create a CardSimulatorTerminalResource
    ///
    /// - Parameters:
    ///     - url: The simulation config for the SimulationRunner
    ///     - configManipulators: manipulators for the above configFile. Default []
    ///     - manager: CardTerminalControllerManager that manages the CardReaderProvider implementers. Default: shared
    ///     - simulatorVersion: G2-Kartensimulation version. Default 2.7.6-352
    public required init(
        url: URL,
        configManipulators: [XMLPathManipulator] = [],
        manager: CardReaderControllerManagerType = CardReaderControllerManager.shared,
        simulatorVersion: String = "2.7.8-378"
    ) {
        configFile = url
        self.configManipulators = configManipulators
        version = simulatorVersion
        manager.cardReaderControllers
            .filter {
                $0.name == SimulatorCardReaderProvider.name
            }
            .forEach { [unowned self] in
                $0.add(delegate: self)
            }
    }

    /// Start the simulator runner and connect the CardTerminalType that connects to the launch G2-Kartensimulator
    ///
    /// - Parameters:
    ///     - flag: whether to pause execution till the SimulationRunner has been launched. Default `true`
    ///     - manager: SimulationManager to create and manager the Runner instance. Default shared
    public func startUp(wait flag: Bool = true, manager: SimulationManagerType = SimulationManager.shared) throws {
        runner = try manager.createSimulation(
            configFile: configFile,
            preprocessor: configManipulators,
            simulatorVersion: version,
            simulatorDirectory: "simulator"
        )
        runner?.start(waitUntilLaunched: flag)
    }

    /// Shutdown the running runner
    ///
    /// - Parameter flag: whether to pause execution till the runner has been terminated
    public func shutDown(wait flag: Bool = true) {
        guard let runner = runner else {
            DLog("Not running?")
            return
        }
        runner.stop(waitUntilTerminated: flag)
        self.runner = nil
    }

    /// deinit
    deinit {
        runner?.stop(waitUntilTerminated: false)
    }
}

extension CardSimulationTerminalResource: CardReaderControllerDelegate {
    public func cardReader(controller _: CardReaderControllerType, didConnect reader: CardReaderType) {
        DLog("We got a reader: \(reader.name)")
        guard let runnerPort = runner?.tlvPort else {
            return
        }
        if reader.name.hasSuffix("\(runnerPort)") {
            _connectedReader.value = reader
        }
    }

    public func cardReader(controller _: CardReaderControllerType, didDisconnect reader: CardReaderType) {
        DLog("We lost a reader: \(reader)")
        if reader === _connectedReader.value {
            _connectedReader.value = DisconnectedTerminal(reader: reader)
        }
    }
}

class DisconnectedTerminal: CardReaderType {
    let name: String
    var cardPresent: Bool { false }
    let card: CardType

    init(reader: CardReaderType) {
        name = "Disconnected: \(reader.name)"
        card = DisconnectedCard()
    }

    func onCardPresenceChanged(_: @escaping (CardReaderType) -> Void) {}

    func connect(_: [String: Any]) throws -> CardType? {
        card
    }

    func connect(protocol _: CardProtocol) throws -> CardType {
        card
    }
}

class DisconnectedCard: CardType {
    struct Error: Swift.Error {
        let description: String
    }

    let atr: ATR
    let `protocol`: CardProtocol

    init() {
        atr = Data.empty
        self.protocol = CardProtocol(rawValue: 0)
    }

    func openBasicChannel() throws -> CardChannelType {
        throw Error(description: "[DisconnectedCard] openBasicChannel() has not been implemented")
    }

    func openLogicChannel() throws -> CardChannelType {
        throw Error(description: "[DisconnectedCard] openLogicChannel() has not been implemented")
    }

    func openLogicChannelAsync() async throws -> CardReaderProviderApi.CardChannelType {
        throw Error(description: "[DisconnectedCard] openBasicChannel() has not been implemented")
    }

    func disconnect(reset _: Bool) throws {
        throw Error(description: "[DisconnectedCard] disconnect() has not been implemented")
    }
}
