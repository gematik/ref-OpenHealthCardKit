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

@frozen
public enum ChangeReferenceDataResponse: Equatable {
    /// Reset successful
    case success
    /// Reset failed, retry count is the number of retries left for the given `EgkFileSystem.Pin` type
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
    /// Any (unexpected) error not specified in gemSpec_COS 14.6.1.3
    case unknownFailure
}

/// Convenience password reference selector
public enum ChangeReferenceDataAffectedPassword {
    /// MR.PIN HOME in non-df-specific context
    case mrPinHomeNoDfSpecific
}

extension HealthCardType {
    ///  Assign a new secret (value) to a password.
    ///
    /// - Parameters:
    ///   - old: The old secret of the password object
    ///   - new: The new secret of the password object
    ///   - type: Password reference
    ///   - dfSpecific: is Password reference dfSpecific
    /// - Returns: Publisher that tries to set the password's new value
    @available(*, deprecated, message: "Use structured concurrency version instead")
    public func changeReferenceDataSetNewPin(
        old: Format2Pin,
        new: Format2Pin,
        type: EgkFileSystem.Pin = EgkFileSystem.Pin.mrpinHome,
        dfSpecific: Bool = false
    ) -> AnyPublisher<ChangeReferenceDataResponse, Error> {
        CommandLogger.commands.append(Command(message: "Change Reference Data: Set New PIN", type: .description))
        let command: HealthCardCommand
        let parameters = (password: type.rawValue, dfSpecific: dfSpecific, old: old, new: new)
        do {
            command = try HealthCardCommand.ChangeReferenceData.change(password: parameters)
        } catch {
            return Combine.Fail(error: error).eraseToAnyPublisher()
        }

        return command
            .publisher(for: self)
            .map { response -> ChangeReferenceDataResponse in
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

    ///  Assign a new secret (value) to a password.
    ///
    /// - Parameters:
    ///   - old: The old secret of the password object
    ///   - new: The new secret of the password object
    ///   - type: Password reference
    ///   - dfSpecific: is Password reference dfSpecific
    /// - Returns: `ChangeReferenceDataResponse` after trying to set the password's new value
    public func changeReferenceDataSetNewPin(
        old: Format2Pin,
        new: Format2Pin,
        type: EgkFileSystem.Pin = EgkFileSystem.Pin.mrpinHome,
        dfSpecific: Bool = false
    ) async throws -> ChangeReferenceDataResponse {
        CommandLogger.commands.append(Command(message: "Change Reference Data: Set New PIN", type: .description))
        let parameters = (password: type.rawValue, dfSpecific: dfSpecific, old: old, new: new)
        let changeReferenceDataCommand = try HealthCardCommand.ChangeReferenceData.change(password: parameters)
        let changeReferenceDataResponse = try await changeReferenceDataCommand.transmitAsync(to: self)

        let responseStatus = changeReferenceDataResponse.responseStatus
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

    ///  Assign a new secret (value) to a password.
    ///
    /// - Parameters:
    ///   - old: The old secret of the password object
    ///   - new: The new secret of the password object
    ///   - affectedPassword: convenient `ChangeReferenceDataAffectedPassword` selector
    /// - Returns: Publisher that tries to set the password's new value
    @available(*, deprecated, message: "Use structured concurrency version instead")
    public func changeReferenceDataSetNewPin(
        old: String,
        new: String,
        affectedPassword: ChangeReferenceDataAffectedPassword
    ) -> AnyPublisher<ChangeReferenceDataResponse, Error> {
        let parsedOld: Format2Pin
        let parsedNew: Format2Pin
        do {
            parsedOld = try Format2Pin(pincode: old)
            parsedNew = try Format2Pin(pincode: new)
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
        return changeReferenceDataSetNewPin(old: parsedOld, new: parsedNew, type: type, dfSpecific: dfSpecific)
    }

    ///  Assign a new secret (value) to a password.
    ///
    /// - Parameters:
    ///   - old: The old secret of the password object
    ///   - new: The new secret of the password object
    ///   - affectedPassword: convenient `ChangeReferenceDataAffectedPassword` selector
    /// - Returns: `ChangeReferenceDataResponse` after trying to set the password's new value
    public func changeReferenceDataSetNewPin(
        old: String,
        new: String,
        affectedPassword: ChangeReferenceDataAffectedPassword
    ) async throws -> ChangeReferenceDataResponse {
        let parsedOld = try Format2Pin(pincode: old)
        let parsedNew = try Format2Pin(pincode: new)
        let type: EgkFileSystem.Pin
        let dfSpecific: Bool
        switch affectedPassword {
        case .mrPinHomeNoDfSpecific:
            type = .mrpinHome
            dfSpecific = false
        }
        return try await changeReferenceDataSetNewPin(
            old: parsedOld,
            new: parsedNew,
            type: type,
            dfSpecific: dfSpecific
        )
    }
}
