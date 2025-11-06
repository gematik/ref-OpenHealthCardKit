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

/// Signature algorithms that can be used to sign a challenge for authentication.
public enum SignatureAlgorithm {
    /// Sign with ECDSA using a SHA256 digest
    case ecdsaSha256
    /// Sign with RSA PSS with mask generation function
    case sha256RsaMgf1
}

extension SignatureAlgorithm {
    /// Map PSOAlgorithm to SignatureAlgorithm
    ///
    /// - Parameter psoAlgorithm: input algorithm
    /// - Returns: the Signature algorithm or nil when unsupported/unknown
    public static func from(psoAlgorithm: PSOAlgorithm) -> SignatureAlgorithm? {
        switch psoAlgorithm {
        case .signECDSA: return .ecdsaSha256
        case .signPSS: return .sha256RsaMgf1
        default: return nil
        }
    }
}
