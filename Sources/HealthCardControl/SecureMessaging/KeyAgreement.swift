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

import ASN1Kit
import BigInt
import CardReaderProviderApi
import Foundation
import GemCommonsKit
import HealthCardAccess

/// Holds functionality to negotiate a common key with a given `HealthCard` and a `CardAccessNumber`.
public class KeyAgreement {

    public enum Error: Swift.Error, Equatable {
        case illegalArgument
        case unexpectedFormedAnswerFromCard
        case resultOfEcArithmeticWasInfinite
        case macPcdVerificationFailedOnCard
        case macPiccVerificationFailedLocally
        case noValidHealthCardStatus
        case efCardAccessNotAvailable
        case unsupportedKeyAgreementAlgorithm(ASN1Kit.ObjectIdentifier)
    }

    /// Algorithm the PACE key agreement negotiation is based on.
    public enum Algorithm {
        /// id-PACE-ECDH-GM-AES-CBC-CMAC-128
        case idPaceEcdhGmAesCbcCmac128

        var protocolIdentifierHex: String {
            switch self {
            case .idPaceEcdhGmAesCbcCmac128: return "060A04007F00070202040202"
            }
        }

        var protocolIdentifier: String {
            switch self {
            case .idPaceEcdhGmAesCbcCmac128: return "0.4.0.127.0.7.2.2.4.2.2"
            }
        }

        var affectedKeyId: UInt8 {
            switch self {
            case .idPaceEcdhGmAesCbcCmac128: return 0x2
            }
        }

        var curve: EllipticCurve {
            switch self {
            case .idPaceEcdhGmAesCbcCmac128: return EllipticCurve.brainpoolP256r1
            }
        }

        var macTokenPrefixSize: Int {
            switch self {
            case .idPaceEcdhGmAesCbcCmac128: return 8
            }
        }

        /// Negotiate a common key with a `HealthCard` given its `CardAccessNumber`
        ///
        /// - Parameters:
        ///     - channel: the channel to negotiate a session key with
        ///     - can: the `CardAccessNumber` of the `HealthCard`
        ///     - writeTimeout: timeout in seconds. time <= 0 is no timeout
        ///     - readTimeout: timeout in seconds. time <= 0 is no timeout
        /// - Returns: When successful PaceKey both this application and the card agreed on.
        /// - Throws: Error
        public func negotiateSessionKey(
                channel: CardChannelType,
                can: CAN,
                writeTimeout: TimeInterval = 10,
                readTimeout: TimeInterval = 10
        ) throws -> Executable<SecureMessaging> {
            switch self {
            case .idPaceEcdhGmAesCbcCmac128:
                // Set security environment
                return try step0PaceEcdhGmAesCbcCmac128(channel: channel,
                        writeTimeout: writeTimeout,
                        readTimeout: readTimeout)
                        // Request nonceZ from card and decrypt it to nonceS as BigInt
                        .flatMap { _ in
                            try step1PaceEcdhGmAesCbcCmac128(channel: channel,
                                    can: can,
                                    writeTimeout: writeTimeout,
                                    readTimeout: readTimeout)
                        }
                        // Generate first own public key (PK1_PCD) and send it to card.
                        // Receive first public key (PK1_PICC) from card
                        .flatMap { nonceS in
                            try step2PaceEcdhGmAesCbcCmac128(channel: channel,
                                    nonceS: nonceS,
                                    writeTimeout: writeTimeout,
                                    readTimeout: readTimeout)
                        }
                        .map { pk2Pcd, keyPair2 in
                            (pk2Pcd, keyPair2)
                        }
                        // Send own public key PK2_PCD to card and receive second public key (PK2_PICC) from card.
                        // Derive PaceKey from all the information.
                        .flatMap { pk2Pcd, keyPair2 in
                            try step3PaceEcdhGmAesCbcCmac128(channel: channel,
                                    pk2Pcd: pk2Pcd,
                                    keyPair2: keyPair2,
                                    writeTimeout: writeTimeout,
                                    readTimeout: readTimeout)
                                    .map { pk2Picc, paceKey in
                                        (pk2Pcd, pk2Picc, paceKey)
                                    }
                        }
                        // Derive MAC_PCD from a key mac and from a auth token and send it to card
                        // so the card can verify it.
                        // Receive MAC_PICC from card and verify it.
                        .flatMap { pk2Pcd, pk2Picc, paceKey in
                            try step4PaceEcdhGmAesCbcCmac128(channel: channel,
                                    pk2Picc: pk2Picc,
                                    pk2Pcd: pk2Pcd,
                                    paceKey: paceKey,
                                    writeTimeout: writeTimeout,
                                    readTimeout: readTimeout)
                                    .map { verifyMacPicc in
                                        if !verifyMacPicc {
                                            throw Error.macPiccVerificationFailedLocally
                                        }
                                        return paceKey
                                    }
                        }
            }

        }
    }

