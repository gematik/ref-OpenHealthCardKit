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

import AEXML
import Foundation
import GemCommonsKit
import OSLog

extension SimulationManager {
    struct DependencyInfo {
        let config: AEXMLDocument
        private let output: URL

        init(xml: AEXMLDocument, output directory: URL) {
            config = xml
            output = directory
        }

        func simulatorName() throws -> String {
            guard let name = config["project"]["name"].value,
                  let version = config["project"]["version"].value else {
                throw SimulationLoaderError.malformedConfiguration
            }
            return "\(name)-\(version)"
        }

        private var simulatorPath: URL {
            let version: String
            if let projectVersion = config["project"]["version"].value {
                version = projectVersion
            } else {
                version = "0.0.0"
            }
            return output.appendingPathComponent(version, isDirectory: true)
        }

        var simulatorClassPath: URL? {
            guard let simName = try? simulatorName() else {
                return nil
            }
            return simulatorPath.appendingPathComponent(simName, isDirectory: true)
                .appendingPathComponent("dependency", isDirectory: true)
        }

        var pom: URL {
            simulatorPath.appendingPathComponent("pom.xml")
        }

        var script: URL {
            simulatorPath.appendingPathComponent("runMaven.sh")
        }

        var simulatorExists: Bool {
            FileManager.default.fileExists(atPath: simulatorPath.absoluteURL.path)
        }
    }

    static func loadCardSimulatorDependencies(
        version: String,
        outputDirectory: URL,
        pom pomXml: Data,
        script runMaven: String = runMavenSh
    ) -> Result<DependencyInfo, Swift.Error> {
        let manipulator = XMLPathManipulatorHolder(path: "project.version") { _, element in
            element.value = version
            return element
        }

        return Result {
            #if os(iOS)
            throw SimulationLoaderError.unsupportedPlatform(name: "iOS")
            #else
            return try AEXMLDocument(xml: pomXml)
            #endif
        }
        .flatMap { (pom: AEXMLDocument) in
            Result {
                try pom.manipulateXMLDocument(with: [manipulator])
            }
        }
        .map { xmlDoc in
            DependencyInfo(xml: xmlDoc, output: outputDirectory)
        }
        .flatMap { dependencyInfo in
            guard !dependencyInfo.simulatorExists else {
                // Skip (consecutive) downloading of same/existing simulator version
                Logger.cardSimulationLoader
                    .debug(
                        // swiftlint:disable:next line_length
                        "Skip (consecutive) download of same/existing simulator version.\n* classPath: [\(String(describing: dependencyInfo.simulatorClassPath?.absoluteString))]"
                    )
                return Result.success(dependencyInfo)
            }

            return Result {
                try dependencyInfo.config.createXML()
            }.flatMap { xmlData -> Result<DependencyInfo, Swift.Error> in
                // Save POM
                xmlData.save(to: dependencyInfo.pom)
                    .flatMap { _ -> Result<DependencyInfo, Swift.Error> in
                        Result {
                            guard let scriptData = runMaven.data(using: .utf8) else {
                                throw SimulationLoaderError.resourceNotFound("Maven.swift")
                            }
                            return scriptData
                        }.flatMap { (scriptData: Data) in
                            // Save runMaven.sh
                            scriptData.save(to: dependencyInfo.script).flatMap { _ in
                                Result {
                                    try SimulationManager.downloadMavenDependencies(dependencyInfo)
                                    return dependencyInfo
                                }
                            }
                        }
                    }
            }
        }
    }

    @discardableResult
    private static func downloadMavenDependencies(_ dependency: DependencyInfo, launchPath: String = "/bin/bash")
        throws -> Int32 {
        #if os(macOS) || os(Linux)
        let shellProcess = Process()
        shellProcess.arguments = [dependency.script.absoluteURL.path, dependency.pom.absoluteURL.path]
        shellProcess.launchPath = launchPath
        shellProcess.launch()
        shellProcess.waitUntilExit()
        guard shellProcess.terminationStatus == 0 else {
            throw SimulationLoaderError.shellProcessTerminatedUnexpected(status: shellProcess.terminationStatus)
        }
        return 0
        #else
        throw SimulationLoaderError.unsupportedPlatform(name: "iOS|tvOS|watchOS")
        #endif
    }
}
