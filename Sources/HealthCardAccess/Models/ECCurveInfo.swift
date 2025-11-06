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

import ASN1Kit
import Foundation

typealias ECCurve = (info: ECCurveInfo, publicKey: Data)

struct ECCurveInfo {
    enum InvalidArgument: Swift.Error, Equatable {
        case invalidSecKey
        case missingParameters
        case unsupportedKeyType(oid: ASN1Kit.ObjectIdentifier)
        case unsupportedArgument(oid: ASN1Kit.ObjectIdentifier)
        case invalidKeySize(Int)
        case invalidSignature
    }

    let oid: ASN1Kit.ObjectIdentifier
    let hashSize: Int
    let signatureSize: Int

    init(_ oid: String, _ hashSize: Int, _ signatureSize: Int) throws {
        self.oid = try ObjectIdentifier.from(string: oid)
        self.hashSize = hashSize
        self.signatureSize = signatureSize
    }

    func validate(signature: Data) -> Bool {
        signature.count == signatureSize
    }

    func validate(hash: Data) -> Bool {
        hash.count == hashSize
    }

    /// Normalize ASN.1 Signature to its raw signature value
    func normalize(signature: Data) throws -> Data {
        let sigData = try ASN1Decoder.decode(asn1: signature)
        guard let items = sigData.data.items, items.count == 2 else {
            throw InvalidArgument.invalidSignature
        }

        let rNormalized = try Data(from: items[0]).normalize(to: signatureSize / 2)
        let sNormalized = try Data(from: items[1]).normalize(to: signatureSize / 2)

        return rNormalized + sNormalized
    }

    static func parse(publicKey: SecKey) throws -> ECCurve {
        guard let attrs = SecKeyCopyAttributes(publicKey) as? [CFString: Any?],
              let valueData = attrs[kSecValueData] as? Data,
              kSecAttrKeyClassPublic == attrs[kSecAttrKeyClass] as! CFString, // swiftlint:disable:this force_cast
              !valueData.isEmpty else {
            throw InvalidArgument.invalidSecKey
        }

        if valueData[0] == 0x4 {
            // Assume uncompressed curve value
            return try parse(curve: valueData)
        } else {
            // ASN.1 Decode Public SecKey ValueData
            let asn1 = try ASN1Decoder.decode(asn1: valueData)
            return try parse(from: asn1)
        }
    }

    private static func parse(curve: Data) throws -> ECCurve {
        let keyLength = curve.count - 1
        guard let info = ECCurveInfo.ecCurves.first(where: { curveInfo in curveInfo.signatureSize == keyLength })
        else {
            throw InvalidArgument.invalidKeySize(keyLength)
        }
        return (info, curve)
    }

    private static func parse(from asn1: ASN1Object) throws -> ECCurve {
        // Make sure the decoded ValueData is formatted correctly
        // e.g. DER PublicKeyInfo
        guard let items = asn1.data.items, items.count > 1,
              let identifiers = items[0].data.items,
              identifiers.count > 1 else {
            throw InvalidArgument.missingParameters
        }

        let oid = try ObjectIdentifier(from: identifiers[0])
        let algId = try ObjectIdentifier(from: identifiers[1])

        guard oid == ECPublicKeyOID else {
            throw InvalidArgument.unsupportedKeyType(oid: oid)
        }

        guard let curveInfo = ecCurves.first(where: { $0.oid == algId }) else {
            throw InvalidArgument.unsupportedArgument(oid: algId)
        }

        let keyObject = items[1]
        let publicKeyData = try Data(from: keyObject)
        return (info: curveInfo, publicKey: publicKeyData)
    }

    /// Key-Value array with supported EC info
    static let ecCurves: [ECCurveInfo] = [
        ansix9p256r1,
        ansix9p384r1,
        brainpoolP256r1,
        brainpoolP384r1,
        brainpoolP512r1,
    ]
}

// swiftlint:disable force_try
let ECPublicKeyOID = try! ObjectIdentifier.from(string: "1.2.840.10045.2.1")
let ansix9p256r1 = try! ECCurveInfo("1.2.840.10045.3.1.7", 32, 64)
let ansix9p384r1 = try! ECCurveInfo("1.3.132.0.34", 48, 96)
let brainpoolP256r1 = try! ECCurveInfo("1.3.36.3.3.2.8.1.1.7", 32, 64)
let brainpoolP384r1 = try! ECCurveInfo("1.3.36.3.3.2.8.1.1.11", 48, 96)
let brainpoolP512r1 = try! ECCurveInfo("1.3.36.3.3.2.8.1.1.13", 64, 128)