    /// Set the appropriate security environment on card.
    private static func step0PaceEcdhGmAesCbcCmac128(channel: CardChannelType,
                                                     writeTimeout: TimeInterval,
                                                     readTimeout: TimeInterval) throws
                    -> Executable<HealthCardResponseType> {
        let algorithm = Algorithm.idPaceEcdhGmAesCbcCmac128
        let key = try Key(algorithm.affectedKeyId)
        let decodedOID = try ASN1Decoder.decode(asn1: try Data(hex: algorithm.protocolIdentifierHex))
        let oid = try ObjectIdentifier(from: decodedOID)
        return try HealthCardCommand.ManageSE.selectPACE(symmetricKey: key, dfSpecific: false, oid: oid)
                .execute(on: channel, writeTimeout: writeTimeout, readTimeout: readTimeout)
    }

    /// Request nonceZ from card and decrypt it to nonceS as BigInt
    private static func step1PaceEcdhGmAesCbcCmac128(channel: CardChannelType,
                                                     can: CAN,
                                                     writeTimeout: TimeInterval,
                                                     readTimeout: TimeInterval) throws
                    -> Executable<BigInt> {
        return HealthCardCommand.PACE.step1a()
                .execute(on: channel, writeTimeout: writeTimeout, readTimeout: readTimeout)
                .map { (response: HealthCardResponseType) -> Data in
                    guard let responseData = response.data,
                          let nonceZ = try? KeyAgreement.extractPrimitive(constructedAsn1: responseData) else {
                        throw KeyAgreement.Error.unexpectedFormedAnswerFromCard
                    }
                    return nonceZ
                }
                .map { (nonceZ: Data) -> BigInt in
                    let derivedKey = KeyDerivationFunction.deriveKey(from: can.rawValue, mode: .password)
                    let nonceSData = try AES.CBC128.decrypt(data: nonceZ, key: derivedKey)
                    let nonceS = BigInt(sign: .plus, magnitude: BigUInt(nonceSData))
                    return nonceS
                }
    }

    /// Generate first own public key (PK1_PCD) and send it to card.
    /// Receive first public key (PK1_PICC) from card
    /// Calculate a shared secret generating point gTilde
    /// Generate second keyPair2 and public key PK2_PCD = gTilde * keypair2.privateKey and
    private static func step2PaceEcdhGmAesCbcCmac128(channel: CardChannelType,
                                                     nonceS: BigInt,
                                                     writeTimeout: TimeInterval,
                                                     readTimeout: TimeInterval) throws
                    -> Executable<(ECPoint, EcdhKeyPair)> {
        let keyPair1 = EcdhKeyPairGenerator().generateKeyPair()
        DLog("keyPair1_PCD publicKey: \(keyPair1.publicKey.encodedUncompressed32Bytes.hexString())")
        return try HealthCardCommand.PACE.step2a(publicKey: keyPair1.publicKey.encodedUncompressed32Bytes)
                .execute(on: channel, writeTimeout: writeTimeout, readTimeout: readTimeout)
                .map { (pk1PiccResponse: HealthCardResponseType) -> (ECPoint, EcdhKeyPair) in
                    guard let pk1PiccResponseResponseData = pk1PiccResponse.data else {
                        throw Error.unexpectedFormedAnswerFromCard
                    }
                    let algorithm = Algorithm.idPaceEcdhGmAesCbcCmac128
                    let pk1PiccData =
                            try KeyAgreement.extractPrimitive(constructedAsn1: pk1PiccResponseResponseData)
                    let pk1Picc = try ECPoint.parse(encoded: pk1PiccData)

                    // calculate shared secret Point ~G = nonceS * G + sk1Pcd * pk1Picc
                    let curve = algorithm.curve
                    let summand1 = curve.scalarMult(k: nonceS, ecPoint: curve.g)
                    let summand2 = try keyPair1.multiplyPrivateKey(with: pk1Picc)
                    let gTilde = curve.addPoints(ecPoint1: summand1, ecPoint2: summand2)

                    // create second own private key SK2_PCD and return public key pk2Pcd = sk2Pcd * gTilde
                    let keyPair2 = EcdhKeyPairGenerator().generateKeyPair()
                    DLog("keyPair1_PCD publicKey: \(keyPair2.publicKey.encodedUncompressed32Bytes.hexString())")
                    let pk2Pcd = try keyPair2.multiplyPrivateKey(with: gTilde)
                    return (pk2Pcd, keyPair2)
                }
    }

    /// Send own public key PK2_PCD to card and receive second public key (PK2_PICC) from card
    /// Derive PaceKey from all the information
    private static func step3PaceEcdhGmAesCbcCmac128(channel: CardChannelType,
                                                     pk2Pcd: ECPoint,
                                                     keyPair2: EcdhKeyPair,
                                                     writeTimeout: TimeInterval,
                                                     readTimeout: TimeInterval) throws
                    -> Executable<(ECPoint, AES128PaceKey)> {
        return try HealthCardCommand.PACE.step3a(publicKey: pk2Pcd.encodedUncompressed32Bytes)
                .execute(on: channel, writeTimeout: writeTimeout, readTimeout: readTimeout)
                .map { (pk2PiccResponse: HealthCardResponseType) in
                    guard let pk2PiccResponseResponseData = pk2PiccResponse.data else {
                        throw KeyAgreement.Error.unexpectedFormedAnswerFromCard
                    }
                    let pk1PiccData = try KeyAgreement
                            .extractPrimitive(constructedAsn1: pk2PiccResponseResponseData)
                    let pk2Picc = try ECPoint.parse(encoded: pk1PiccData)
                    let paceKey = try KeyAgreement.derivePaceKeyEcdhAes128(publicKey: pk2Picc, keyPair: keyPair2)

                    return (pk2Picc, paceKey)
                }
    }

