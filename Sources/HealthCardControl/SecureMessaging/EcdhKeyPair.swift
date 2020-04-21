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

struct EcdhKeyPair: Equatable {

    enum Error: Swift.Error {
        case suppliedPointNotOnEllipticCurve
    }

    private let privateKey: BigInt
    let publicKey: ECPoint
    let ellipticCurve: EllipticCurve

    init(privateKey: BigInt, publicKey: ECPoint, ellipticCurve: EllipticCurve = EllipticCurve.brainpoolP256r1) {
        self.privateKey = privateKey
        self.publicKey = publicKey
        self.ellipticCurve = ellipticCurve
    }

    /// Multiply inner private key with a given public key (`ECPoint`)
    /// - Parameter:
    ///     - ecPoint: `ECPoint` that will be multiplied with the this key pair's private key.
    /// - Throws: EcdhEphemeralKeyPair.Error when ecPoint is not contained in the curve this key pair was derived from
    /// - Return: The result of the multiplication
    func multiplyPrivateKey(with ecPoint: ECPoint) throws -> ECPoint {
        if !ellipticCurve.contains(point: ecPoint) {
            throw Error.suppliedPointNotOnEllipticCurve
        }
        return ellipticCurve.scalarMult(k: privateKey, ecPoint: ecPoint)
    }

    static func ==(lhs: EcdhKeyPair, rhs: EcdhKeyPair) -> Bool {
        // swiftlint:disable:previous operator_whitespace
        return lhs.ellipticCurve == rhs.ellipticCurve && lhs.publicKey == rhs.publicKey
    }
}
