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

/// HealthCard status
public enum HealthCardStatus {
    /// when card type has not been determined (yet) [e.g. probing]
    case unknown
    /// when card type has been identified by this library
    case valid(cardType: HealthCardPropertyType?)
    /// when card type could not be determined
    case invalid

    /// Whether the presented Card is valid in the gematik domain
    public var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }

    /// The generation version of the card/COS
    public var generation: CardGeneration? {
        type?.generation
    }

    /// The kind of gematik Healthcard (eGK, HBA, SMC-B)
    public var type: HealthCardPropertyType? {
        if case let .valid(cardType) = self {
            return cardType
        }
        return nil
    }
}

extension HealthCardStatus: Equatable {
    public static func ==(lhs: HealthCardStatus, rhs: HealthCardStatus) -> Bool {
        // swiftlint:disable:previous operator_whitespace
        switch (lhs, rhs) {
        case (.unknown, .unknown): return true
        case let (.valid(lhsCardType), .valid(rhsCardType)): return lhsCardType == rhsCardType
        case (.invalid, .invalid): return true
        default: return false
        }
    }
}
