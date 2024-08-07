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

public class SimulatorCardReader: CardReaderType {
    public enum CardReaderError: Error {
        case simulatorNotRunning
    }

    typealias CardPresentBlock = (CardReaderType) -> Void

    public var name: String {
        mode.simulationName(on: _host)
    }

    public var cardPresent: Bool {
        mode.isRunning
    }

    internal let simulationRunner: SimulationRunnerType
    private var _prevMode: SimulationProcessMode?
    private var _cardPresentBlock: CardPresentBlock?
    private let _host: String

    var mode: SimulationProcessMode {
        simulationRunner.mode
    }

    init(cardReader runner: SimulationRunnerType, host: String = "localhost") {
        simulationRunner = runner
        _host = host
        checkRunnerModeDidChange()
    }

    public func onCardPresenceChanged(_ block: @escaping (CardReaderType) -> Void) {
        _cardPresentBlock = block
        if mode.isRunning {
            block(self)
        }
    }

    public func connect(_: [String: Any]) throws -> CardType? {
        try connect(protocol: .t1)
    }

    public func connect(protocol: CardProtocol) throws -> CardType {
        guard let port = simulationRunner.mode.tlvPort else {
            throw CardReaderError.simulatorNotRunning
        }
        return SimulatorCard(host: _host, port: port, channel: `protocol`)
    }

    internal func checkRunnerModeDidChange() {
        let currentMode = mode
        if currentMode != _prevMode {
            defer {
                _prevMode = currentMode
            }
            if currentMode.isRunning {
                _cardPresentBlock?(self)
            }
        }
    }

    public var description: String {
        "SimulatorCardReader: \(name)"
    }
}

extension SimulationProcessMode {
    internal func simulationName(prefix: String = "cardsim", on host: String) -> String {
        switch self {
        case let .running(onTCPPort): return "\(prefix)-\(host)-\(onTCPPort)"
        case .terminated: return "\(prefix)-\(host)-x"
        case .initializing: return "\(prefix)-\(host)-?"
        case .notStarted: return "\(prefix)-\(host)-?"
        }
    }
}
