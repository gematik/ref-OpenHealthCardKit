//
//  Copyright (c) 2020 gematik GmbH
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//     http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import CardReaderProviderApi
import CardSimulationTerminalTestCase
import DataKit
import Foundation
import GemCommonsKit
@testable import HealthCardAccess
import Nimble
import XCTest

final class OperationIntegrationTest: CardSimulationTerminalTestCase {
    func testSelectCommandIntegration() {
        expect {
            HealthCardCommand.Select.selectRoot()
                    .execute(on: CardSimulationTerminalTestCase.healthCard)
                    .run(on: Executor.trampoline)
                    .test().value?.responseStatus
        } == ResponseStatus.success

        expect {
            HealthCardCommand.Select.selectParent()
                    .execute(on: CardSimulationTerminalTestCase.healthCard)
                    .run(on: Executor.trampoline)
                    .test().value?.responseStatus
        } == ResponseStatus.fileNotFound
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
            let exec: Executable<HealthCardResponseType> = selectEsignCommand.execute(on: eGk)
            // end::setExecutionTarget[]

            // tag::evaluateResponseStatus[]
            let execEvaluated: Executable<HealthCardResponseType> = exec.map { healthCardResponse in
                guard healthCardResponse.responseStatus == ResponseStatus.success else {
                    throw HealthCard.Error.operational // throw a meaningful Error
                }
                return healthCardResponse
            }
            // end::evaluateResponseStatus[]

            // tag::createCommandSequence[]
            let readCertificate: Executable<HealthCardResponseType> = execEvaluated.flatMap { _ in
                let sfi = EgkFileSystem.EF.esignCChAutR2048.sfid!
                let read = try HealthCardCommand.Read.readFileCommand(with: sfi, ne: 0x076C - 1)
                return read.execute(on: eGk)
            }
            // end::createCommandSequence[]

            // tag::processExecutionResult[]
            readCertificate
                    .run(on: Executor.trampoline)
                    .on { event in
                        event.fold(
                                onComplete: { healthCardResponse in
                                    DLog("Got a certifcate")
                                    guard let data = healthCardResponse.data else {
                                        DLog("No certificate data")
                                        throw HealthCard.Error.operational
                                    }
                                    // proceed with certificate data here, show success message on screen etc.
                                },
                                onCancelled: {
                                    DLog("Cancelled")
                                },
                                onTimedOut: {
                                    DLog("Timeout")
                                },
                                onError: { error in
                                    DLog("Error: \(error.localizedDescription)")
                                })
                    }
            // end::processExecutionResult[]
            return 0
        }.toNot(throwError())
    }

    static let allTests = [
        ("testSelectCommandIntegration", testSelectCommandIntegration)
    ]
}
