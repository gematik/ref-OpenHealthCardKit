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
import HealthCardAccess

extension HealthCardPropertyType {
    static func from(cardAid: CardAid, cardVersion2: CardVersion2) throws -> HealthCardPropertyType {
        guard let generation = cardVersion2.generation() else {
            throw HealthCard.Error.illegalGeneration(version: cardVersion2)
        }
        switch cardAid {
        case .egk:
            return .egk(generation: generation)
        case .hba:
            return .hba(generation: generation)
        case .smcb:
            return .smcb(generation: generation)
        }
    }
}

extension CardAid {
    /// 5.3.4 MF / EF.Version2 (SMC-B)
    /// 5.3.8 MF / EF.Version2 (eGK)
    /// 5.3.5 MF / EF.Version2 (HBA)
    /// - Note: for all three the shortFileIdentifier is the same
    var efVersion2Sfi: ShortFileIdentifier {
        // swiftlint:disable:next force_unwrapping
        EgkFileSystem.EF.version2.sfid!
    }
}

extension CardChannelType {
    var expectedLengthWildcard: Int {
        if extendedLengthSupported {
            return APDU.expectedLengthWildcardExtended
        }
        return APDU.expectedLengthWildcardShort
    }

    /// Determine `HealthCardPropertyType` either by known initialApplicationIdentifier of the `CardType`
    /// or trying to read EF.Version2.
    /// - Parameters:
    ///     - cardAid: `ApplicationIdentifier` of MF (root) where EF.Version2 is expected to be in.
    ///                 When now known then the function determines it by itself.
    ///     - writeTimeout: interval in seconds. Default: 30
    ///     - readTimeout: interval in seconds. Default: 30
    /// - Returns: Publisher that emits a HealthCardPropertyType on successful recognition of the AID and EF.Version2
    @available(*, deprecated, message: "Use structured concurrency version instead")
    public func readCardType(
        cardAid: CardAid? = nil,
        writeTimeout: TimeInterval = 30.0,
        readTimeout: TimeInterval = 30.0
    ) -> AnyPublisher<HealthCardPropertyType, Error> {
        let channel = self

        let cardAidPublisher: AnyPublisher<CardAid, Error>
        if let cardAid = cardAid {
            cardAidPublisher = Just(cardAid)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            cardAidPublisher = channel.determineCardAid()
        }
        return cardAidPublisher
            .flatMap { (cardAid: CardAid) in
                HealthCardCommand.Select.selectFile(with: cardAid.rawValue)
                    .publisher(for: channel, writeTimeout: writeTimeout, readTimeout: readTimeout)
                    .tryMap { _ in
                        try HealthCardCommand.Read.readFileCommand(with: cardAid.efVersion2Sfi,
                                                                   ne: channel.expectedLengthWildcard)
                    }
                    .flatMap {
                        $0.publisher(for: channel, writeTimeout: writeTimeout, readTimeout: readTimeout)
                    }
                    .tryMap { response in
                        let cardVersion2 = try CardVersion2(data: response.data ?? Data.empty)
                        return try HealthCardPropertyType.from(cardAid: cardAid, cardVersion2: cardVersion2)
                    }
            }
            .eraseToAnyPublisher()
    }

    /// Determine `HealthCardPropertyType` either by known initialApplicationIdentifier of the `CardType`
    /// or trying to read EF.Version2.
    /// - Parameters:
    ///     - cardAid: `ApplicationIdentifier` of MF (root) where EF.Version2 is expected to be in.
    ///                 When now known then the function determines it by itself.
    ///     - writeTimeout: interval in seconds. Default: 30
    ///     - readTimeout: interval in seconds. Default: 30
    /// - Returns: HealthCardPropertyType on successful recognition of the AID and EF.Version2
    public func readCardTypeAsync(
        cardAid: CardAid? = nil,
        writeTimeout: TimeInterval = 30.0,
        readTimeout: TimeInterval = 30.0
    ) async throws -> HealthCardPropertyType {
        let channel = self

        let determinedCardAid: CardAid
        if let cardAid = cardAid {
            determinedCardAid = cardAid
        } else {
            determinedCardAid = try await channel.determineCardAidAsync()
        }

        let selectCommand = HealthCardCommand.Select.selectFile(with: determinedCardAid.rawValue)
        let selectResponse = try await selectCommand.transmitAsync(
            on: channel,
            writeTimeout: writeTimeout,
            readTimeout: readTimeout
        )
        guard selectResponse.responseStatus == ResponseStatus.success
        else {
            throw HealthCard.Error.unexpectedResponse(actual: selectResponse.responseStatus, expected: .success)
        }

        let readCommand = try HealthCardCommand.Read.readFileCommand(
            with: determinedCardAid.efVersion2Sfi,
            ne: channel.expectedLengthWildcard
        )
        let readResponse = try await readCommand.transmitAsync(
            on: channel,
            writeTimeout: writeTimeout,
            readTimeout: readTimeout
        )

        let cardVersion2 = try CardVersion2(data: readResponse.data ?? Data.empty)
        return try HealthCardPropertyType.from(cardAid: determinedCardAid, cardVersion2: cardVersion2)
    }
}
