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

import Foundation

/// Helper that can be used for logging all send and received commands
public enum CommandLogger {
    /// Array of commands that have been logged
    public static var commands: [Command] = []
}

public struct Command: Identifiable {
    public enum CommunicationType {
        case send
        case sendSecureChannel
        case response
        case responseSecureChannel
        case description
    }

    public var id = UUID() // swiftlint:disable:this identifier_name
    public var type: CommunicationType
    public var message: String

    public init(message: String, type: CommunicationType) {
        self.message = message
        self.type = type
    }
}
