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

@frozen
public enum ResetRetryCounterResponse: Equatable {
    /// Reset successful
    case success
    /// Reset failed, retry count is the number of retries left for the given `EgkFileSystem.Pin` type's PUK
    case wrongSecretWarning(retryCount: Int)
    /// Access rule evaluation failure
    case securityStatusNotSatisfied
    /// Write action unsuccessful
    case memoryFailure
    /// Counter for PUK is already blocked (cannot be reset)
    case commandBlocked
    /// New password is either too long or too short
    case wrongPasswordLength
    /// Referenced password could not be found
    case passwordNotFound
    /// Any (unexpected) error not specified in gemSpec_COS 14.6.5.5
    case unknownFailure
}

/// Convenience password reference selector
public enum ResetRetryCounterAffectedPassword {
    /// MR.PIN HOME in non-df-specific context
    case mrPinHomeNoDfSpecific
}

// Usage: See IntegrationTests.HealthCardControl.HealthCardTypeExtResetRetryCounterIntegrationTest
extension HealthCardType {
    /// Reset the retry counter of a password object to its start value.
    ///
    /// - Parameters:
    ///   - puk: Secret which authorizes the action
    ///   - type: Password reference
    ///   - dfSpecific: is Password reference dfSpecific
    /// - Returns: Publisher that tries to reset the password's retry counter
    /// - Throws: HealthCardCommandBuilderError
    public func resetRetryCounter(
        puk: Format2Pin,
        type: EgkFileSystem.Pin = EgkFileSystem.Pin.mrpinHome,
        dfSpecific: Bool = false
    ) -> AnyPublisher<ResetRetryCounterResponse, Error> {
        CommandLogger.commands.append(Command(message: "Reset Retry Counter", type: .description))
        let command: HealthCardCommand
        do {
            command = try HealthCardCommand.ResetRetryCounter.resetRetryCounterWithPukWithoutNewSecret(
                password: type.rawValue,
                dfSpecific: dfSpecific,
                puk: puk
            )
        } catch {
            return Combine.Fail(error: error).eraseToAnyPublisher()
        }

        return command
            .publisher(for: self)
            .map { response -> ResetRetryCounterResponse in
                let responseStatus = response.responseStatus
                if ResponseStatus.wrongSecretWarnings.contains(responseStatus) {
                    return .wrongSecretWarning(retryCount: responseStatus.retryCount)
                }
                switch responseStatus {
                case .success: return .success
                case .memoryFailure: return .memoryFailure
                case .securityStatusNotSatisfied: return .securityStatusNotSatisfied
                case .commandBlocked: return .commandBlocked
                case .wrongPasswordLength: return .wrongPasswordLength
                case .passwordNotFound: return .passwordNotFound
                default: return .unknownFailure
                }
            }
            .eraseToAnyPublisher()
    }

    /// Reset the retry counter of a password object to its start value.
    ///
    /// - Parameters:
    ///   - puk: Secret which authorizes the action
    ///   - affectedPassWord: convenience `ResetRetryCounterAffectedPassword` selector
    /// - Returns: Publisher that tries to reset the password's retry counter
    /// - Throws: HealthCardAccessError
    public func resetRetryCounter(
        puk: String,
        affectedPassWord: ResetRetryCounterAffectedPassword
    ) -> AnyPublisher<ResetRetryCounterResponse, Error> {
        let parsedPuk: Format2Pin
        do {
            parsedPuk = try Format2Pin(pincode: puk)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        let type: EgkFileSystem.Pin
        let dfSpecific: Bool
        switch affectedPassWord {
        case .mrPinHomeNoDfSpecific:
            type = .mrpinHome
            dfSpecific = false
        }
        return resetRetryCounter(puk: parsedPuk, type: type, dfSpecific: dfSpecific)
    }

    /// Reset the retry counter of a password object to its start value while assigning a new secret.
    ///
    /// - Parameters:
    ///   - puk: Secret which authorizes the action
    ///   - newPin: The new secret of the password object
    ///   - type: Password reference
    ///   - dfSpecific: is Password reference dfSpecific
    /// - Returns: Publisher that tries to reset the password's retry counter while setting a new secret
    public func resetRetryCounterAndSetNewPin(
        puk: Format2Pin,
        newPin: Format2Pin,
        type: EgkFileSystem.Pin = EgkFileSystem.Pin.mrpinHome,
        dfSpecific: Bool = false
    ) -> AnyPublisher<ResetRetryCounterResponse, Error> {
        CommandLogger.commands.append(Command(message: "Reset Retry Counter And Set New PIN", type: .description))
        let command: HealthCardCommand
        do {
            command = try HealthCardCommand.ResetRetryCounter.resetRetryCounterWithPukWithNewSecret(
                password: type.rawValue,
                dfSpecific: dfSpecific,
                puk: puk,
                newPin: newPin
            )
        } catch {
            return Combine.Fail(error: error).eraseToAnyPublisher()
        }

        return command
            .publisher(for: self)
            .map { response -> ResetRetryCounterResponse in
                let responseStatus = response.responseStatus
                if ResponseStatus.wrongSecretWarnings.contains(responseStatus) {
                    return .wrongSecretWarning(retryCount: responseStatus.retryCount)
                }
                switch responseStatus {
                case .success: return .success
                case .memoryFailure: return .memoryFailure
                case .securityStatusNotSatisfied: return .securityStatusNotSatisfied
                case .commandBlocked: return .commandBlocked
                case .wrongPasswordLength: return .wrongPasswordLength
                case .passwordNotFound: return .passwordNotFound
                default: return .unknownFailure
                }
            }
            .eraseToAnyPublisher()
    }

    /// Reset the retry counter of a password object to its start value while assigning a new secret.
    ///
    /// - Parameters:
    ///   - puk: Secret which authorizes the action
    ///   - newPin: The new secret of the password object
    ///   - affectedPassWord: convenience `ResetRetryCounterAffectedPassword` selector
    /// - Returns: Publisher that tries to reset the password's retry counter
    public func resetRetryCounterAndSetNewPin(
        puk: String,
        newPin: String,
        affectedPassWord: ResetRetryCounterAffectedPassword
    ) -> AnyPublisher<ResetRetryCounterResponse, Error> {
        let parsedPuk: Format2Pin
        let parsedPin: Format2Pin
        do {
            parsedPuk = try Format2Pin(pincode: puk)
            parsedPin = try Format2Pin(pincode: newPin)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        let type: EgkFileSystem.Pin
        let dfSpecific: Bool
        switch affectedPassWord {
        case .mrPinHomeNoDfSpecific:
            type = .mrpinHome
            dfSpecific = false
        }
        return resetRetryCounterAndSetNewPin(puk: parsedPuk, newPin: parsedPin, type: type, dfSpecific: dfSpecific)
    }
}
