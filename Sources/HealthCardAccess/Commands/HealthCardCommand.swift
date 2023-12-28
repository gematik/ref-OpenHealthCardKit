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

/// *HealthCardCommand* is a struct holding a `CommandType` object and a dictionary
/// of command context specific `ResponseStatus`es.
public struct HealthCardCommand {
    /// `CommandType` holding the command data
    public let apduCommand: CommandType
    /// Dictionary mapping from *UInt16* status codes (e.g. 0x9000) to its command context specific `ResponseStatus`es.
    public let responseStatuses: [UInt16: ResponseStatus]
}

extension HealthCardCommand: HealthCardCommandType {
    public var data: Data? {
        apduCommand.data
    }

    // swiftlint:disable identifier_name
    public var ne: Int? {
        apduCommand.ne
    }

    public var nc: Int {
        apduCommand.nc
    }

    public var cla: UInt8 {
        apduCommand.cla
    }

    public var ins: UInt8 {
        apduCommand.ins
    }

    public var p1: UInt8 {
        apduCommand.p1
    }

    public var p2: UInt8 {
        apduCommand.p2
        // swiftlint:enable identifier_name
    }

    public var bytes: Data {
        apduCommand.bytes
    }
}
