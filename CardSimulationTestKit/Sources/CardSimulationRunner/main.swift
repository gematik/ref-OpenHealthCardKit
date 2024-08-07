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

import CardSimulationLoader
import Foundation
import GemCommonsKit

func main() throws {
    Logger.cardSimulationRunner.debug("Cmdline working directory: [\(FileManager.default.currentDirectoryPath)]")
    Logger.cardSimulationRunner.debug("Cmdline argc: \(CommandLine.argc)")
    Logger.cardSimulationRunner.debug("Cmdline: \(CommandLine.arguments)")
    guard CommandLine.arguments.count > 1 else {
        Logger.cardSimulationRunner.fault("No argument passed for configuration file")
        exit(1)
    }

    let simulatorManager = SimulationManager.shared
    let configFile = CommandLine.arguments[1].asURL
    let configPath = configFile.absoluteURL.deletingLastPathComponent()
    let runner = try simulatorManager.createSimulation(
        configFile: configFile,
        preprocessor: [
            XMLPathManipulatorHolder.tlvPortManipulator(port: "0"),
            XMLPathManipulatorHolder.relativeToAbsolutePathManipulator(with: XMLPathManipulatorHolder
                .CardConfigFileXMLPath, absolutePath: configPath),
            XMLPathManipulatorHolder.relativeToAbsolutePathManipulator(with: XMLPathManipulatorHolder
                .ChannelConfigFileXMLPath, absolutePath: configPath),
        ]
    )
    runner.start(waitUntilLaunched: true)

    // Terminate all simulators
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(2)) {
        SimulationManager.shared.stopAll()
        SimulationManager.shared.clean()
    }

    while !runner.mode.isTerminated {
        RunLoop.current.run(mode: .default, before: Date.distantFuture)
    }

    Logger.cardSimulationRunner.debug("Sleep one seconds")
    Thread.sleep(forTimeInterval: 1)
}

do {
    try main()
} catch {
    Logger.cardSimulationRunner.fault("Exception: \(error)")
}
