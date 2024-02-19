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

import CoreNFC
import NFCCardReaderProvider

extension NFCHealthCardSessionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .couldNotInitializeSession:
            return "NFCTagReaderSession could not be initalized"
        case .unsupportedTag:
            return "NFCTagReaderSession.Error: The read tag is not supported"
        case let .coreNFC(error: error):
            switch error {
            case let .tagConnectionLost(nFCReaderError):
                return nFCReaderError.localizedDescription
            case let .sessionTimeout(nFCReaderError):
                return nFCReaderError.localizedDescription

            case let .sessionInvalidated(nFCReaderError):
                return nFCReaderError.localizedDescription

            case let .userCanceled(nFCReaderError):
                return nFCReaderError.localizedDescription

            case let .unsupportedFeature(nFCReaderError):
                return nFCReaderError.localizedDescription

            case let .other(nFCReaderError):
                return nFCReaderError.localizedDescription

            case let .unknown(error):
                return error.localizedDescription
            }
        case .wrongCAN:
            return "Wrong CAN (macPcdVerificationFailedOnCard)!"
        case let .establishingSecureChannel(error):
            return error.localizedDescription
        case let .operation(error):
            return error.localizedDescription
        @unknown default:
            return "unknown NFCHealthCardSessionError"
        }
    }
}

extension NFCTagReaderSession.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .couldNotInitializeSession:
            return "NFCTagReaderSession could not be initialized"
        case .unsupportedTag:
            return "NFCTagReaderSession.Error: The read tag is not supported"
        case let .nfcTag(error: error):
            switch error {
            case let .tagConnectionLost(nFCReaderError):
                return nFCReaderError.localizedDescription
            case let .sessionTimeout(nFCReaderError):
                return nFCReaderError.localizedDescription

            case let .sessionInvalidated(nFCReaderError):
                return nFCReaderError.localizedDescription

            case let .userCanceled(nFCReaderError):
                return nFCReaderError.localizedDescription

            case let .unsupportedFeature(nFCReaderError):
                return nFCReaderError.localizedDescription

            case let .other(nFCReaderError):
                return nFCReaderError.localizedDescription

            case let .unknown(error):
                return error.localizedDescription
            }
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
        case let .nfcTag(error: coreNFCError):
            switch coreNFCError {
            case let .tagConnectionLost(readerError):
                return readerError.localizedDescription
            case let .sessionTimeout(readerError):
                return readerError.localizedDescription
            case let .sessionInvalidated(readerError):
                return readerError.localizedDescription
            case let .other(readerError):
                return readerError.localizedDescription
            case let .unknown(error):
                return error.localizedDescription
            case let .userCanceled(readerError):
                return readerError.localizedDescription
            case let .unsupportedFeature(readerError):
                return readerError.localizedDescription
            }
        @unknown default:
            return "unknown NFCCardError"
        }
    }
}
