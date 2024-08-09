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
import StreamReader

/// Protocol that describes `SimulationRunnerType` behaviour.
public protocol SimulationRunnerType: AnyObject, CustomStringConvertible {
    /// The mode the runner is currently in
    var mode: SimulationProcessMode { get }

    /// Launch the `SimulationRunnerType` - assuming did not run before
    /// - Parameter waitUntilLaunched:
    ///     indicate whether the function should wait until the process has finished launching
    func start(waitUntilLaunched: Bool)

    /// Stop the `SimulationRunnerType`
    /// - Parameter waitUntilLaunched:
    ///     indicate whether the function should wait until the process has finished terminating
    func stop(waitUntilTerminated: Bool)
}

/// Delegate protocol gets informed on `SimulationProcessMode` changes for a given `SimulationRunnerType`
public protocol SimulationRunnerDelegate: AnyObject {
    /**
        Invoked on a delegate when the run mode changes.

        - Parameters:
            - runner: the simulation for which the mode has changed
            - mode: the new/current process mode
     */
    func simulation(runner: SimulationRunnerType, changed mode: SimulationProcessMode)
}

/**
    This class takes care of launching a `JavaProcess` and building its configuration
    and thereafter monitor its process state.
 */
public class SimulationRunner {
    private let _mode = SynchronizedVar<SimulationProcessMode>(.notStarted)
    private let javaClassPath: URL
    private let simulatorConfig: URL
    private let workingDirectory: URL
    internal let processThread: KeepAliveRunLoop
    internal var processLoader: JavaProcess?
    internal lazy var stdoutInfo: (pipe: Pipe, reader: StreamReader) = {
        let pipe = Pipe()

        let delimiterData = "\n".data(using: .utf8) ?? Data()
        // Note chunkSize = 1 else  the StreamReader will block until the chunk is filled, blocking this Runner to
        // detect a successful start indefinitely
        return (pipe, StreamReader(fileHandle: pipe.fileHandleForReading,
                                   delimiterData: delimiterData,
                                   encoding: .utf8,
                                   chunkSize: 1))
    }()

    internal var streamThread: KeepAliveRunLoop!

    /// The delegate that gets informed when `self.mode` changes
    public weak var delegate: SimulationRunnerDelegate?

    /**
        The designated initializer.

        - Parameters:
            - file: configuration file
            - classPath: the path to the G2-Kartensimulation artifacts
            - dir: the working directory for the JavaProcess to be launched. Default is `FileManager.currentDirectory`
            - thread: the thread wherein to monitor the process' state and (initialization) progress. Default a new
                   `KeepAliveRunLoop`.
     */
    public required init(simulator file: URL,
                         classPath: URL,
                         workingDirectory dir: URL,
                         in thread: KeepAliveRunLoop = KeepAliveRunLoop()) {
        simulatorConfig = file
        javaClassPath = classPath
        processThread = thread
        workingDirectory = dir
    }

    internal lazy var config = JavaProcess.Config.build(
        workingDirectory: workingDirectory.absoluteURL.path,
        classPath: javaClassPath.absoluteURL.path + "/*",
        arguments: ["-configFile", simulatorConfig.absoluteURL.path]
    )

    /// Deinit
    deinit {
        if mode.isRunning {
            stop(waitUntilTerminated: false)
        }
    }
}

extension SimulationRunner: SimulationRunnerType {
    /// Current runner mode
    public internal(set) var mode: SimulationProcessMode {
        get {
            _mode.value
        }
        set {
            _mode.set { _ in newValue }
            delegate?.simulation(runner: self, changed: newValue)
        }
    }

    /// Start the simulation runner
    /// - Parameter flag: whether to pause further execution until the JavaProcess has been (successfully) launched.
    public func start(waitUntilLaunched flag: Bool) {
        guard mode.isNotRunning else {
            Logger.cardSimulationLoader.debug("WARN: double start")
            return
        }
        mode = .initializing

        let process = JavaProcess(config: config, stdout: stdoutInfo.pipe, stderr: stdoutInfo.pipe)
        processThread.start()
        process.run(in: processThread.runloop, delegate: self)
        processLoader = process

        if flag {
            while !mode.isRunning && !mode.isTerminated {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
            }
        }

        Logger.cardSimulationLoader.debug("start END")
    }

    /// Stop the simulation runner
    /// - Parameter flag: whether to pause further execution until the JavaProcess has been terminated.
    public func stop(waitUntilTerminated flag: Bool) {
        Logger.cardSimulationLoader.debug("Simulator runner STOP [wait:\(String(describing: flag))]")
        processLoader?.terminate(waitUntilDone: flag)
    }

    public var description: String {
        "SimulationRunner: \(mode)"
    }
}
