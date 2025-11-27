//
// Copyright (Change Date see Readme), gematik GmbH
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// *******
//
// For additional notes and disclaimer from gematik and in case of changes by gematik find details in the "Readme" file.
//

import Foundation
import OSLog

/// Protocol that describes G2-Kartensimulation Configuration files (pre-)processors
public protocol ConfigurationFileProcessor {
    /// The return type after preparing the config file
    associatedtype Processed

    /**
        Prepare the configuration for the simulation runtime by mutating its original contents with the `manipulators`.

        - Parameters:
            - manipulators: The XMLManipulators for the specified XML paths

        - Returns: Result<R>
     */
    func prepareXMLConfigFile(with manipulators: [XMLPathManipulator]) -> Result<Processed, Swift.Error>
}

/// Delegate protocol to inform about start/stopped SimulationRunners
public protocol SimulationManagerDelegate: AnyObject {
    /**
        Invoked when a `SimulationManagerType` has started a `SimulationRunnerType`

        - Parameters:
            - manager: the managing manager
            - simulator: the newly started simulation
     */
    func simulation(manager: SimulationManagerType, didStart simulator: SimulationRunnerType)

    /**
        Invoked when a `SimulationRunnerType` has terminated or 'failed' to launch and therefore terminated.

        - Note: that it is possible to get a 'didEnd' notification without a prior 'didStart' notification.

        - Parameters:
            - manager: the managing manager
            - simulator: the terminated simulation
     */
    func simulation(manager: SimulationManagerType, didEnd simulator: SimulationRunnerType)
}

/// SimulationManagerType that allows delegates to register for `SimulationRunnerType` updates
public protocol SimulationManagerType {
    /// Register a delegate to get updated on `SimulationRunnerType`s
    /// - Parameter delegate: the delegate to add
    func register(delegate: SimulationManagerDelegate)
    /// De-register a delegate to get updated on `SimulationRunnerType`s
    /// - Parameter delegate: the delegate to remove
    func deregister(delegate: SimulationManagerDelegate)

    /**
        Create a simulator runner instance.

        - Note: The Simulation should be configured and dependencies may have been downloaded/running.
                But the SimulationRunnerType itself should not have been launched yet.

        - Parameters:
            - configFile: the URL to the main G2-Kartensimulation configFile
            - manipulators: list of `XMLPathManipulator`s to manipulate configFile
            - simulatorVersion: the *de.gematik.egk.g2sim.product* artifacts version to download/use
            - simulatorDirectory: the path to append to the transient directory where the artifacts need to be stored
            - flag: indicate whether to wait until the JavaProcess has finished launching and initializing.

        - Throws: when the configuration in malformed and/or the simulator couldn't be launched.

         - Returns: the SimulationRunner instance that monitors the launched simulator.
     */
    func createSimulation(
        configFile: URL,
        preprocessor manipulators: [XMLPathManipulator],
        simulatorVersion: String,
        simulatorDirectory: String
    ) throws -> SimulationRunnerType

    /**
        Stop the passed simulation and deregister from the manager when needed.

        - Parameters:
            - simulation: the simulation (process) to stop
            - flag: indicate whether this function should wait until the process has terminated
     */
    func stop(simulation: SimulationRunnerType, waitUntilDone flag: Bool)

    /**
        Stop all simulation instances registered with this manager.

        - Parameter flag: indicate whether this function should wait until all the processes have been terminated
     */
    func stopAll(waitUntilDone flag: Bool)
}

/**
    Main class that provides `SimulationRunner`s when launching G2-Kartensimulations.
 */
public class SimulationManager {
    /// Singleton instance of `SimulationManager`
    public static let shared = {
        SimulationManager(tempDir: NSTemporaryDirectory().asURL.appendingPathComponent(
            ProcessInfo.processInfo.globallyUniqueString, isDirectory: true
        ))
    }()

    /// The default G2-Kartensimulation version
    public static let defaultVersion = "2.8.4-436"

    private var _delegates = WeakArray<SimulationManagerDelegate>()

    private var _runners: [(url: URL, simulator: SimulationRunnerType)] = []

    /// Currently running `SimulationRunnerType`s
    public var runners: [SimulationRunnerType] {
        _runners.map(\.simulator)
    }

    private let tempDirectory: URL

    /// Initialize a SimulationManager with a custom tempDir if needed.
    ///
    /// - SeeAlso: `SimulationManager.shared` for general purpose use
    ///
    /// - Parameters:
    ///     - tempDir: path to a directory to be used as temporary directory for storing dependencies and configuration.
    /// - Returns: a new SimulationManger
    public init(tempDir: URL) {
        Logger.cardSimulationLoader.debug("Init with tempDir: [\(tempDir)]")
        tempDirectory = tempDir
    }

