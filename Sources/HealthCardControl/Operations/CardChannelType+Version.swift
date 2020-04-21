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
import HealthCardAccess

enum CardAid: ApplicationIdentifier {
    case egk = "D2760001448000"
    case hba = "D27600014601"
    case smcb = "D27600014606"

    /// 5.3.4 MF / EF.Version2 (SMC-B)
    /// 5.3.8 MF / EF.Version2 (eGK)
    /// 5.3.5 MF / EF.Version2 (HBA)
    /// - Note: for all three the shortFileIdentifier is the same
    var efVersion2Sfi: ShortFileIdentifier {
        // swiftlint:disable:next force_unwrapping
        return EgkFileSystem.EF.version2.sfid!
    }
}

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
    ///     - writeTimeout: interval in seconds
    ///     - readTimeout: interval in seconds
    /// - Returns: Executor that emits a HealthCardPropertyType on successful recognition of the AID and EF.Version2
    public func readCardType(writeTimeout: TimeInterval = 30.0, readTimeout: TimeInterval = 30.0)
                    -> Executable<HealthCardPropertyType> {
        let channel = self

        return Executable<ApplicationIdentifier>
                .evaluate {
                    try channel.card.initialApplicationIdentifier()
                }
                .flatMap { (initialApplicationIdentifierData: Data?) in
                    if let aidData = initialApplicationIdentifierData {
                        return Executable<ApplicationIdentifier>.evaluate {
                            try ApplicationIdentifier(aidData)
                        }
                    } else {
                        return try HealthCardCommand.Select.selectRootRequestingFcp(
                                        expectedLength: channel.expectedLengthWildcard
                                )
                                .execute(on: channel, writeTimeout: writeTimeout, readTimeout: readTimeout)
                                .map {
                                    let fcp = try FileControlParameter.parse(data: $0.data ?? Data.empty)
                                    guard let aid = fcp.applicationIdentifier else {
                                        throw HealthCard.Error.unknownCardType(aid: nil)
                                    }
                                    return aid
                                }
                    }
                }
                .map { (aid: ApplicationIdentifier) in
                    guard let cardAid = CardAid(rawValue: aid) else {
                        throw HealthCard.Error.unknownCardType(aid: aid)
                    }
                    return cardAid
                }
                .flatMap { (cardAid: CardAid) in
                    try HealthCardCommand.Read.readFileCommand(with: cardAid.efVersion2Sfi,
                                    ne: channel.expectedLengthWildcard)
                            .execute(on: channel, writeTimeout: writeTimeout, readTimeout: readTimeout)
                            .map { response in
                                let cardVersion2 = try CardVersion2(data: response.data ?? Data.empty)
                                return try HealthCardPropertyType.from(cardAid: cardAid, cardVersion2: cardVersion2)
                            }
                }
    }
}
