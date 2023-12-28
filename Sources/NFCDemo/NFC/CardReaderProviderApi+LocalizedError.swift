// swiftlint:disable:this file_name
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

extension CardError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .securityError(error):
            return error?.localizedDescription ?? "CardError.securityError \(String(describing: error))"
        case let .connectionError(error):
            return error?.localizedDescription ?? "CardError.connectionError \(String(describing: error))"
        case let .illegalState(error):
            return error?.localizedDescription ?? "CardError.illegalState \(String(describing: error))"
        case let .objcError(exception):
            return exception?.description ?? "CardError.objcError with exception \(String(describing: exception))"
        @unknown default:
            return "unknown CardError error"
        }
    }
}

extension APDU.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .commandBodyDataTooLarge:
            return "command body data is too large"
        case .expectedResponseLengthOutOfBounds:
            return "expected response length out of bounds"
        case let .insufficientResponseData(data: data):
            return "insufficient response data: \(data)"
        @unknown default:
            return "unknown APDU.Error error"
        }
    }
}
