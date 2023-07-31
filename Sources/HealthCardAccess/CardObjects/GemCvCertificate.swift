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

import ASN1Kit
import Foundation

/// Gematik Card verifiable (CV) Certificate (gemSpec_PKI#6.7.5)
/// - Note: BSI TR-03110 spec for self descriptive Card verifiable certificates (ISO 7816) for more info
public struct GemCvCertificate {
    public enum Error: Swift.Error {
        case unexpected(tag: ASN1DecodedTag)
        case missing(tag: ASN1DecodedTag, source: ASN1Object)
        case missingTagParameter
    }

    /// CV Certificate - 0x7F4E
    public let certificateBody: CVCBody
    /// Signature - 0x5F37
    public let signature: Data

    /// Create a GemCvCertificate from ASN.1 encoded document
    ///
    /// - Parameter asn1: Document (ASN.1) should be constructed as described in gemSpec_PKI#6.7.5
    /// - Throws: GemCvCertificate.Error
    /// - Returns: initialized certificate
    public static func from(asn1: ASN1Object) throws -> GemCvCertificate {
        guard asn1.tag == Tag.tag else {
            throw Error.unexpected(tag: asn1.tag)
        }
        guard let asn1body = asn1[CVCBody.Tag.tag] else {
            throw Error.missing(tag: CVCBody.Tag.tag, source: asn1)
        }
        guard let asn1signature = asn1[Tag.signature], let signature = asn1signature.data.primitive else {
            throw Error.missing(tag: Tag.signature, source: asn1)
        }
        return GemCvCertificate(
            certificateBody: try CVCBody.from(asn1: asn1body),
            signature: signature
        )
    }

    /// Create a GemCvCertificate from ASN.1 encoded document
    ///
    /// - Parameter data: DER encoded Data document (ASN.1) should be constructed as described in gemSpec_PKI#6.7.5
    /// - Throws: GemCvCertificate.Error or ASN1Error when decoding fails
    /// - Returns: initialized certificate
    public static func from(data: Data) throws -> GemCvCertificate {
        let asn1object = try ASN1Decoder.decode(asn1: data)
        return try from(asn1: asn1object)
    }

    /// Tag information for GemCvCertificate
    public struct Tag {
        /// Root tag
        public static let tag = ASN1DecodedTag.applicationTag(0x21)
        /// Signature tag
        public static let signature = ASN1DecodedTag.applicationTag(0x37)

        private init() {}
    }
}

extension GemCvCertificate {
    /// Serialize the CVC as ASN.1 encoded Data
    /// - Returns: ASN.1 encoded CVC
    public func asn1encode() throws -> Data {
        try ASN1Kit.create(
            tag: Tag.tag,
            data: .constructed([
                certificateBody.asn1encode(tag: CVCBody.Tag.tag),
                signature.asn1encode(tag: Tag.signature),
            ])
        )
        .serialize()
    }
}

extension GemCvCertificate: Equatable {}

/// an Iso7816CertificateBody structure. (gemSpec_PKI#6.7.5)
public struct CVCBody {
    /// Certificate Profile Identifier [CPI 0x5F29]
    public let certificateProfileIdentifier: Data // UInteger
    /// Certificate Authority Reference [CAR 0x42]
    public let certificateAuthorityReference: Data
    /// Public key [0x7F49]
    public let publicKey: CVCPublicKey
    /// Card Holder Reference [0x5F20]
    public let certificateHolderReference: Data
    /// Certificate Holder Authorization Template [0x7F4c]
    public let certificateHolderAuthorization: CVCChat
    /// Certificate Effective Date [0x5F25]
    public let certificateEffectiveDate: Data
    /// Certificate Expiration Data [0x5F24]
    public let certificateExpirationDate: Data

    /// Certificate Extensions for Terminal Authentication Version 2 [0x65]
    /// - Note: gemSpec_PKI undefined/unsupported. Return empty Array.
    public let certificateExtensions: [Data]
}

extension CVCBody: Equatable {}

