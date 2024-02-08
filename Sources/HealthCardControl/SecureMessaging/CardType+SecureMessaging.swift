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

import CardReaderProviderApi
import Combine
import Foundation
import GemCommonsKit
import HealthCardAccess
import Helper

/// Extensions on CardType to negotiate a PACE session key for further secure
extension CardType {
    /// Open a secure session with a Card for further scheduling/attaching Publisher commands
    ///
    /// - Note: The healthCard provided by the Combine operation chain should be used for the commands
    ///   to be executed on the secure channel.
    ///   After the chain has completed the session should be invalidated/closed.
    ///
    /// - Parameters:
    ///     - can: The Channel access number for the session
    ///     - writeTimeout: time in seconds. Default: 30
    ///     - readTimeout: time in seconds. Default 30
    /// - Returns: Publisher that negotiates a secure session when scheduled to run.
    @available(*, deprecated, message: "Use structured concurrency version instead")
    public func openSecureSession(can: CAN, writeTimeout: TimeInterval = 30, readTimeout: TimeInterval = 30)
        -> AnyPublisher<HealthCardType, Error> {
        CommandLogger.commands.append(Command(message: "Open secure Session", type: .description))
        return Deferred { () -> AnyPublisher<CardChannelType, Error> in
            do {
                return try Just(self.openBasicChannel()).setFailureType(to: Error.self).eraseToAnyPublisher()
            } catch {
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
        .flatMap { channel in
            // Read/Determine ApplicationIdentifier of the card's initial application
            channel.determineCardAid()
                .flatMap { cardAid in
                    // Read EF.CardAccess and determine algorithm for key agreement (e.g. PACE)
                    channel.readKeyAgreementAlgorithm(cardAid: cardAid)
                        .flatMap { keyAgreementAlgorithm in
                            // Read EF.Version2 and determine HealthCardPropertyType
                            channel.readCardType(cardAid: cardAid,
                                                 writeTimeout: writeTimeout,
                                                 readTimeout: readTimeout)
                                .tryMap { type in
                                    try HealthCard(card: self, status: .valid(cardType: type))
                                }
                                .flatMap { healthCard in
                                    keyAgreementAlgorithm.negotiateSessionKey(
                                        card: healthCard,
                                        can: can,
                                        writeTimeout: writeTimeout,
                                        readTimeout: readTimeout
                                    )
                                    .map { sessionKey in
                                        SecureHealthCard(session: sessionKey, card: healthCard)
                                    }
                                }
                        }
                }
        }
        .eraseToAnyPublisher()
    }

    /// Open a secure session with a Card for further scheduling/attaching Publisher commands
    ///
    /// - Note: The negotiated SecureHealthCard should be used for the commands to be executed on the secure channel.
    ///   After the chain has completed the session should be invalidated/closed.
    ///
    /// - Parameters:
    ///     - can: The Channel access number for the session
    ///     - writeTimeout: time in seconds. Default: 30
    ///     - readTimeout: time in seconds. Default 30
    /// - Returns: SecureHealthCard
    public func openSecureSession(
        can: CAN,
        writeTimeout: TimeInterval = 30,
        readTimeout: TimeInterval = 30
    ) async throws -> HealthCardType {
        CommandLogger.commands.append(Command(message: "Open secure Session", type: .description))
        let channel = try openBasicChannel()
        // Read/Determine ApplicationIdentifier of the card's initial application
        let cardAid = try await channel.determineCardAid(writeTimeout: writeTimeout, readTimeout: readTimeout)

        // Read EF.CardAccess and determine the algorithm for the key agreement (e.g. PACE)
        let keyAgreementAlgorithm = try await channel.readKeyAgreementAlgorithm(cardAid: cardAid)
        // Read EF.Version2 and determine HealthCardPropertyType
        let cardType = try await channel.readCardType(
            cardAid: cardAid,
            writeTimeout: writeTimeout,
            readTimeout: readTimeout
        )
        let healthCard = try HealthCard(card: self, status: .valid(cardType: cardType))
        let sessionKey = try await keyAgreementAlgorithm.negotiateSessionKey(
            card: healthCard,
            can: can,
            writeTimeout: writeTimeout,
            readTimeout: readTimeout
        )
        return SecureHealthCard(session: sessionKey, card: healthCard)
    }

    /// Open a secure session with a Card for further scheduling/attaching Publisher commands
    ///
    /// - Note: The healthCard provided by the Combine operation chain should be used for the commands
    ///   to be executed on the secure channel.
    ///   After the chain has completed the session should be invalidated/closed.
    ///
    /// - Parameters:
    ///     - can: The Channel access number for the session
    ///     - writeTimeout: time in seconds. Default: 30
    ///     - readTimeout: time in seconds. Default 30
    /// - Returns: Publisher that negotiates a secure session when scheduled to run.
    public func openSecureSession(can: String, writeTimeout: TimeInterval = 30, readTimeout: TimeInterval = 30)
        -> AnyPublisher<HealthCardType, Error> {
        let parsedCan: CAN
        do {
            parsedCan = try CAN.from(Data(can.utf8))
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        return openSecureSession(can: parsedCan, writeTimeout: writeTimeout, readTimeout: readTimeout)
    }
}