    /// Derive MAC_PCD from a key mac and from a auth token and send it to card for verification
    /// Receive MAC_PICC from card and verify it
    private static func step4PaceEcdhGmAesCbcCmac128( // swiftlint:disable:this function_parameter_count
            channel: CardChannelType,
            pk2Picc: ECPoint,
            pk2Pcd: ECPoint,
            paceKey: AES128PaceKey,
            writeTimeout: TimeInterval,
            readTimeout: TimeInterval
    ) throws -> Executable<Bool> {
        let algorithm = Algorithm.idPaceEcdhGmAesCbcCmac128

        let macPcd = try KeyAgreement.deriveMac(publicKey: pk2Picc,
                sessionKeyMac: paceKey.mac,
                algorithm: algorithm)
        let macPcdToken = macPcd.prefix(algorithm.macTokenPrefixSize)

        return try HealthCardCommand.PACE.step4a(token: macPcdToken)
                .execute(on: channel, writeTimeout: writeTimeout, readTimeout: readTimeout)
                .map { (macPiccResponse: HealthCardResponseType) -> Bool in
                    if macPiccResponse.responseStatus != .success {
                        throw Error.macPcdVerificationFailedOnCard
                    }
                    guard let macPiccResponseData = macPiccResponse.data else {
                        throw Error.unexpectedFormedAnswerFromCard
                    }
                    let macPiccData = try extractPrimitive(constructedAsn1: macPiccResponseData)
                    let verifyMacPiccData = try deriveMac(publicKey: pk2Pcd,
                            sessionKeyMac: paceKey.mac,
                            algorithm: algorithm)

                    return macPiccData == verifyMacPiccData.prefix(8)
                }
    }

    static func extractPrimitive(constructedAsn1: Data) throws -> Data {
        guard let asn1 = try? ASN1Decoder.decode(asn1: constructedAsn1),
              let asn1First = asn1.data.items?.first,
              let primitiveData = asn1First.data.primitive else {
            throw Error.unexpectedFormedAnswerFromCard
        }
        return primitiveData
    }

    static func extractProtocolIdentifier(from efAccessResponse: Data) throws -> Data {
        guard let asn1 = try? ASN1Decoder.decode(asn1: efAccessResponse),
              let asn1FirstSet = asn1.data.items?.first,
              let asn1Oid = asn1FirstSet.data.items?.first,
              let `protocol` = asn1Oid.data.primitive else {
            throw Error.unexpectedFormedAnswerFromCard
        }
        return `protocol`
    }

    static func derivePaceKeyEcdhAes128(publicKey: ECPoint, keyPair: EcdhKeyPair) throws -> AES128PaceKey {
        let sharedSecret = try keyPair.multiplyPrivateKey(with: publicKey)
        guard let sharedSecretX = sharedSecret.xCoord else {
            throw Error.resultOfEcArithmeticWasInfinite
        }
        let sharedSecretXSerialized = sharedSecretX.serialize().dropLeadingZeroByte
        let keyEnc = KeyDerivationFunction.deriveKey(from: sharedSecretXSerialized, mode: .enc)
        let keyMac = KeyDerivationFunction.deriveKey(from: sharedSecretXSerialized, mode: .mac)
        return AES128PaceKey(enc: keyEnc, mac: keyMac)
    }

    static func deriveMac(publicKey: ECPoint, sessionKeyMac: Data, algorithm: Algorithm) throws -> Data {
        let asn1AuthToken = try self.createAsn1AuthToken(ecPoint: publicKey, protocolID: algorithm.protocolIdentifier)

        let cmac = try AES.CMAC(key: sessionKeyMac, data: asn1AuthToken)
        DLog("Derived cmac: \(cmac.hexString())")

        return cmac
    }

    private static func createAsn1AuthToken(ecPoint: ECPoint, protocolID: String) throws -> Data {

        let asn1OID = try ObjectIdentifier.from(string: protocolID).asn1encode(tag: .taggedTag(0x6)) //
        let asn1 = create(tag: .taggedTag(0x6), data: ASN1Data.primitive(ecPoint.encodedUncompressed32Bytes))
        let asn1Vector = create(tag: .applicationTag(0x49), data: .constructed([asn1OID, asn1]))

        let serialized = try asn1Vector.serialize()
        DLog("Authentication token to derive a MAC from: \(serialized.hexString())")
        return serialized
    }
}
