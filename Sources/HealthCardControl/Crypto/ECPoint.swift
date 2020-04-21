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

/// Alias for `(x: BigInt, y: BigInt)`
public typealias ECPointCoordinates = (x: BigInt, y: BigInt)

/// Representing a point on a `EllipticCurve`.
/// Can be .infinite or .finite(ECPointCoordinates), where `ECPointCoordinates` is (x: BigInt, y:BigInt).
public enum ECPoint {
    /// Represents the point infinity
    case infinite
    /// Represents a finite point with coordinates (x: BigInt, y: BigInt)
    case finite(ECPointCoordinates)
}

extension ECPoint {

    enum InvalidArgument: Swift.Error, Equatable {
        case empty
        case encodingNotSupported
        case invalidPointEncoding
        case invalidInfinityEncoding
    }

    /// For now we only handle uncompressed input like [0x4, x, y]
    static func parse(encoded: Data) throws -> ECPoint {
        guard !encoded.isEmpty,
              let first = encoded.first else {
            throw InvalidArgument.empty
        }

        let ecPoint: ECPoint

        switch first {
        case 0x0: ecPoint = .infinite
        case 0x2: throw InvalidArgument.encodingNotSupported // not implemented
        case 0x3: throw InvalidArgument.encodingNotSupported // not implemented
        case 0x4: ecPoint = try parseUncompressed(encoded: encoded)
        case 0x6: throw InvalidArgument.encodingNotSupported // not implemented
        case 0x7: throw InvalidArgument.encodingNotSupported // not implemented
        default: throw InvalidArgument.invalidPointEncoding
        }

        if first != 0x0 && ecPoint == .infinite {
            throw InvalidArgument.invalidInfinityEncoding
        }
        return ecPoint
    }

    private static func parseUncompressed(encoded: Data) throws -> ECPoint {
        if encoded.isEmpty || encoded.first != 0x4 {
            preconditionFailure("Tried to decode an uncompressed ECPoint encoding that was empty or does not start " +
                                        "with 0x4")
        }

        if encoded.count % 2 != 1 {
            throw InvalidArgument.invalidPointEncoding
        }

        let expectedLength = encoded.count / 2
        let xCoord = BigInt.fromUnsignedData(buf: encoded, off: 1, length: expectedLength)
        let yCoord = BigInt.fromUnsignedData(buf: encoded, off: expectedLength + 1, length: 2 * expectedLength)
        return .finite((xCoord, yCoord))
    }
}

extension ECPoint {
    /// (Normalized) x coordinate of this ECPoint
    /// Returns nil when this ECPoint is infinite
    public var xCoord: BigInt? {
        switch self {
        case .infinite: return nil
        case .finite(let coords): return coords.x
        }
    }

    /// (Normalized) y coordinate of this ECPoint
    /// Returns nil when this ECPoint is infinite
    public var yCoord: BigInt? {
        switch self {
        case .infinite: return nil
        case .finite(let coords): return coords.y
        }
    }
}

extension ECPoint {
    /// Uncompressed data encoding of ECPoint. Hexadecimal representation should start with 0x04.
    /// see: https://www.secg.org/SEC1-Ver-1.0.pdf 2.3.3 EllipticCurvePoint-to-OctetString Conversion
    public var encodedUncompressed32Bytes: Data {
        return self.encoded(compression: false, padToByteCount: 32)
    }

    private func encoded(compression: Bool, padToByteCount: Int = 32) -> Data {
        switch self {
        case .infinite: return Data([0x0])
        case .finite:
            if compression {
                preconditionFailure("ECPoint encoding with compression is not implemented")
            } else {
                guard let xCoord = self.xCoord,
                      let yCoord = self.yCoord else {
                    preconditionFailure("ECPoint was said to be finite, but one coordinate was not")
                }
                return Data([0x04] +
                        xCoord.serialize().dropLeadingZeroByte.padWithLeadingZeroes(totalLength: padToByteCount) +
                        yCoord.serialize().dropLeadingZeroByte.padWithLeadingZeroes(totalLength: padToByteCount))
            }
        }
    }
}

extension ECPoint: Equatable {
    public static func ==(lhs: ECPoint, rhs: ECPoint) -> Bool {
        //swiftlint:disable:previous operator_whitespace
        switch (lhs, rhs) {
        case (.infinite, .infinite): return true
        case (.finite, .infinite), (.infinite, .finite): return false
        case (.finite(let point1), .finite(let point2)):
            return point1.x == point2.x && point1.y == point2.y
        }
    }
}

extension Data {
    var dropLeadingZeroByte: Data {
        if self.first == 0x0 {
            return self.dropFirst()
        } else {
            return self
        }
    }

    func padWithLeadingZeroes(totalLength: Int) -> Data {
        if self.count >= totalLength {
            return self
        } else {
            return Data(count: totalLength - self.count) + self
        }
    }
}

extension BigInt {
    static func fromUnsignedData(buf: Data, off: Int, length: Int) -> BigInt {
        var mag = buf
        if off != 0 || length != buf.count {
            mag = buf[off...length]
        }
        return BigInt(sign: .plus, magnitude: BigUInt(mag))
    }
}
