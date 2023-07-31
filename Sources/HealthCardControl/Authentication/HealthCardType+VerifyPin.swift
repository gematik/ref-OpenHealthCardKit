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

import Combine
import Foundation
import HealthCardAccess
import Helper

/// Response to a Verify Pin command on a HealthCard
/// - SeeAlso: `HealthCardType.verify(pin:type:)`
/// - success: when the pin verified as correct
/// - failed: when the pin was incorrect
public enum VerifyPinResponse: Equatable {
    /// Pin verification succeeded
    case success
    /// Pin verification failed, retry count is the number of retries left for the given `EgkFileSystem.Pin` type
    case wrongSecretWarning(retryCount: Int)
    /// Access rule evaluation failure
    case securityStatusNotSatisfied
    /// Write action unsuccessful
    case memoryFailure
    /// Exhausted retry counter
    case passwordBlocked
    /// Password is transport protected
    case passwordNotUsable
    /// Referenced password could not be found
    case passwordNotFound
    /// Any (unexpected) error not specified in gemSpec_COS 14.6.6.2
    case unknownFailure
}

/// Convenience password reference selector
public enum VerifyPinAffectedPassword {
    /// MR.PIN HOME in non-df-specific context
    case mrPinHomeNoDfSpecific
}

extension HealthCardType {
    /// Verify Password for a Pin type
    ///
    /// - Parameters:
    ///     - pin: `Format2Pin` holds the Pin information for the `type`. E.g. mrPinHome.
    ///     - type: verification type. Any of `EgkFileSystem.Pin`.
    ///     - dfSpecific: is Password reference dfSpecific
    ///
    /// - Returns: Publisher that tries to verify the given PIN-value information against `type`
    ///
    /// - Note: Only supports eGK Card types
    public func verify(
        pin: Format2Pin,
        type: EgkFileSystem.Pin,
        dfSpecific: Bool = false
    ) -> AnyPublisher<VerifyPinResponse, Error> {
        CommandLogger.commands.append(Command(message: "Verify PIN", type: .description))
        let verifyPasswordParameter = (type.rawValue, dfSpecific, pin)
        return HealthCardCommand.Verify.verify(password: verifyPasswordParameter)
            .publisher(for: self)
            .map { response -> VerifyPinResponse in
                let responseStatus = response.responseStatus
                if ResponseStatus.wrongSecretWarnings.contains(responseStatus) {
                    return .wrongSecretWarning(retryCount: responseStatus.retryCount)
                }
                switch responseStatus {
                case .success: return .success
                case .memoryFailure: return .memoryFailure
                case .securityStatusNotSatisfied: return .securityStatusNotSatisfied
                case .passwordBlocked: return .passwordBlocked
                case .passwordNotUsable: return .passwordNotUsable
                case .passwordNotFound: return .passwordNotFound
                default: return .unknownFailure
                }
            }
            .eraseToAnyPublisher()
    }

    /// Verify Password for a Pin type
    ///
    /// - Parameters:
    ///   - pin: holds the Pin information for the password
    ///   - affectedPassword: convenience `VerifyPinAffectedPassword` selector
    /// - Returns: Publisher that tries to verify the given PIN-value information against the affected password
    public func verify(
        pin: String,
        affectedPassword: VerifyPinAffectedPassword
    ) -> AnyPublisher<VerifyPinResponse, Error> {
        let parsedPIN: Format2Pin
        do {
            parsedPIN = try Format2Pin(pincode: pin)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        let type: EgkFileSystem.Pin
        let dfSpecific: Bool
        switch affectedPassword {
        case .mrPinHomeNoDfSpecific:
            type = .mrpinHome
            dfSpecific = false
        }
        return verify(pin: parsedPIN, type: type, dfSpecific: dfSpecific)
    }
}
