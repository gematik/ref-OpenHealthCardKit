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

import HealthCardAccess

extension ResponseStatus {
    static let wrongSecretWarnings: [ResponseStatus] = [
        .wrongSecretWarningCount00,
        .wrongSecretWarningCount01,
        .wrongSecretWarningCount02,
        .wrongSecretWarningCount02,
        .wrongSecretWarningCount03,
        .wrongSecretWarningCount04,
        .wrongSecretWarningCount05,
        .wrongSecretWarningCount06,
        .wrongSecretWarningCount07,
        .wrongSecretWarningCount08,
        .wrongSecretWarningCount09,
        .wrongSecretWarningCount10,
        .wrongSecretWarningCount11,
        .wrongSecretWarningCount12,
        .wrongSecretWarningCount13,
        .wrongSecretWarningCount14,
        .wrongSecretWarningCount15,
    ]

    var retryCount: Int {
        switch self {
        case .wrongSecretWarningCount09: return 9
        case .wrongSecretWarningCount08: return 8
        case .wrongSecretWarningCount07: return 7
        case .wrongSecretWarningCount06: return 6
        case .wrongSecretWarningCount05: return 5
        case .wrongSecretWarningCount04: return 4
        case .wrongSecretWarningCount03: return 3
        case .wrongSecretWarningCount02: return 2
        case .wrongSecretWarningCount01: return 1
        default: return 0
        }
    }
}
