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

import AEXML
@testable import CardSimulationLoader
import Foundation
import Nimble
import OSLog
import XCTest

final class SimulationManagerExtInternalTest: XCTestCase {
    func testSimulationManager_DependencyInfo() {
        do {
            let pomXmlData = try Data(contentsOf: Bundle(for: SimulationManagerExtInternalTest.self)
                .testResourceFilePath(in: "Resources", for: "pom.xml").asURL)
            let pomXml = try AEXMLDocument(xml: pomXmlData)
            let outputPath = NSTemporaryDirectory()
                .asURL.appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)
            let dependencyInfo = SimulationManager.DependencyInfo(xml: pomXml, output: outputPath)

            let expectedProject = "CardSimulation-test"
            let expectedVersion = "1.0.0-test"
            let expectedName = "\(expectedProject)-\(expectedVersion)"
            let simulatorName = try dependencyInfo.simulatorName()
            expect(expectedName).to(equal(simulatorName))
            let expectedSimulatorPath = outputPath.appendingPathComponent(expectedVersion, isDirectory: true)
            let expectedPomPath = expectedSimulatorPath.appendingPathComponent("pom.xml")
            expect(expectedPomPath).to(equal(dependencyInfo.pom))
            let expectedScriptPath = expectedSimulatorPath.appendingPathComponent("runMaven.sh")
            expect(expectedScriptPath).to(equal(dependencyInfo.script))

            let expectedClassPath = expectedSimulatorPath.appendingPathComponent(expectedName, isDirectory: true)
                .appendingPathComponent("dependency", isDirectory: true)
            expect(expectedClassPath).to(equal(dependencyInfo.simulatorClassPath))

            expect(dependencyInfo.simulatorExists).to(beFalse())
            let simPath = expectedScriptPath.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: simPath, withIntermediateDirectories: true)
            expect(dependencyInfo.simulatorExists).to(beTrue())
            try FileManager.default.removeItem(at: simPath)
        } catch {
            Logger.cardSimulationLoaderTests.fault("Test-case failed with exception: [\(error)]")
            Nimble.fail("Failed with error \(error)")
        }
    }

    func testSimulationManager_loadCardSimulatorDependencies() {
        do {
            let pomXmlData = try Data(contentsOf: Bundle(for: SimulationManagerExtInternalTest.self)
                .testResourceFilePath(in: "Resources", for: "pom.xml").asURL)
            let script = """
            #!/bin/bash
            DIR="$(dirname $1)"
            cd "${DIR}" && echo -n $1 > output.txt
            exit 0
            """
            let outputPath = NSTemporaryDirectory().asURL
                .appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)
            let expectedVersion = "0.0.T-tests"
            let dependencyInfo = try SimulationManager.loadCardSimulatorDependencies(
                version: expectedVersion,
                outputDirectory: outputPath,
                pom: pomXmlData,
                script: script
            )
            .get()

            let scriptOutputFileData = try Data(contentsOf: dependencyInfo.pom.deletingLastPathComponent()
                .appendingPathComponent("output.txt"))
            guard let output = String(data: scriptOutputFileData, encoding: .utf8) else {
                Nimble.fail("Failed converting scriptOutputFileData to String.")
                return
            }
            expect(output).to(equal(dependencyInfo.pom.path))
            let pomFileData = try Data(contentsOf: dependencyInfo.pom)
            let pomXml = try AEXMLDocument(xml: pomFileData)
            expect(expectedVersion).to(equal(pomXml["project"]["version"].value))
            // cleanup
            try FileManager.default.removeItem(at: outputPath)
        } catch {
            Logger.cardSimulationLoaderTests.fault("Test-case failed with exception: [\(error)]")
            Nimble.fail("Failed with error \(error)")
        }
    }

    static var allTests = [
        ("testSimulationManager_DependencyInfo", testSimulationManager_DependencyInfo),
        ("testSimulationManager_loadCardSimulatorDependencies", testSimulationManager_loadCardSimulatorDependencies),
    ]
}
