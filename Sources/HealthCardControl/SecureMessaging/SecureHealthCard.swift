//
//  Copyright (c) 2021 gematik GmbH
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
import Foundation
import HealthCardAccess

/// `SecureHealthCardType` extends the `HealthCardType` protocol to indicate that this instance has established
/// a secure communication channel to its underlying `CardChannelType`.
public protocol SecureHealthCardType: HealthCardType {}

class SecureHealthCard: SecureHealthCardType {
    private let card: HealthCardType
    private let channel: SecureCardChannel

    var status: HealthCardStatus {
        card.status
    }

    var currentCardChannel: CardChannelType {
        channel
    }

    init(session: SecureMessaging, card: HealthCardType) {
        self.card = card
        channel = SecureCardChannel(session: session, card: card)
    }
}
