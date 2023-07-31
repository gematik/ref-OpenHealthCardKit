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

/// Cryptobox command algorithm identifier - gemSpec_COS#16.1 Identifier
/// Table 268
public enum PSOAlgorithm {
    /// aes 4sm session key
    case aesSessionKey4SM
    /// des session key
    case desSessionKey4SM
    /// aes 4tc session key
    case aesSessionKey4TC
    /// des 4tc session key
    case desSessionKey4TC
    /// elc async admin
    case elcAsyncAdmin
    /// elc role auth
    case elcRoleAuthentication
    /// elc async check
    case elcRoleCheck
    /// elc 4sm session key
    case elcSessionKey4SM
    /// elc 4tc session key
    case elcSessionKey4TC
    /// rsa client auth
    case rsaClientAuthentication
    /// rsa role auth - cvc
    case rsaRoleAuthenticationOptionCVC
    /// rsa role check
    case rsaRoleCheckOptionCVC
    /// rsa session key 4sm DES
    case rsaSessionKey4SMOptionDES
    /// rsa session key 4tc DES
    case rsaSessionKey4TCOptionDES
    /// Table 269

    /// aes session key
    case aesSessionKey
    /// des session key
    case desSessionKey
    /// rsa decipher OAEP
    case rsaDecipherOAEP
    /// rsa decipher PKCS1v15
    case rsaDecipherPKCS1v15
    /// rsa encipher OAEP
    case rsaEncipherOAEP
    /// rsa encipher PKCS1v15
    case rsaEncipherPKCS1v15
    /// elc shared secret calculation
    case elcSharedSecretCalculation
    /// Table 270

    /// sign9796v2DS2
    case sign9796v2DS2
    /// signPKCS1v15
    case signPKCS1v15
    /// signPSS
    case signPSS
    /// signECDSA
    case signECDSA

    /// Algorithm identifier byte
    public var identifier: UInt8 {
        switch self {
        case .aesSessionKey4SM: return 0x54
        case .desSessionKey4SM: return 0x54
        case .aesSessionKey4TC: return 0x74
        case .desSessionKey4TC: return 0x74
        case .elcAsyncAdmin: return 0xF4
        case .elcRoleAuthentication: return 0x0
        case .elcRoleCheck: return 0x0
        case .elcSessionKey4SM: return 0x54
        case .elcSessionKey4TC: return 0xD4
        case .rsaClientAuthentication: return 0x5
        case .rsaRoleAuthenticationOptionCVC: return 0x0
        case .rsaRoleCheckOptionCVC: return 0x0
        case .rsaSessionKey4SMOptionDES: return 0x54
        case .rsaSessionKey4TCOptionDES: return 0x74
        case .aesSessionKey: return 0x0
        case .desSessionKey: return 0x0
        case .rsaDecipherOAEP: return 0x85
        case .rsaDecipherPKCS1v15: return 0x81
        case .rsaEncipherOAEP: return 0x5
        case .rsaEncipherPKCS1v15: return 0x1
        case .elcSharedSecretCalculation: return 0xB
        case .sign9796v2DS2: return 0x7
        case .signPKCS1v15: return 0x2
        case .signPSS: return 0x5
        case .signECDSA: return 0x0
        }
    }

    /// Algorithm name
    public var name: String? {
        switch self {
        case .aesSessionKey4SM: return nil
        case .desSessionKey4SM: return nil
        case .aesSessionKey4TC: return "aesSessionkey4TC"
        case .desSessionKey4TC: return "desSessionkey4TC (Option_DES)"
        case .elcAsyncAdmin: return "elcAsynchronAdmin"
        case .elcRoleAuthentication: return "elcRoleAuthentication"
        case .elcRoleCheck: return "elcRoleCheck"
        case .elcSessionKey4SM: return "elcSessionkey4SM"
        case .elcSessionKey4TC: return "elcSessionkey4SM"
        case .rsaClientAuthentication: return "rsaClientAuthentication"
        case .rsaRoleAuthenticationOptionCVC: return "rsaRoleAuthentication"
        case .rsaRoleCheckOptionCVC: return "rsaRoleCheck"
        case .rsaSessionKey4SMOptionDES: return "rsaSessionkey4SM"
        case .rsaSessionKey4TCOptionDES: return "rsaSessionkey4TC (Option_DES)"
        case .aesSessionKey: return "aesSessionkey"
        case .desSessionKey: return "desSessionkey (Option_DES)"
        case .rsaDecipherOAEP: return "rsaDecipherOaep"
        case .rsaDecipherPKCS1v15: return "rsaDecipherPKCS1_V1_5"
        case .rsaEncipherOAEP: return "rsaEncipherOaep"
        case .rsaEncipherPKCS1v15: return "rsaEncipherPKCS1_V1_5"
        case .elcSharedSecretCalculation: return "elcSharedSecretCalculation"
        case .sign9796v2DS2: return nil
        case .signPKCS1v15: return "signPKCS1_V1_5"
        case .signPSS: return "signPSS"
        case .signECDSA: return "signECDSA"
        }
    }
}
