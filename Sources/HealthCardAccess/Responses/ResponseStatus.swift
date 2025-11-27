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

import Foundation

/// Named response statuses per UInt16 status code.
/// - Remark: Depending on the context a UInt16 status code can have different meanings.
public enum ResponseStatus {
    // swiftlint:disable:previous type_body_length
    /// (0x9000)
    case success
    /// (0x6f00)
    case unknownException
    /// (0x0000)
    case unknownStatus
    /// (0x6200)
    case dataTruncated
    /// (0x6281)
    case corruptDataWarning
    /// (0x6282)
    case endOfFileWarning
    /// (0x6282)
    case endOfRecordWarning
    /// (0x6282)
    case unsuccessfulSearch
    /// (0x6282)
    case fileDeactivated
    /// (0x6283)
    case fileTerminated
    /// (0x6287)
    case recordDeactivated
    /// (0x62c1)
    case transportStatusTransportPin
    /// (0x62c7)
    case transportStatusEmptyPin
    /// (0x62d0)
    case passwordDisabled
    /// (0x6300)
    case authenticationFailure
    /// (0x63cf)
    case noAuthentication
    /// (0x63c0)
    case retryCounterCount00
    /// (0x63c1)
    case retryCounterCount01
    /// (0x63c2)
    case retryCounterCount02
    /// (0x63c3)
    case retryCounterCount03
    /// (0x63c4)
    case retryCounterCount04
    /// (0x63c5)
    case retryCounterCount05
    /// (0x63c6)
    case retryCounterCount06
    /// (0x63c7)
    case retryCounterCount07
    /// (0x63c8)
    case retryCounterCount08
    /// (0x63c9)
    case retryCounterCount09
    /// (0x63ca)
    case retryCounterCount10
    /// (0x63cb)
    case retryCounterCount11
    /// (0x63cc)
    case retryCounterCount12
    /// (0x63cd)
    case retryCounterCount13
    /// (0x63ce)
    case retryCounterCount14
    /// (0x63cf)
    case retryCounterCount15
    /// (0x63c0)
    case updateRetryWarningCount00
    /// (0x63c1)
    case updateRetryWarningCount01
    /// (0x63c2)
    case updateRetryWarningCount02
    /// (0x63c3)
    case updateRetryWarningCount03
    /// (0x63c4)
    case updateRetryWarningCount04
    /// (0x63c5)
    case updateRetryWarningCount05
    /// (0x63c6)
    case updateRetryWarningCount06
    /// (0x63c7)
    case updateRetryWarningCount07
    /// (0x63c8)
    case updateRetryWarningCount08
    /// (0x63c9)
    case updateRetryWarningCount09
    /// (0x63ca)
    case updateRetryWarningCount10
    /// (0x63cb)
    case updateRetryWarningCount11
    /// (0x63cc)
    case updateRetryWarningCount12
    /// (0x63cd)
    case updateRetryWarningCount13
    /// (0x63ce)
    case updateRetryWarningCount14
    /// (0x63cf)
    case updateRetryWarningCount15
    /// (0x63c0)
    case wrongSecretWarningCount00
    /// (0x63c1)
    case wrongSecretWarningCount01
    /// (0x63c2)
    case wrongSecretWarningCount02
    /// (0x63c3)
    case wrongSecretWarningCount03
    /// (0x63c4)
    case wrongSecretWarningCount04
    /// (0x63c5)
    case wrongSecretWarningCount05
    /// (0x63c6)
    case wrongSecretWarningCount06
    /// (0x63c7)
    case wrongSecretWarningCount07
    /// (0x63c8)
    case wrongSecretWarningCount08
    /// (0x63c9)
    case wrongSecretWarningCount09
    /// (0x63ca)
    case wrongSecretWarningCount10
    /// (0x63cb)
    case wrongSecretWarningCount11
    /// (0x63cc)
    case wrongSecretWarningCount12
    /// (0x63cd)
    case wrongSecretWarningCount13
    /// (0x63ce)
    case wrongSecretWarningCount14
    /// (0x63cf)
    case wrongSecretWarningCount15
    /// (0x6400)
    case encipherError
    /// (0x6400)
    case keyInvalid
    /// (0x6400)
    case objectTerminated
    /// (0x6400)
    case parameterMismatch
    /// (0x6581)
    case memoryFailure
    /// (0x6700)
    case wrongRecordLength
    /// (0x6881)
    case channelClosed
    /// (0x6981)
    case noMoreChannelsAvailable
    /// (0x6981)
    case volatileKeyWithoutLcs
    /// (0x6981)
    case wrongFileType
    /// (0x6982)
    case securityStatusNotSatisfied
    /// (0x6983)
    case commandBlocked
    /// (0x6983)
    case keyExpired
    /// (0x6983)
    case passwordBlocked
    /// (0x6985)
    case keyAlreadyPresent
    /// (0x6985)
    case noKeyReference
    /// (0x6985)
    case noPrkReference
    /// (0x6985)
    case noPukReference
    /// (0x6985)
    case noRandom
    /// (0x6985)
    case noRecordLifeCycleStatus
    /// (0x6985)
    case passwordNotUsable
    /// (0x6985)
    case wrongRandomLength
    /// (0x6985)
    case wrongRandomOrNoKeyReference
    /// (0x6985)
    case wrongPasswordLength
    /// (0x6986)
    case noCurrentEf
    /// (0x6988)
    case incorrectSmDo
    /// (0x6a80)
    case newFileSizeWrong
    /// (0x6a80)
    case numberPreconditionWrong
    /// (0x6a80)
    case numberScenarioWrong
    /// (0x6a80)
    case verificationError
    /// (0x6a80)
    case wrongCipherText
    /// (0x6a80)
    case wrongToken
    /// (0x6a81)
    case unsupportedFunction
    /// (0x6a82)
    case fileNotFound
    /// (0x6a83)
    case recordNotFound
    /// (0x6a84)
    case dataTooBig
    /// (0x6a84)
    case fullRecordList
    /// (0x6a84)
    case messageTooLong
    /// (0x6a84)
    case outOfMemory
    /// (0x6a84)
    case fullRecordListOrOutOfMemory
    /// (0x6a88)
    case inconsistentKeyReference
    /// (0x6a88)
    case wrongKeyReference
    /// (0x6a88)
    case keyNotFound
    /// (0x6a88)
    case keyOrPrkNotFound
    /// (0x6a88)
    case keyOrPwdNotFound
    /// (0x6a88)
    case passwordNotFound
    /// (0x6a88)
    case prkNotFound
    /// (0x6a88)
    case pukNotFound
    /// (0x6a89)
    case duplicatedObjects
    /// (0x6a8a)
    case dfNameExists
    /// (0x6b00)
    case offsetTooBig
    /// (0x6d00)
    case instructionNotSupported
    /// (0x0000)
    case customError

