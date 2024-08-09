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

@testable import CardSimulationCardReaderProvider
import CardSimulationLoader
import Foundation

class MockSimulationManager: SimulationManagerType {
    var delegates = WeakArray<SimulationManagerDelegate>()

    func register(delegate: SimulationManagerDelegate) {
        delegates.add(object: delegate)
    }

    func deregister(delegate: SimulationManagerDelegate) {
        guard let index = delegates.index(of: delegate) else {
            return
        }
        delegates.removeObject(at: index)
        deregister(delegate: delegate)
    }

    func createSimulation(
        configFile _: URL,
        preprocessor _: [XMLPathManipulator],
        simulatorVersion _: String,
        simulatorDirectory _: String
    ) throws -> SimulationRunnerType {
        throw "NotImplemented"
    }

    func stop(simulation _: SimulationRunnerType, waitUntilDone _: Bool) {
        // Do nothing
    }

    func stopAll(waitUntilDone _: Bool) {
        // Do nothing
    }
}
