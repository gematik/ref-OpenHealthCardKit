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

public protocol HealthCardCommandType: CommandType {
    /// Returns a dictionary mapping from *UInt16* status codes (e.g. 0x9000) to its command context specific
    /// `ResponseStatus`es.
    var responseStatuses: [UInt16: ResponseStatus] { get }
}

extension HealthCardCommandType {
    /// Returns context specific `ResponseStatus` from a UInt16 code (like 0x9000, 0x6400, ...)
    /// - Returns: `ResponseStatus`
    public func responseStatus(from code: UInt16) -> ResponseStatus {
        if let status = self.responseStatuses[code] {
            return status
        } else if code == ResponseStatus.channelClosed.code {
            return .channelClosed
        } else {
            return .customError
        }
    }

    /// Execute the command on a given card
    /// - Note: the Executable itself is not yet executed. You have to schedule/execute it on an ExecutorType
    /// - Parameters:
    ///     - card: the card to use for executing `self` on. Uses the `currentCardChannel` form the card to transmit on
    ///     - writeTimeout: the time in seconds to allow for the write to begin. time <= 0 no timeout
    ///     - readTimeout: the time in seconds to allow for the receiving to begin. time <= 0 no timeout
    /// - Returns: Executable that holds a strong reference to the command: `self`
    public func execute(on card: HealthCardType, writeTimeout: TimeInterval = 0, readTimeout: TimeInterval = 0)
                    -> Executable<HealthCardResponseType> {
        return execute(on: card.currentCardChannel, writeTimeout: writeTimeout, readTimeout: readTimeout)
    }

    /// Execute the command on a given channel
    /// - Note: the Executable itself is not yet executed. You have to schedule/execute it on an ExecutorType
    /// - Parameters:
    ///     - channel: the channe to use for executing `self` on
    ///     - writeTimeout: the time in seconds to allow for the write to begin. time <= 0 no timeout
    ///     - readTimeout: the time in seconds to allow for the receiving to begin. time <= 0 no timeout
    /// - Returns: Executable that holds a strong reference to the command: `self`
    public func execute(on channel: CardChannelType, writeTimeout: TimeInterval = 0, readTimeout: TimeInterval = 0)
                    -> Executable<HealthCardResponseType> {
        return Executable<HealthCardResponseType>
                .evaluate {
                    try channel.transmit(
                            command: self,
                            writeTimeout: writeTimeout,
                            readTimeout: readTimeout
                    )
                }
                .map {
                    HealthCardResponse.from(response: $0, for: self)
                }
    }
}