    /// Code belonging to the status
    public var code: UInt16 {
        switch self {
        case .success: return 0x9000
        case .unknownException: return 0x6F00
        case .unknownStatus: return 0x0
        case .dataTruncated: return 0x6200
        case .corruptDataWarning: return 0x6281
        case .endOfFileWarning: return 0x6282
        case .endOfRecordWarning: return 0x6282
        case .unsuccessfulSearch: return 0x6282
        case .fileDeactivated: return 0x6282
        case .fileTerminated: return 0x6283
        case .recordDeactivated: return 0x6287
        case .transportStatusTransportPin: return 0x62C1
        case .transportStatusEmptyPin: return 0x62C7
        case .passwordDisabled: return 0x62D0
        case .authenticationFailure: return 0x6300
        case .noAuthentication: return 0x63CF
        case .retryCounterCount00: return 0x63C0
        case .retryCounterCount01: return 0x63C1
        case .retryCounterCount02: return 0x63C2
        case .retryCounterCount03: return 0x63C3
        case .retryCounterCount04: return 0x63C4
        case .retryCounterCount05: return 0x63C5
        case .retryCounterCount06: return 0x63C6
        case .retryCounterCount07: return 0x63C7
        case .retryCounterCount08: return 0x63C8
        case .retryCounterCount09: return 0x63C9
        case .retryCounterCount10: return 0x63CA
        case .retryCounterCount11: return 0x63CB
        case .retryCounterCount12: return 0x63CC
        case .retryCounterCount13: return 0x63CD
        case .retryCounterCount14: return 0x63CE
        case .retryCounterCount15: return 0x63CF
        case .updateRetryWarningCount00: return 0x63C0
        case .updateRetryWarningCount01: return 0x63C1
        case .updateRetryWarningCount02: return 0x63C2
        case .updateRetryWarningCount03: return 0x63C3
        case .updateRetryWarningCount04: return 0x63C4
        case .updateRetryWarningCount05: return 0x63C5
        case .updateRetryWarningCount06: return 0x63C6
        case .updateRetryWarningCount07: return 0x63C7
        case .updateRetryWarningCount08: return 0x63C8
        case .updateRetryWarningCount09: return 0x63C9
        case .updateRetryWarningCount10: return 0x63CA
        case .updateRetryWarningCount11: return 0x63CB
        case .updateRetryWarningCount12: return 0x63CC
        case .updateRetryWarningCount13: return 0x63CD
        case .updateRetryWarningCount14: return 0x63CE
        case .updateRetryWarningCount15: return 0x63CF
        case .wrongSecretWarningCount00: return 0x63C0
        case .wrongSecretWarningCount01: return 0x63C1
        case .wrongSecretWarningCount02: return 0x63C2
        case .wrongSecretWarningCount03: return 0x63C3
        case .wrongSecretWarningCount04: return 0x63C4
        case .wrongSecretWarningCount05: return 0x63C5
        case .wrongSecretWarningCount06: return 0x63C6
        case .wrongSecretWarningCount07: return 0x63C7
        case .wrongSecretWarningCount08: return 0x63C8
        case .wrongSecretWarningCount09: return 0x63C9
        case .wrongSecretWarningCount10: return 0x63CA
        case .wrongSecretWarningCount11: return 0x63CB
        case .wrongSecretWarningCount12: return 0x63CC
        case .wrongSecretWarningCount13: return 0x63CD
        case .wrongSecretWarningCount14: return 0x63CE
        case .wrongSecretWarningCount15: return 0x63CF
        case .encipherError: return 0x6400
        case .keyInvalid: return 0x6400
        case .objectTerminated: return 0x6400
        case .parameterMismatch: return 0x6400
        case .memoryFailure: return 0x6581
        case .wrongRecordLength: return 0x6700
        case .channelClosed: return 0x6881
        case .noMoreChannelsAvailable: return 0x6981
        case .volatileKeyWithoutLcs: return 0x6981
        case .wrongFileType: return 0x6981
        case .securityStatusNotSatisfied: return 0x6982
        case .commandBlocked: return 0x6983
        case .keyExpired: return 0x6983
        case .passwordBlocked: return 0x6983
        case .keyAlreadyPresent: return 0x6985
        case .noKeyReference: return 0x6985
        case .noPrkReference: return 0x6985
        case .noPukReference: return 0x6985
        case .noRandom: return 0x6985
        case .noRecordLifeCycleStatus: return 0x6985
        case .passwordNotUsable: return 0x6985
        case .wrongRandomLength: return 0x6985
        case .wrongRandomOrNoKeyReference: return 0x6985
        case .wrongPasswordLength: return 0x6985
        case .noCurrentEf: return 0x6986
        case .incorrectSmDo: return 0x6988
        case .newFileSizeWrong: return 0x6A80
        case .numberPreconditionWrong: return 0x6A80
        case .numberScenarioWrong: return 0x6A80
        case .verificationError: return 0x6A80
        case .wrongCipherText: return 0x6A80
        case .wrongToken: return 0x6A80
        case .unsupportedFunction: return 0x6A81
        case .fileNotFound: return 0x6A82
        case .recordNotFound: return 0x6A83
        case .dataTooBig: return 0x6A84
        case .fullRecordList: return 0x6A84
        case .messageTooLong: return 0x6A84
        case .outOfMemory: return 0x6A84
        case .fullRecordListOrOutOfMemory: return 0x6A84
        case .inconsistentKeyReference: return 0x6A88
        case .wrongKeyReference: return 0x6A88
        case .keyNotFound: return 0x6A88
        case .keyOrPrkNotFound: return 0x6A88
        case .keyOrPwdNotFound: return 0x6A88
        case .passwordNotFound: return 0x6A88
        case .prkNotFound: return 0x6A88
        case .pukNotFound: return 0x6A88
        case .duplicatedObjects: return 0x6A89
        case .dfNameExists: return 0x6A8A
        case .offsetTooBig: return 0x6B00
        case .instructionNotSupported: return 0x6D00
        case .customError: return 0x0
        }
    }
}
