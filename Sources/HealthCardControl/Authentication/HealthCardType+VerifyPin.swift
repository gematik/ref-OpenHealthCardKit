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
public enum VerifyPinResponse: Equatable {
    /// Pin verification succeeded
    case success
    /// Pin verification failed, retry count is the number of retries left for the given `EgkFileSystem.Pin` type
    case failed(retryCount: Int) // TODO: not complete // swiftlint:disable:this todo
}

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
                    // TODO: not complete // swiftlint:disable:this todo
                    // is also wrong for failures that were not wrongSecret
                    return .failed(retryCount: response.responseStatus.retryCount)
                }
            }
            .eraseToAnyPublisher()
    }
}
