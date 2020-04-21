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
import DataKit
import Foundation

/// Defined curves
extension EllipticCurve {
    /// BrainpoolP256r1 curve
    public static let brainpoolP256r1 = EllipticCurve(
            name: "brainpoolP256r1",
            // swiftlint:disable force_unwrapping
            p: BigInt("A9FB57DBA1EEA9BC3E660A909D838D726E3BF623D52620282013481D1F6E5377", radix: 16)!,
            a: BigInt("7D5A0975FC2C3057EEF67530417AFFE7FB8055C126DC5C6CE94A4B44F330B5D9", radix: 16)!,
            b: BigInt("26DC5C6CE94A4B44F330B5D9BBD77CBF958416295CF7E1CE6BCCDC18FF8C07B6", radix: 16)!,
            g: ECPoint.finite(
                    (BigInt("8BD2AEB9CB7E57CB2C4B482FFC81B7AFB9DE27E1E3BD23C23A4453BD9ACE3262", radix: 16)!,
                            BigInt("547EF835C3DAC4FD97F8461A14611DC9C27745132DED8E545C1D54C72F046997", radix: 16)!)),
            n: BigInt("A9FB57DBA1EEA9BC3E660A909D838D718C397AA3B561A6F7901E0E82974856A7", radix: 16)!,
            // swiftlint:enable force_unwrapping
            h: 1)
}

/// Structure holding parameters for defining Elliptic curves and its arithmetic operations
public struct EllipticCurve: Equatable {

    let name: String

    // swiftlint:disable identifier_name
    /// Field characteristic
    let p: BigInt

    /// Curve coefficients
    let a: BigInt
    let b: BigInt

    /// Base point
    let g: ECPoint

    /// Subgroup order
    let n: BigInt

    /// Subgroup cofactor
    let h: BigInt
    // swiftlint:disable identifier_name

    /// Returns true if the given point lies on the elliptic curve
    func contains(point: ECPoint) -> Bool {

        switch point {
        case .infinite:
            return true

        case .finite(let point):
            let x: BigInt = point.x
            let y: BigInt = point.y
            return (y * y - x * x * x - self.a * x - self.b) % self.p == 0
        }
    }

    /// Return -point
    func negate(_ point: ECPoint) -> ECPoint {
        assert(self.contains(point: point), "Point not contained in curve.")

        switch point {
        case .infinite: return .infinite
        case .finite(let point):
            let x: BigInt = point.x
            let y: BigInt = point.y

            let result = ECPoint.finite(ECPointCoordinates(x, (-y).modulus(self.p)))
            assert(self.contains(point: result))
            return result
        }
    }

    /// Returns the result of point1 + point2 according to the group law.
    func addPoints(ecPoint1: ECPoint, ecPoint2: ECPoint) -> ECPoint {
        assert(self.contains(point: ecPoint1))
        assert(self.contains(point: ecPoint2))

        switch (ecPoint1, ecPoint2) {
        case (.infinite, .infinite): return .infinite
        case (.finite, .infinite): return ecPoint1
        case (.infinite, .finite): return  ecPoint2
        case (.finite(let point1), .finite(let point2)):
            let x1: BigInt = point1.x
            let y1: BigInt = point1.y
            let x2: BigInt = point2.x
            let y2: BigInt = point2.y

            if x1 == x2 && y1 != y2 {
                // point1 + (-point1) = 0
                return .infinite
            }

            let m: BigInt
            if x1 == x2 {
                // This is the case point1 == point2
                m = (3 * x1 * x1 + self.a) * EllipticCurve.inverseModular(k: 2 * y1, p: self.p)
            } else {
                // This is the case point1 != point2
                m = (y1 - y2) * EllipticCurve.inverseModular(k: x1 - x2, p: self.p)
            }

            let x3: BigInt = (m * m - x1 - x2).modulus(self.p)
            let y3: BigInt = (m * (x1 - x3) - y1).modulus(self.p)
            let result = ECPoint.finite(ECPointCoordinates(x3, y3))

            assert(self.contains(point: result))
            return result
        }
    }

    /// Returns k * point computed using the `addPoints` algorithm
    func scalarMult(k: BigInt, ecPoint: ECPoint) -> ECPoint {
        assert(self.contains(point: ecPoint))

        if k.modulus(self.n).isZero {
            return .infinite
        }

        switch ecPoint {
        case .infinite:
            return .infinite
        case .finite:
            if k < 0 {
                // k * point = -k * (-point)
                return scalarMult(k: (-k), ecPoint: self.negate(ecPoint))
            }

            var mk = k
            var result: ECPoint = .infinite
            var addend: ECPoint = ecPoint

            while !mk.isZero {
                if mk.trailingZeroBitCount == 0 {
                    // Add
                    result = addPoints(ecPoint1: result, ecPoint2: addend)
                }
                // Double
                addend = addPoints(ecPoint1: addend, ecPoint2: addend)

                mk >>= 1
            }
            assert(self.contains(point: result))
            return result
        }
    }
}

/// Stand alone arithmetic operations needed by Elliptic Curve group arithmetic.
extension EllipticCurve {
    /// Returns the inverse of k modulo p.
    /// This function returns the only integer x such that (x * k) % p == 1.
    /// k must be non-zero and p must be a prime.
    static func inverseModular(k: BigInt, p: BigInt) -> BigInt {
        assert(!k.isZero)

        if k < 0 {
            // k ** -1 = p - (-k) ** -1(mod p)
            return p - inverseModular(k: -k, p: p)
        }

        // Extended Euclidean algorithm.
        var s = BigInt(0), old_s = BigInt(1)
        var t = BigInt(1)
        var r = p, old_r = k
        var tmp_r, tmp_s: BigInt
        var quotient: BigInt

        while !r.isZero {
            quotient = old_r / r

            tmp_r = r
            r = old_r - quotient * r
            old_r = tmp_r

            tmp_s = s
            s = old_s - quotient * s
            old_s = tmp_s

            t = old_s - quotient * t
        }

        let gcd = old_r
        let x = old_s
        // let y = old_t

        assert(gcd == BigInt(1))
        assert((k * x).modulus(p) == BigInt(1))

        return x % p
    }
}
