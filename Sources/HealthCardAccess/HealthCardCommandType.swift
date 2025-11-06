//
// Copyright (Change Date see Readme), gematik GmbH
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// *******
//
// For additional notes and disclaimer from gematik and in case of changes by gematik find details in the "Readme" file.
//

import CardReaderProviderApi
import Combine
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
        if let status = responseStatuses[code] {
            return status
        } else if code == ResponseStatus.channelClosed.code {
            return .channelClosed
        } else {
            return .customError
        }
    }

    /// Execute the command on a given card
    /// - Note: the Publisher itself is not yet executed. You have to subscribe to it using a `Combine.Subscriber`
    /// - Parameters:
    ///     - card: the card to use for executing `self` on
    ///     - writeTimeout: the time in seconds to allow for the write to begin. time <= 0 no timeout
    ///     - readTimeout: the time in seconds to allow for the receiving to begin. time <= 0 no timeout
    /// - Returns: AnyPublisher that holds a strong reference to the command: `self`
    @available(*, deprecated, message: "Use structured concurrency version instead")
    public func publisher(for card: HealthCardType, writeTimeout: TimeInterval = 0, readTimeout: TimeInterval = 0)
        -> AnyPublisher<HealthCardResponseType, Swift.Error> {
        publisher(for: card.currentCardChannel, writeTimeout: writeTimeout, readTimeout: readTimeout)
    }

    /// Execute the command on a given card
    /// - Parameters:
    ///     - to: the card to use for executing `self` on
    ///     - writeTimeout: the time in seconds to allow for the write to begin. time <= 0 no timeout
    ///     - readTimeout: the time in seconds to allow for the receiving to begin. time <= 0 no timeout
    /// - Returns: HealthCardResponseType decoded from the answer received via channel.
    @available(
        *,
        deprecated,
        renamed: "transmit(to:writeTimeout:readTimeout:)"
    )
    public func transmitAsync(
        to card: HealthCardType,
        writeTimeout: TimeInterval = 0,
        readTimeout: TimeInterval = 0
    ) async throws -> HealthCardResponseType {
        try await transmit(on: card.currentCardChannel, writeTimeout: writeTimeout, readTimeout: readTimeout)
    }

    /// Execute the command on a given channel
    /// - Note: the Publisher itself is not yet executed. You have to subscribe to it using a `Combine.Subscriber`
    /// - Parameters:
    ///     - channel: the channel to use for executing `self` on
    ///     - writeTimeout: the time in seconds to allow for the write to begin. time <= 0 no timeout
    ///     - readTimeout: the time in seconds to allow for the receiving to begin. time <= 0 no timeout
    /// - Returns: AnyPublisher that holds a strong reference to the command: `self`
    @available(*, deprecated, message: "Use structured concurrency version instead")
    public func publisher(for channel: CardChannelType, writeTimeout: TimeInterval = 0, readTimeout: TimeInterval = 0)
        -> AnyPublisher<HealthCardResponseType, Swift.Error> {
        Combine.Future<ResponseType, Swift.Error> { promise in
            do {
                let res = try channel.transmitPublisher(
                    command: self,
                    writeTimeout: writeTimeout,
                    readTimeout: readTimeout
                )
                promise(.success(res))
            } catch {
                promise(.failure(error))
            }
        }
        .map {
            HealthCardResponse.from(response: $0, for: self)
        }
        .eraseToAnyPublisher()
    }

    /// Execute the command on a given channel
    /// - Parameters:
    ///     - channel: the channel to use for executing `self` on
    ///     - writeTimeout: the time in seconds to allow for the write to begin. time <= 0 no timeout
    ///     - readTimeout: the time in seconds to allow for the receiving to begin. time <= 0 no timeout
    /// - Returns: HealthCardResponseType decoded from the answer received via channel.
    @available(
        *,
        deprecated,
        renamed: "transmit(on:writeTimeout:readTimeout:)"
    )
    public func transmitAsync(
        on channel: CardChannelType,
        writeTimeout: TimeInterval = 0,
        readTimeout: TimeInterval = 0
    ) async throws -> HealthCardResponseType {
        let response = try await channel.transmitAsync(
            command: self,
            writeTimeout: writeTimeout,
            readTimeout: readTimeout
        )
        return HealthCardResponse.from(response: response, for: self)
    }
}

extension HealthCardCommandType {
    /// Execute the command on a given card
    /// - Parameters:
    ///     - to: the card to use for executing `self` on
    ///     - writeTimeout: the time in seconds to allow for the write to begin. time <= 0 no timeout
    ///     - readTimeout: the time in seconds to allow for the receiving to begin. time <= 0 no timeout
    /// - Returns: HealthCardResponseType decoded from the answer received via channel.
    public func transmit(
        to card: HealthCardType,
        writeTimeout: TimeInterval = 0,
        readTimeout: TimeInterval = 0
    ) async throws -> HealthCardResponseType {
        try await transmit(on: card.currentCardChannel, writeTimeout: writeTimeout, readTimeout: readTimeout)
    }

    /// Execute the command on a given channel
    /// - Parameters:
    ///     - channel: the channel to use for executing `self` on
    ///     - writeTimeout: the time in seconds to allow for the write to begin. time <= 0 no timeout
    ///     - readTimeout: the time in seconds to allow for the receiving to begin. time <= 0 no timeout
    /// - Returns: HealthCardResponseType decoded from the answer received via channel.
    public func transmit(
        on channel: CardChannelType,
        writeTimeout: TimeInterval = 0,
        readTimeout: TimeInterval = 0
    ) async throws -> HealthCardResponseType {
        let response = try await channel.transmitAsync(
            command: self,
            writeTimeout: writeTimeout,
            readTimeout: readTimeout
        )
        return HealthCardResponse.from(response: response, for: self)
    }
}
