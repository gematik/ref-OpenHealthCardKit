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

/// A struct holding an APDU response and its matching `ResponseStatus`
/// derived from the executed `HealthCardCommand`.
///
/// Parameters:
///     - apduResponse
///     - responseStatus
public struct HealthCardResponse {
    /// `ResponseType` holding the response data.
    public let response: ResponseType
    /// `ResponseStatus` derived from the executed `HealthCardCommand` and *sw* value of `ResponseType
    public let responseStatus: ResponseStatus
}

extension HealthCardResponse: HealthCardResponseType {
    // swiftlint:disable identifier_name
    public var data: Data? {
        response.data
    }

    public var nr: Int {
        response.nr
    }

    public var sw1: UInt8 {
        response.sw1
    }

    public var sw2: UInt8 {
        response.sw2
    }

    public var sw: UInt16 {
        response.sw
    }

    // swiftlint:enable identifier_name
}