extension CVCBody: ASN1CodableType {
    public init(from asn1: ASN1Object) throws {
        guard let asn1cpi = asn1[Tag.cpi], let cpi = asn1cpi.data.primitive else {
            throw GemCvCertificate.Error.missing(tag: Tag.cpi, source: asn1)
        }
        guard let asn1car = asn1[Tag.car], let car = asn1car.data.primitive else {
            throw GemCvCertificate.Error.missing(tag: Tag.car, source: asn1)
        }
        guard let asn1key = asn1[Tag.pubKey] else {
            throw GemCvCertificate.Error.missing(tag: Tag.pubKey, source: asn1)
        }
        guard let asn1chr = asn1[Tag.chr], let chr = asn1chr.data.primitive else {
            throw GemCvCertificate.Error.missing(tag: Tag.chr, source: asn1)
        }
        guard let asn1chat = asn1[Tag.chat] else {
            throw GemCvCertificate.Error.missing(tag: Tag.chat, source: asn1)
        }
        guard let asn1ced = asn1[Tag.ced], let ced = asn1ced.data.primitive else {
            throw GemCvCertificate.Error.missing(tag: Tag.ced, source: asn1)
        }
        guard let asn1cxd = asn1[Tag.cxd], let cxd = asn1cxd.data.primitive else {
            throw GemCvCertificate.Error.missing(tag: Tag.cxd, source: asn1)
        }

        self.init(
            certificateProfileIdentifier: cpi,
            certificateAuthorityReference: car,
            publicKey: try CVCPublicKey.from(asn1: asn1key),
            certificateHolderReference: chr,
            certificateHolderAuthorization: try CVCChat.from(asn1: asn1chat),
            certificateEffectiveDate: ced,
            certificateExpirationDate: cxd,
            certificateExtensions: []
        )
    }

    public func asn1encode(tag: ASN1DecodedTag?) throws -> ASN1Object {
        guard let tag = tag else {
            throw GemCvCertificate.Error.missingTagParameter
        }
        return ASN1Kit.create(
            tag: tag,
            data: .constructed([
                certificateProfileIdentifier.asn1encode(tag: CVCBody.Tag.cpi),
                certificateAuthorityReference.asn1encode(tag: CVCBody.Tag.car),
                try publicKey.asn1encode(tag: CVCBody.Tag.pubKey),
                certificateHolderReference.asn1encode(tag: CVCBody.Tag.chr),
                try certificateHolderAuthorization.asn1encode(tag: CVCBody.Tag.chat),
                certificateEffectiveDate.asn1encode(tag: CVCBody.Tag.ced),
                certificateExpirationDate.asn1encode(tag: CVCBody.Tag.cxd),
            ])
        )
    }
}

extension CVCBody {
    /// CVCBody Tag information
    public struct Tag {
        /// CVC Root body tag
        public static let tag = ASN1DecodedTag.applicationTag(0x4E)
        /// Certificate Profile Identifier tag
        public static let cpi = ASN1DecodedTag.applicationTag(0x29)
        /// Certificate Authority Reference tag
        public static let car = ASN1DecodedTag.applicationTag(0x2)
        /// Public Key tag
        public static let pubKey = ASN1DecodedTag.applicationTag(0x49)
        /// Certificate Holder Reference tag
        public static let chr = ASN1DecodedTag.applicationTag(0x20)
        /// Certificate Holder Authorization Template tag
        public static let chat = ASN1DecodedTag.applicationTag(0x4C)
        /// Certificate Effective Data tag
        public static let ced = ASN1DecodedTag.applicationTag(0x25)
        /// Certificate Expiration Date tag
        public static let cxd = ASN1DecodedTag.applicationTag(0x24)

        private init() {}
    }

    /// Create CVCBody from ASN.1 Object
    /// - Parameter asn1: object should be constructed as described in gemSpec_PKI#6.7.5 [0x7F4E]
    /// - Throws: GemCvCertificate.Error
    /// - Returns: Initialized CVCBody
    public static func from(asn1: ASN1Object) throws -> CVCBody {
        try CVCBody(from: asn1)
    }
}

/// CVC Certificate Holder Authentication Template
public struct CVCChat {
    /// Object Identifier [0x6]
    public let terminalType: ASN1Kit.ObjectIdentifier
    /// Discretionary Data [0x53]
    public let relativeAuthorization: Data
}

extension CVCChat: Equatable {}

extension CVCChat: ASN1CodableType {
    public init(from asn1: ASN1Object) throws {
        guard let asn1oid = asn1[Tag.oid], let oid = try? ObjectIdentifier(from: asn1oid) else {
            throw GemCvCertificate.Error.missing(tag: Tag.oid, source: asn1)
        }
        guard let asn1content = asn1[Tag.content], let content = asn1content.data.primitive else {
            throw GemCvCertificate.Error.missing(tag: Tag.content, source: asn1)
        }
        self.init(
            terminalType: oid,
            relativeAuthorization: content
        )
    }

