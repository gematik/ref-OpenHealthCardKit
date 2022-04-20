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

import CardReaderProviderApi
import Combine
import Foundation
import HealthCardAccess

/// `ApplicationIdentifier` of the application the card is initialised with
public enum CardAid: ApplicationIdentifier {
    case egk = "D2760001448000"
    case hba = "D27600014601"
    case smcb = "D27600014606"
}

extension CardChannelType {
    /// Determines the `CardAid` of the card either by
    /// using the NFCISO7816Tag.initialSelectedAID when this card is connected via NFC or
    /// selecting the MF.root application and requesting its application identifier.
    ///
    /// - Parameters:
    ///   - writeTimeout: time in seconds. Default: 30
    ///   - readTimeout: time in seconds. Default: 30
    /// - Returns: Publisher that emits the ApplicationIdentifier of the initial application of this card.
    func determineCardAid(writeTimeout _: TimeInterval = 30.0, readTimeout _: TimeInterval = 30.0)
        -> AnyPublisher<CardAid, Error> {
        let channel = self
        return Just(channel)
            .tryMap {
                try $0.card.initialApplicationIdentifier()
            }
            .flatMap { initialApplicationIdentifierData -> AnyPublisher<ApplicationIdentifier, Error> in
                if let aidData = initialApplicationIdentifierData {
                    return Just(aidData)
                        .tryMap { try ApplicationIdentifier($0) }
                        .eraseToAnyPublisher()
                } else {
                    return Just(channel.expectedLengthWildcard)
                        .tryMap { expectedLength -> HealthCardCommandType in
                            try HealthCardCommand.Select.selectRootRequestingFcp(expectedLength: expectedLength)
                        }
                        .flatMap {
                            $0.publisher(for: channel)
                        }
                        .tryMap {
                            let fcp = try FileControlParameter.parse(data: $0.data ?? Data.empty)
                            guard let aid = fcp.applicationIdentifier else {
                                throw HealthCard.Error.unknownCardType(aid: nil)
                            }
                            return aid
                        }
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
            .tryMap { (aid: ApplicationIdentifier) -> CardAid in
                guard let cardAid = CardAid(rawValue: aid) else {
                    throw HealthCard.Error.unknownCardType(aid: aid)
                }
                return cardAid
            }
            .eraseToAnyPublisher()
    }
}
