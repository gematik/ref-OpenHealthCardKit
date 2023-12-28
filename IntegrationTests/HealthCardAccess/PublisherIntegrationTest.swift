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
import Combine
import DataKit
import Foundation
import GemCommonsKit
@testable import HealthCardAccess
import Nimble
import XCTest

final class PublisherIntegrationTest: CardSimulationTerminalTestCase {
    func testSelectCommandPublisherIntegration() {
        expect {
            try HealthCardCommand.Select.selectRoot()
                .publisher(for: CardSimulationTerminalTestCase.healthCard.currentCardChannel)
                .test()
                .responseStatus
        } == ResponseStatus.success
    }

    func testSelectThenReadCommandPublisherIntegration() {
        let eSign = EgkFileSystem.DF.ESIGN
        let selectEsignCommand = HealthCardCommand.Select.selectFile(with: eSign.aid)
        let sfi = EgkFileSystem.EF.esignCChAutR2048.sfid! // swiftlint:disable:this force_unwrapping
        expect {
            try selectEsignCommand.publisher(for: CardSimulationTerminalTestCase.healthCard)
                .flatMap { _ -> AnyPublisher<HealthCardResponseType, Error> in
                    do {
                        return try HealthCardCommand.Read.readFileCommand(with: sfi, ne: 0x076C)
                            .publisher(for: CardSimulationTerminalTestCase.healthCard)
                    } catch {
                        return Fail(error: error)
                            .eraseToAnyPublisher()
                    }
                }
                .eraseToAnyPublisher()
                .test()
                .responseStatus
        } == ResponseStatus.endOfFileWarning
    }

    // swiftlint:disable force_unwrapping
    func codeForUserManual() {
        // tag::createCommand[]
        let eSign = EgkFileSystem.DF.ESIGN
        let selectEsignCommand = HealthCardCommand.Select.selectFile(with: eSign.aid)
        // end::createCommand[]

        expect {
            // tag::setExecutionTarget[]
            // initialize your CardReaderType instance
            let cardReader: CardReaderType = CardSimulationTerminalTestCase.reader
            let card = try cardReader.connect([:])!
            let healthCardStatus = HealthCardStatus.valid(cardType: .egk(generation: .g2))
            let eGk = try HealthCard(card: card, status: healthCardStatus)
            let publisher: AnyPublisher<HealthCardResponseType, Error> = selectEsignCommand.publisher(for: eGk)
            // end::setExecutionTarget[]

            // tag::evaluateResponseStatus[]
            let checkResponse = publisher.tryMap { healthCardResponse -> HealthCardResponseType in
                guard healthCardResponse.responseStatus == ResponseStatus.success else {
                    throw HealthCard.Error.operational // throw a meaningful Error
                }
                return healthCardResponse
            }
            // end::evaluateResponseStatus[]

            // tag::createCommandSequence[]
            let readCertificate = checkResponse
                .tryMap { _ -> HealthCardCommandType in
                    let sfi = EgkFileSystem.EF.esignCChAutR2048.sfid!
                    return try HealthCardCommand.Read.readFileCommand(with: sfi, ne: 0x076C - 1)
                }
                .flatMap { command in
                    command.publisher(for: eGk)
                }
                .eraseToAnyPublisher()
            // end::createCommandSequence[]

            // tag::processExecutionResult[]
            readCertificate
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            DLog("Completed")
                        case let .failure(error):
                            DLog("Error: \(error)")
                        }
                    },
                    receiveValue: { healthCardResponse in
                        DLog("Got a certifcate")
                        let certificate = healthCardResponse.data!
                        // proceed with certificate data here
                        // use swiftUI to a show success message on screen etc.
                    }
                )
            // end::processExecutionResult[]
        }.toNot(throwError())
    }

    // swiftlint:enable force_unwrapping

    static let allTests = [
        ("testSelectCommandPublisherIntegration", testSelectCommandPublisherIntegration),
        ("testSelectThenReadCommandPublisherIntegration", testSelectThenReadCommandPublisherIntegration),
    ]
}
