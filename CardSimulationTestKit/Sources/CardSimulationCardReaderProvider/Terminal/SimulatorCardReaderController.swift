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

public class SimulatorCardReaderController: CardReaderControllerType {
    public let name = SimulatorCardReaderProvider.name

    private let simulationManager: SimulationManagerType
    private let cardReaderDelegates = WeakArray<CardReaderControllerDelegate>()
    private var simulatorCardReaders = [SimulatorCardReader]()

    init(manager: SimulationManagerType) {
        simulationManager = manager

        simulationManager.register(delegate: self)
    }

    deinit {
        simulationManager.deregister(delegate: self)
    }

    public var cardReaders: [CardReaderType] {
        simulatorCardReaders.map { $0 }
    }

    public func add(delegate: CardReaderControllerDelegate) {
        if cardReaderDelegates.index(of: delegate) == nil {
            cardReaderDelegates.add(object: delegate)
            simulatorCardReaders.forEach { cardReader in
                delegate.cardReader(controller: self, didConnect: cardReader)
            }
        }
    }

    public func remove(delegate: CardReaderControllerDelegate) {
        guard let index = cardReaderDelegates.index(of: delegate) else {
            return
        }
        cardReaderDelegates.removeObject(at: index)
    }
}

extension SimulatorCardReaderController: SimulationManagerDelegate {
    public func simulation(manager _: SimulationManagerType, didStart simulator: SimulationRunnerType) {
        let cardReader = SimulatorCardReader(cardReader: simulator)
        simulatorCardReaders.append(cardReader)
        cardReaderDelegates.array.forEach {
            $0.cardReader(controller: self, didConnect: cardReader)
        }
    }

    public func simulation(manager _: SimulationManagerType, didEnd simulator: SimulationRunnerType) {
        let predicate: (SimulatorCardReader) -> Bool = { cardReader in cardReader.simulationRunner === simulator }
        if let cardReader = simulatorCardReaders.first(where: predicate) {
            cardReaderDelegates.array.forEach { delegate in
                delegate.cardReader(controller: self, didDisconnect: cardReader)
            }
        }
        simulatorCardReaders.removeAll {
            $0.simulationRunner === simulator
        }
    }
}