    public func asn1encode(tag: ASN1DecodedTag?) throws -> ASN1Object {
        guard let tag = tag else {
            throw GemCvCertificate.Error.missingTagParameter
        }
        return ASN1Kit.create(tag: tag, data: .constructed([
            try terminalType.asn1encode(tag: CVCChat.Tag.oid),
            relativeAuthorization.asn1encode(tag: CVCChat.Tag.content),
        ]))
    }
}

extension CVCChat {
    /// CVC Chat tag info
    public struct Tag {
        /// Object identifier
        public static let oid = ASN1DecodedTag.universal(.objectIdentifier)
        /// Discretionary data
        public static let content = ASN1DecodedTag.applicationTag(0x13)

        private init() {}
    }

    /// Create a CVCChat from ASN.1 object
    /// - Parameter asn1: object should be constructed as described in gemSpec_PKI#6.7.5 [0x7F4C]
    /// - Throws: GemCvCertificate.Error
    /// - Returns: Initialized CVCChat
    public static func from(asn1: ASN1Object) throws -> CVCChat {
        try CVCChat(from: asn1)
    }
}

// MARK: CVC Public Key

/// ASN.1 encoded public key
public struct CVCPublicKey {
    /// Object Identifier
    public let oid: ASN1Kit.ObjectIdentifier
    /// Raw public key material. Format could be either:
    ///     - RSAPubKey
    ///     - ECDSAPubKey
    ///     - DHPubKey
    public let pubKey: Data
}

extension CVCPublicKey: Equatable {}

extension CVCPublicKey: ASN1CodableType {
    public init(from asn1: ASN1Object) throws {
        guard let asn1oid = asn1[Tag.oid], let oid = try? ObjectIdentifier(from: asn1oid) else {
            throw GemCvCertificate.Error.missing(tag: Tag.oid, source: asn1)
        }
        guard let asn1content = asn1[Tag.content], let content = asn1content.data.primitive else {
            throw GemCvCertificate.Error.missing(tag: Tag.content, source: asn1)
        }

        self.init(
            oid: oid,
            pubKey: content
        )
    }

    public func asn1encode(tag: ASN1DecodedTag?) throws -> ASN1Object {
        guard let tag = tag else {
            throw GemCvCertificate.Error.missingTagParameter
        }
        return ASN1Kit.create(
            tag: tag,
            data: .constructed([
                try oid.asn1encode(tag: Tag.oid),
                pubKey.asn1encode(tag: Tag.content),
            ])
        )
    }
}

extension CVCPublicKey {
    /// CVCPublicKey tag info
    public struct Tag {
        /// Object identifier
        public static let oid = ASN1DecodedTag.universal(.objectIdentifier)
        /// Public Key content
        public static let content = ASN1DecodedTag.taggedTag(0x6)

        private init() {}
    }

    /// Create a CVCPublicKey from ASN.1 Object
    /// - Parameter asn1: object should be constructed as described in gemSpec_PKI#6.7.5 [0x7F49]
    /// - Throws: GemCvCertificate.Error
    /// - Returns: Initialized CVCPublicKey
    public static func from(asn1: ASN1Object) throws -> CVCPublicKey {
        try CVCPublicKey(from: asn1)
    }
}

/// Diffie Hellman Public Key
public struct DHPubKey {
    /// Object identifier
    public let oid: ASN1Kit.ObjectIdentifier
    /// Prime modulus (p)
    public let prime: Data // UInteger
    /// Order of the subgroup (q)
    public let subgroup: Data // UInteger
    /// Generator (g)
    public let generator: Data // UInteger
    /// Public value (y)
    public let value: Data // UInteger
}

extension DHPubKey: Equatable {}

/// RSA Public Key
public struct RSAPubKey {
    /// Object identifier
    public let oid: ASN1Kit.ObjectIdentifier
    /// Composite modulus (n)
    public let modulus: Data // UInteger
    /// Public exponent (e)
    public let exponent: Data // UInteger
}

extension RSAPubKey: Equatable {}

/// Elliptic Curve Public Key
public struct ECDSAPubKey {
    /// Object identifier
    public let oid: ASN1Kit.ObjectIdentifier
    /// Prime modulus (p)
    public let modulus: Data
    /// First coefficient (a)
    public let first: Data
    /// Second coefficient (b)
    public let second: Data
    /// Base point (G)
    public let base: Data
    /// Order of base point (r)
    public let order: Data
    /// Public point (Y)
    public let point: Data
    /// Cofactor (f)
    public let cofactor: Data
}

extension ECDSAPubKey: Equatable {}
