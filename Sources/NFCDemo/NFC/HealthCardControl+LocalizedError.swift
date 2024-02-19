// swiftlint:disable:this file_name
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
import HealthCardControl

extension KeyAgreement.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .illegalArgument:
            return "illegalArgument"
        case .unexpectedFormedAnswerFromCard:
            return "unexpectedFormedAnswerFromCard"
        case .resultOfEcArithmeticWasInfinite:
            return "resultOfEcArithmeticWasInfinite"
        case .macPcdVerificationFailedOnCard:
            return "Wrong CAN (macPcdVerificationFailedOnCard)!"
        case .macPiccVerificationFailedLocally:
            return "macPiccVerificationFailedLocally"
        case .noValidHealthCardStatus:
            return "noValidHealthCardStatus"
        case .efCardAccessNotAvailable:
            return "efCardAccessNotAvailable"
        case let .unsupportedKeyAgreementAlgorithm(identifier):
            return "unsupportedKeyAgreementAlgorithm with identifier: \(identifier)"
        @unknown default:
            return "unknown KeyAgreement error"
        }
    }
}