    /**
        Start a simulation instance.

        - Parameters:
            - configFile: the URL to the main G2-Kartensimulation configFile
            - manipulators: list of `XMLPathManipulator`s to manipulate configFile
            - simulatorVersion: the *de.gematik.egk.g2sim.product* artifacts version to download/use
            - simulatorDirectory: the path to append to the transient directory where the artifacts need to be stored
            - flag: indicate whether to wait until the JavaProcess has finished launching and initializing.

        - Throws: when the configuration in malformed and/or the simulator couldn't be launched.

         - Returns: the SimulationRunner instance that monitors the launched simulator.
     */
    public func createSimulation(
        configFile: URL,
        preprocessor manipulators: [XMLPathManipulator] = [],
        simulatorVersion: String = defaultVersion,
        simulatorDirectory: String = "simulator"
    ) throws -> SimulationRunnerType {
        let simPath = tempDirectory.appendingPathComponent(simulatorDirectory, isDirectory: true)
        let pomXml = try Data(contentsOf: Bundle(for: SimulationManager.self)
            .resourceFilePath(in: "Resources", for: "pom.xml").asURL)

        // Load simulator dependencies
        return try SimulationManager.loadCardSimulatorDependencies(
            version: simulatorVersion,
            outputDirectory: simPath,
            pom: pomXml
        )
        .flatMap { dependencyInfo in
            // Prepare Simulator XML configuration
            configFile.prepareXMLConfigFile(with: manipulators)
                .flatMap { [unowned self] simConfigDoc in
                    Result {
                        try simConfigDoc.createXML()
                    }
                    .flatMap { (xmlData: Data) in
                        xmlData.save(to: self.tempFile(for: configFile))
                            .flatMap { [unowned self] result in
                                // Start/Run the simulator instance
                                Result {
                                    try self.manageSimulation(simulator: result.url, dependency: dependencyInfo)
                                }
                            }
                    }
                }
        }
        .get()
    }

    // Create and Manage the SimulationRunner (but not yet launch it)
    func manageSimulation(
        simulator file: URL, dependency info: SimulationManager.DependencyInfo
    ) throws -> SimulationRunnerType {
        guard let simClassPath = info.simulatorClassPath else {
            throw SimulationLoaderError.malformedConfiguration
        }
        let currentDir = FileManager.default.currentDirectoryPath.asURL
        let simulator = SimulationRunner(simulator: file, classPath: simClassPath, workingDirectory: currentDir)
        simulator.delegate = self
        _runners.append((url: file, simulator: simulator))
        return simulator
    }

    /**
        Stop the passed simulation and deregister from the manager when needed.

        - Parameters:
            - simulation: the simulation (process) to stop
            - flag: indicate whether this function should wait until the process has terminated
     */
    public func stop(simulation: SimulationRunnerType, waitUntilDone flag: Bool = true) {
        simulation.stop(waitUntilTerminated: flag)
        remove(simulation: simulation)
    }

    /**
        Stop all simulation instances registered with this manager.

        - Parameter flag: indicate whether this function should wait until all the processes have been terminated
     */
    public func stopAll(waitUntilDone flag: Bool = true) {
        Logger.cardSimulationLoader.debug("Stop all simulators")
        runners.forEach { [unowned self] in
            self.stop(simulation: $0, waitUntilDone: flag)
        }
    }

    private func remove(simulation: SimulationRunnerType) {
        /// clean the temp files for this SimulationRunnerType
        _runners.filter {
            $0.1 === simulation
        }
        .forEach {
            Logger.cardSimulationLoader.debug("Cleaning: \($0.url)")
            do {
                try FileManager.default.removeItem(at: $0.url)
            } catch {
                Logger.cardSimulationLoader.fault("Failed to clean simulator runner environment: [\(error)]")
            }
        }
        /// Remove the simulation from the runners array
        _runners.removeAll {
            $0.1 === simulation
        }
        /// Inform delegates
        _delegates.array.forEach {
            $0.simulation(manager: self, didEnd: simulation)
        }
    }

    /**
        Clean and remove all transient files and artifacts associated with this instance.
     */
    public func clean() {
        do {
            try FileManager.default.removeItem(at: tempDirectory)
        } catch {
            Logger.cardSimulationLoader.fault("Failed to clean [\(error)]")
        }
    }
}

extension SimulationManager: SimulationManagerType {
    /// Register a delegate to get updated on `SimulationRunnerType`s
    /// - Parameter delegate: the delegate to add
    public func register(delegate: SimulationManagerDelegate) {
        if _delegates.index(of: delegate) == nil {
            _delegates.add(object: delegate)
            _runners.forEach { [unowned self] in
                delegate.simulation(manager: self, didStart: $0.simulator)
            }
        }
    }

    /// De-register a delegate to get updated on `SimulationRunnerType`s
    /// - Parameter delegate: the delegate to remove
    public func deregister(delegate: SimulationManagerDelegate) {
        guard let index = _delegates.index(of: delegate) else {
            return // Not in delegate array
        }
        _delegates.removeObject(at: index)
    }
}

extension SimulationManager: TempFilePathGeneratorType {
    func tempFile(for path: URL) -> URL {
        tempDirectory
            .appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)
            .appendingPathComponent(path.lastPathComponent)
    }
}

extension SimulationManager: SimulationRunnerDelegate {
    /**
        Simulation manager's delegate for the runner.
     */
    public func simulation(runner: SimulationRunnerType, changed mode: SimulationProcessMode) {
        let runnerDescription = runner.description
        Logger.cardSimulationLoader.debug("Simulation: \(runnerDescription) -> [\(mode)]")
        if mode.isRunning {
            /// Inform delegates
            _delegates.array.forEach {
                $0.simulation(manager: self, didStart: runner)
            }
        } else if mode.isTerminated {
            remove(simulation: runner)
        }
    }
}
