//
//  Copyright (c) 2022 gematik GmbH
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

import Combine
import Foundation
import HealthCardAccess
import Helper

/// Response to a Verify Pin command on a HealthCard
/// - SeeAlso: `HealthCardType.verify(pin:type:)`
/// - success: when the pin verified as correct
/// - failed: when the pin was incorrect
public enum VerifyPinResponse {
    /// Pin verification succeeded
    case success
    /// Pin verification failed, retry count is the number of retries left for the given `EgkFileSystem.Pin` type
    case failed(retryCount: Int)
}

extension VerifyPinResponse: Equatable {}

extension HealthCardType {
    /// Verify Password for a Pin type
    ///
    /// - Parameters:
    ///     - pin: `Format2Pin` holds the Pin information for the `type`. E.g. mrPinHome.
    ///     - type: verification type. Any of `EgkFileSystem.Pin`.
    ///
    /// - Returns: Publisher that tries to verify the given `pin` information against `type`
    ///
    /// - Note: Only supports eGK Card types
    public func verify(pin: Format2Pin, type: EgkFileSystem.Pin) -> AnyPublisher<VerifyPinResponse, Error> {
        CommandLogger.commands.append(Command(message: "Verify PIN", type: .description))
        let verifyPasswordParameter = (type.rawValue, false, pin)
        return HealthCardCommand.Verify.verify(password: verifyPasswordParameter)
            .publisher(for: self)
            .map { response in
                if response.responseStatus == .success {
                    return .success
                } else {
                    return .failed(retryCount: response.responseStatus.retryCount)
                }
            }
            .eraseToAnyPublisher()
    }
}

extension ResponseStatus {
    var retryCount: Int {
        switch self {
        case .wrongSecretWarningCount06: return 6
        case .wrongSecretWarningCount05: return 5
        case .wrongSecretWarningCount04: return 4
        case .wrongSecretWarningCount03: return 3
        case .wrongSecretWarningCount02: return 2
        case .wrongSecretWarningCount01: return 1
        default: return 0
        }
    }
}
