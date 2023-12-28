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

#if os(iOS)

import CoreNFC
import Foundation

@frozen
public enum CoreNFCError: Swift.Error {
    case tagConnectionLost(NFCReaderError)
    case sessionTimeout(NFCReaderError)
    case sessionInvalidated(NFCReaderError)
    case userCanceled(NFCReaderError)
    case unsupportedFeature(NFCReaderError)
    case other(NFCReaderError)
    case unknown(Swift.Error)
}

extension Swift.Error {
    func asCoreNFCError() -> CoreNFCError {
        if let nfcReaderError = self as? NFCReaderError {
            switch nfcReaderError.code {
            case .readerTransceiveErrorTagConnectionLost,
                 .readerTransceiveErrorTagResponseError:
                return .tagConnectionLost(nfcReaderError)
            case .readerTransceiveErrorSessionInvalidated,
                 .readerSessionInvalidationErrorSessionTerminatedUnexpectedly:
                return .sessionInvalidated(nfcReaderError)
            case .readerSessionInvalidationErrorSessionTimeout:
                return .sessionTimeout(nfcReaderError)
            case .readerSessionInvalidationErrorUserCanceled:
                return .userCanceled(nfcReaderError)
            case .readerErrorUnsupportedFeature:
                return .unsupportedFeature(nfcReaderError)
            case .readerErrorSecurityViolation,
                 .readerErrorInvalidParameter,
                 .readerErrorInvalidParameterLength,
                 .readerErrorParameterOutOfBound,
                 .readerErrorRadioDisabled,
                 .readerTransceiveErrorRetryExceeded,
                 .readerTransceiveErrorTagNotConnected,
                 .readerTransceiveErrorPacketTooLong,
                 .readerSessionInvalidationErrorSystemIsBusy,
                 .readerSessionInvalidationErrorFirstNDEFTagRead,
                 .tagCommandConfigurationErrorInvalidParameters,
                 .ndefReaderSessionErrorTagNotWritable,
                 .ndefReaderSessionErrorTagUpdateFailure,
                 .ndefReaderSessionErrorTagSizeTooSmall,
                 .ndefReaderSessionErrorZeroLengthMessage:
                return .other(nfcReaderError)
            @unknown default:
                return .unknown(self)
            }
        }
        return .unknown(self)
    }
}

#endif
