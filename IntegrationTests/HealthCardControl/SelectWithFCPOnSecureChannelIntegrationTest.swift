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
import CardSimulationCardReaderProvider
import Combine
import Foundation
import HealthCardAccess
@testable import HealthCardControl
import Nimble
import XCTest

final class SelectWithFCPOnSecureChannelIntegrationTest: CardSimulationTerminalTestCase {
    override class var configFileInput: String { "CardSim/configuration_TLK_COS_image_kontaktlos128.xml" }

    func testSelectEsignCChAutE256WithFCP_publisher() throws {
        let can = try CAN.from(Data("123123".utf8))

        let response = try Self.card.openSecureSessionPublisher(can: can, writeTimeout: 0, readTimeout: 0)
            .flatMap { secureCard in
                secureCard.selectDedicatedPublisher(
                    file: DedicatedFile(aid: EgkFileSystem.DF.ESIGN.aid, fid: EgkFileSystem.EF.esignCChAutE256.fid),
                    fcp: true
                )
            }
            .eraseToAnyPublisher()
            .test()

        expect(response.0) == .success
        expect(response.1?.size) == 1900
    }

    func testSelectEsignCChAutE256WithFCP() async throws {
        let can = try CAN.from(Data("123123".utf8))

        let secureCard = try await Self.card.openSecureSessionAsync(can: can, writeTimeout: 0, readTimeout: 0)
        let response = try await secureCard.selectDedicatedAsync(
            file: DedicatedFile(aid: EgkFileSystem.DF.ESIGN.aid, fid: EgkFileSystem.EF.esignCChAutE256.fid),
            fcp: true
        )

        expect(response.0) == .success
        expect(response.1?.size) == 1900
    }
}
