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
import Foundation
import GemCommonsKit
import HealthCardAccess

/// Extensions on CardType to negotiate a PACE session key for further secure
extension CardType {

    /// Open a secure session with a Card for further scheduling/attaching Executable commands
    ///
    /// - Note: the healthCard provided by the Executable operation chain should be used for the commands
    ///         to be executed on the secure channel. After the chain has completed the session should be
    ///         invalidated/closed.
    ///
    /// - Parameters:
    ///     - can: The Channel access number for the session
    ///     - writeTimeout: time in seconds. Default: 30
    ///     - readTimeout: time in seconds. Default 30
    /// - Returns: Executable<SecureHealthCardType> that negotiates a secure session when scheduled to run.
    public func openSecureSession(can: CAN, writeTimeout: TimeInterval = 30, readTimeout: TimeInterval = 30)
                    -> Executable<SecureHealthCardType> {
        return Executable<SecureHealthCardType>
                .evaluate { [self] () -> CardChannelType in
                    return try self.openBasicChannel()
                }
                .flatMap { channel in
                    /// Read EF.Version2 and determine HealthCardPropertyType
                    channel.readCardType(writeTimeout: writeTimeout, readTimeout: readTimeout)
                            .flatMap { type in
                                let healthCard = try HealthCard(card: self, status: .valid(cardType: type))
                                //swiftlint:disable:next todo
                                // TODO Determine the key agreement protocol by reading the info from EF.Access
                                // As of now for all current Health Card generations, it is .idPaceEcdhGmAesCbcCmac128
                                let keyAgreementAlgorithm = KeyAgreement.Algorithm.idPaceEcdhGmAesCbcCmac128
                                return try keyAgreementAlgorithm.negotiateSessionKey(
                                                channel: channel,
                                                can: can,
                                                writeTimeout: writeTimeout,
                                                readTimeout: readTimeout
                                        )
                                        .map { sessionKey in
                                            return SecureHealthCard(session: sessionKey, card: healthCard)
                                        }
                            }
                }
    }
}
