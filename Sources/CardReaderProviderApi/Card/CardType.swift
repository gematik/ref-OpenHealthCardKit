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

import Foundation
import GemCommonsKit

/// Answer-to-reset is of Type Data
public typealias ATR = Data

/// General card representation
public protocol CardType {
    /// Card Answer-to-reset configuration
    var atr: ATR { get }

    /// Card supported protocol(s)
    var `protocol`: CardProtocol { get }

    /**
        Open a communication channel to the Card.

        - Note: the basic channel assumes the channel number 0.

        - Throws: `CardError` when failed to connect to the Card.

        - Returns: The (connected) card channel
     */
    func openBasicChannel() throws -> CardChannelType

    /**
        Open a new logical channel. The channel is opened issuing a MANAGE CHANNEL command that
        should use the format [0x0, 0x70, 0x0, 0x0, 0x1].

        - Throws: `CardError` when failed to connect to the Card.

        - Returns: The (connected) card channel
     */
    func openLogicChannel() throws -> CardChannelType

    /**
        Transmit a control command to the Card/Slot

        - Note: implementation is optional.

        - Throws: `CardError`

        - Returns: The returned Data upon success.
     */
    func transmitControl(command: Int, data: Data) throws -> Data

    /// Provide an initial application identifier of an application on the underlying card (f.e. the root application).
    /// - Throws: Error when requesting the application identifier or parsing it.
    /// - Returns: The initial application identifier if known, else nil.
    func initialApplicationIdentifier() throws -> Data?

    /**
        Disconnect connection to the Card.

        - Parameter reset: true to reset the Card after disconnecting.

        - Throws: `CardError`
     */
    func disconnect(reset: Bool) throws
}

/// Default behaviour to CardType
extension CardType {
    /// Default implementation returns empty data object.
    public func transmitControl(command: Int, data: Data) throws -> Data {
        return Data.empty
    }

    /// Default implementation returns nil.
    public func initialApplicationIdentifier() throws -> Data? {
        nil
    }
}
