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
import Foundation
@testable import HealthCardAccess
import Nimble
import XCTest

final class SelectCommandIntegrationTest: CardSimulationTerminalTestCase {
    func testSelectRoot() async throws {
        let selectRootCommand = HealthCardCommand.Select.selectRoot()
        let selectRootResponse = try await selectRootCommand.transmit(to: Self.healthCard)
        expect(selectRootResponse.responseStatus) == ResponseStatus.success
    }

    func testSelectFileByAidThenSelectParentFolder() async throws {
        let selectFileCommand = HealthCardCommand.Select.selectFile(with: EgkFileSystem.DF.GDD.aid)
        let selectFileResponse = try await selectFileCommand.transmit(to: Self.healthCard)
        expect(selectFileResponse.responseStatus) == ResponseStatus.success

        let selectRootCommand = HealthCardCommand.Select.selectRoot()
        let selectRootResponse = try await selectRootCommand.transmit(to: Self.healthCard)
        expect(selectRootResponse.responseStatus) == ResponseStatus.success
    }

    func testReadFileBySfiWithLowerThanSpecifiedLength() async throws {
        let cEgkAutCVCE256Count = 0x00DE

        let readFileCommand = try HealthCardCommand.Read.readFileCommand(
            with: EgkFileSystem.EF.cEgkAutCVCE256.sfid!, // swiftlint:disable:this force_unwrapping
            ne: cEgkAutCVCE256Count + 1,
            offset: 0
        )
        let readFileResponse = try await readFileCommand.transmit(to: Self.healthCard)
        expect(readFileResponse.responseStatus) == ResponseStatus.endOfFileWarning
    }
}
