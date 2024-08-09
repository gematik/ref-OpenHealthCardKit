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

import Foundation
import OSLog

extension SimulationRunner: JavaProcessUpdateDelegate {
    func processDidLaunch(_: JavaProcess, pid: Int32) {
        Logger.cardSimulationLoader.debug("Simulator process launched PID: [\(pid)]")
        streamThread = KeepAliveRunLoop()
        streamThread.start()
        streamThread.runloop.perform(inModes: [.default]) { [unowned self] in
            if Thread.current === Thread.main {
                preconditionFailure("New thread runs on Main thread")
            }

            Logger.cardSimulationLoader.debug("Card simulator: [STREAM START]")

            var tcpPort: Int32?
            var successfullyLaunched = false
            // Add NSException handler around stdout reader since it can throw NSFileHandleOperationException
            // that are not caught by Swift's try
            if let exception = gemTryBlock({
                var line = self.stdoutInfo.reader.nextLine()
                repeat {
                    Logger.cardSimulationLoader.debug("Card simulator: [\(String(describing: line))]")
                    if let line = line, !successfullyLaunched {
                        // Check for TCP TLV interface port
                        if tcpPort == nil, let port = line.match(pattern: "TCPIP: TLV Interface at Port (\\d*)$",
                                                                 group: 1) {
                            tcpPort = Int32(port)
                        }
                        successfullyLaunched = line == "Simulation started successfully."
                    }

                    // !mode.isRunning means mode.isInitializing = true
                    if !self.mode.isRunning, successfullyLaunched, let tcpPort = tcpPort {
                        Logger.cardSimulationLoader.debug("Simulator started successfully in port [\(tcpPort)]")
                        self.mode = .running(onTCPPort: tcpPort)
                    } else if successfullyLaunched {
                        tcpPort = 12350 // G2-Kartensimulation does not log default TLV port 12350
                    }

                    line = self.stdoutInfo.reader.nextLine()
                } while line != nil
            }) {
                // Caught NSException
                Logger.cardSimulationLoader.fault("Raised NSException while reading Process stdout")
                Logger.cardSimulationLoader.debug("NSException: \(exception)")
            }

            Logger.cardSimulationLoader.debug("Card simulator: [STREAM END]")
        }
    }

    func processDidTerminate(_: JavaProcess, with status: Int32) {
        mode = .terminated(terminationStatus: status)
        let statusDescription = status.description
        let configDescription = config.description
        Logger.cardSimulationLoader
            .debug("Simulator process ended with: [\(statusDescription)] - [CONFIG: \(configDescription)]")
        processThread.cancel()
        streamThread.cancel()
        stdoutInfo.reader.close()
        processLoader = nil
    }
}
