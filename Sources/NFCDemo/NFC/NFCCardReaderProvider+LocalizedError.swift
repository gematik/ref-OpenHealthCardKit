// swiftlint:disable:this file_name
//
//  Copyright (c) 2022 gematik GmbH
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

import CoreNFC
import NFCCardReaderProvider

extension NFCTagReaderSession.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .couldNotInitializeSession:
            return "NFCTagReaderSession could not be initalized"
        case .unsupportedTag:
            return "NFCTagReaderSession.Error: The read tag is not supported"
        case let .nfcTag(error: error):
            return error.localizedDescription
        case let .userCancelled(error: error):
            return error.localizedDescription
        @unknown default:
            return "unknown NFCTagReaderSession.Error"
        }
    }
}

extension NFCCardError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noCardPresent:
            return "NFCCardError: no card present"
        case let .transferException(name: name):
            return "NFCCardError: transfer exception with name: \(name)"
        case .sendTimeout:
            return "NFCCardError: send timeout"
        @unknown default:
            return "unknown NFCCardError"
        }
    }
}
