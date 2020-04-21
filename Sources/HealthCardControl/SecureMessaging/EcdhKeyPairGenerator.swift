//
//  Copyright (c) 2020 gematik GmbH
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//     http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import BigInt
import Foundation

/// Class for generating and holding a private/public key pair for Elliptic Curve Diffie Hellman key exchange algorithm.
final class EcdhKeyPairGenerator {

    private let ellipticCurve: EllipticCurve
    private let seed: BigInt

    /// Initialize
    /// - Parameters:
    ///     - ellipticCurve: An `EllipticCurve` to derive a valid key pair from
    ///     - seed: use a seed value for testing, when it is zero (default) the key pair is generated randomly
    /// - Notice: Use a seed value != 0 for testing purposes only! Private key will be seed times ecCurve.g
    init(ellipticCurve: EllipticCurve = EllipticCurve.brainpoolP256r1, seed: BigInt = 0) {
        self.ellipticCurve = ellipticCurve
        self.seed = seed
    }

    /// Generates a private / public key pair.
    func generateKeyPair() -> EcdhKeyPair {

        let privateKey: BigInt
        if seed != 0 { // use the seed as private key e.g.: publicKey = curve.g * seed
            privateKey = seed
        } else {
            privateKey = BigInt(BigUInt.randomInteger(withMaximumWidth: self.ellipticCurve.p.bitWidth))
        }

        let publicKey = ellipticCurve.scalarMult(k: privateKey, ecPoint: ellipticCurve.g)
        return EcdhKeyPair(privateKey: privateKey, publicKey: publicKey, ellipticCurve: ellipticCurve)
    }
}
