//
//  Copyright (c) 2021 gematik GmbH
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
import HealthCardAccess
@testable import HealthCardControl
import Nimble
import XCTest

final class AuthenticateChallengeR2048Test: CardSimulationTerminalTestCase {
    func testSignChallenge() throws {
        let challenge = "1234567890".data(using: .utf8)!
        let authenticatedResult = try Self.healthCard
            .verify(pin: "123456", type: .mrpinHome)
            .flatMap { _ in
                Self.healthCard.authenticate(challenge: challenge)
            }
            .eraseToAnyPublisher()
            .test()

        expect(authenticatedResult.certificate.signatureAlgorithm) == .sha256RsaMgf1
        expect(authenticatedResult.certificate.certificate.count) == 1242
        expect(authenticatedResult.signature.count) == 256
    }
}
