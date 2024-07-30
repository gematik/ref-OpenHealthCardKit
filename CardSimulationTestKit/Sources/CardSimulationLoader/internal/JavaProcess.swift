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
import GemCommonsKit

protocol JavaProcessConfig {
    #if os(macOS) || os(Linux)
    func makeTask() -> Process
    #endif
}

/**
    Process wrapper for launching, monitoring Java processes.
 */
class JavaProcess {
    internal struct Config: JavaProcessConfig {
        let classPath: String
        let mainClass: String
        let arguments: [String]
        let workingDirectory: String
        let launchPath: String

        static func build(
            workingDirectory: String,
            classPath: String,
            mainClass: String = "com.achelos.egk.g2sim.application.Application",
            arguments: [String] = [],
            launchPath: String = "/usr/bin/java"
        ) -> Config {
            Config(classPath: classPath,
                   mainClass: mainClass,
                   arguments: arguments,
                   workingDirectory: workingDirectory,
                   launchPath: launchPath)
        }

        #if os(macOS) || os(Linux)
        func makeTask() -> Process {
            let task = Process()
            task.currentDirectoryPath = workingDirectory
            task.arguments = ["-cp", classPath, mainClass] + arguments
            task.launchPath = launchPath
            return task
        }
        #endif
    }

    private let config: JavaProcessConfig
    #if os(macOS) || os(Linux)
    private var process: Process?
    #endif
    private let runloop = KeepAliveRunLoop()

    let stdout: Pipe?
    let stderr: Pipe?
    let stdin: Pipe?

    init(config: JavaProcessConfig, stdout: Pipe? = nil, stderr: Pipe? = nil, stdin: Pipe? = nil) {
        self.config = config
        self.stdout = stdout
        self.stderr = stderr
        self.stdin = stdin
    }
}

protocol JavaProcessUpdateDelegate: AnyObject {
    func processDidLaunch(_ process: JavaProcess, pid: Int32)
    func processDidTerminate(_ process: JavaProcess, with status: Int32)
}

extension JavaProcessUpdateDelegate {
    /// Allow method to be optional
    func processDidLaunch(_: JavaProcess, pid _: Int32) {}

    /// Allow method to be optional
    func processDidTerminate(_: JavaProcess, with _: Int32) {}
}

extension JavaProcess {
    /// Runs the Java process
    public func run(in runloop: RunLoop = RunLoop.current,
                    mode: RunLoop.Mode = .default,
                    delegate: JavaProcessUpdateDelegate? = nil) {
        #if os(macOS) || os(Linux)
        guard process == nil else {
            ALog("WARN: double start. Process already started/initialized")
            return
        }
        #endif
        runloop.perform(inModes: [mode]) {
            let terminationStatusCode = self.launch(delegate)
            // Safe-callback on main-thread without blocking the current RunLoop
            DispatchQueue.global().async { [weak self, delegate] in
                DispatchQueue.main.sync {
                    if let sSelf = self {
                        delegate?.processDidTerminate(sSelf, with: terminationStatusCode)
                    }
                }
            }
        }
    }

    private func launch(_ delegate: JavaProcessUpdateDelegate? = nil) -> Int32 {
        #if os(macOS) || os(Linux)
        let task = config.makeTask()

        if let stderr = self.stderr {
            task.standardError = stderr
        }
        if let stdout = self.stdout {
            task.standardOutput = stdout
        }
        if let stdin = self.stdin {
            task.standardInput = stdin
        } else {
            /// Avoid that the host process Standard Input is piped through to this process
            task.standardInput = Pipe()
        }

        task.launch()
        DLog("JavaProcess launched PID: [\(task.processIdentifier)]")
        process = task
        DispatchQueue.global().async {
            DispatchQueue.main.sync {
                delegate?.processDidLaunch(self, pid: task.processIdentifier)
            }
        }
        task.waitUntilExit()
        return task.terminationStatus
        #else
        return 1
        #endif
    }

    var isRunning: Bool {
        #if os(macOS) || os(Linux)
        return process?.isRunning ?? false
        #else
        return false
        #endif
    }

    func terminate(waitUntilDone: Bool = false) {
        #if os(macOS) || os(Linux)
        process?.terminate()
        if waitUntilDone {
            process?.waitUntilExit()
        }
        #endif
    }
}
