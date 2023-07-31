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
import Foundation

/// HealthCard classes should implement the HealthCardType protocol
public protocol HealthCardType {
    /// The current status for the Card object
    var status: HealthCardStatus { get }

    /// The current (open) card channel that can be used to send APDU messages
    var currentCardChannel: CardChannelType { get }
}

extension HealthCardType {
    /// Convenience function to disconnect and invalidate an possibly opened session with the underlying card
    /// - Parameter reset: Bool to forward to the close call on the card
    /// - Throws: `CardError`
    public func disconnect(reset: Bool) throws {
        try currentCardChannel.card.disconnect(reset: reset)
    }
}
