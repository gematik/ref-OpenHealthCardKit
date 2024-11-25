// swiftlint:disable file_length
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
import CardReaderProviderApi
import Combine
import Foundation
import HealthCardAccess
import OpenSSL
import OSLog

/// Holds functionality to negotiate a common key with a given `HealthCard` and a `CardAccessNumber`.
public enum KeyAgreement { // swiftlint:disable:this type_body_length
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

        var macTokenPrefixSize: Int {
            switch self {
            case .idPaceEcdhGmAesCbcCmac128: return 8
            }
        }

        /// Negotiate a common key with a `HealthCard` given its `CardAccessNumber`
        ///
        /// - Parameters:
        ///     - card: the card to negotiate a session key with
        ///     - can: the `CardAccessNumber` of the `HealthCard`
        ///     - writeTimeout: timeout in seconds. time <= 0 is no timeout
        ///     - readTimeout: timeout in seconds. time <= 0 is no timeout
        /// - Returns: Publisher that when successful emits PaceKey both this application and the card agreed on.
        @available(*, deprecated, message: "Use structured concurrency version instead")
        public func negotiateSessionKeyPublisher(
            card: HealthCardType,
            can: CAN,
            writeTimeout: TimeInterval = 10,
            readTimeout: TimeInterval = 10
        ) -> AnyPublisher<SecureMessaging, Swift.Error> {
            switch self {
            case .idPaceEcdhGmAesCbcCmac128:
                // Set security environment
                return step0PaceEcdhGmAesCbcCmac128(
                    card: card,
                    writeTimeout: writeTimeout,
                    readTimeout: readTimeout
                )
                // Request nonceZ from card and decrypt it to nonceS as Data
                .flatMap { _ in
                    step1PaceEcdhGmAesCbcCmac128(
                        card: card,
                        can: can,
                        writeTimeout: writeTimeout,
                        readTimeout: readTimeout
                    )
                }
                // Generate first own public key (PK1_PCD) and send it to card.
                // Receive first public key (PK1_PICC) from card
                .flatMap { nonceS in
                    step2PaceEcdhGmAesCbcCmac128(
                        card: card,
                        nonceS: nonceS,
                        writeTimeout: writeTimeout,
                        readTimeout: readTimeout
                    )
                }
                // Send own public key PK2_PCD to card and receive second public key (PK2_PICC) from card.
                // Derive PaceKey from all the information.
                .flatMap { pk2Pcd, keyPair2 in
                    step3PaceEcdhGmAesCbcCmac128(
                        card: card,
                        pk2Pcd: pk2Pcd,
                        keyPair2: keyPair2,
                        writeTimeout: writeTimeout,
                        readTimeout: readTimeout
                    )
                    .map { pk2Picc, paceKey in
                        (pk2Pcd, pk2Picc, paceKey)
                    }
                }
                // Derive MAC_PCD from a key mac and from a auth token and send it to card
                // so the card can verify it.
                // Receive MAC_PICC from card and verify it.
                .flatMap { pk2Pcd, pk2Picc, paceKey in
                    step4PaceEcdhGmAesCbcCmac128(
                        card: card,
                        pk2Picc: pk2Picc,
                        pk2Pcd: pk2Pcd,
                        paceKey: paceKey,
                        writeTimeout: writeTimeout,
                        readTimeout: readTimeout
                    )
                    .tryMap { verifyMacPicc in
                        guard verifyMacPicc else {
                            throw Error.macPiccVerificationFailedLocally
                        }
                        return paceKey
                    }
                }
                .eraseToAnyPublisher()
            }
        }

        /// Negotiate a common key with a `HealthCard` given its `CardAccessNumber`
        ///
        /// - Parameters:
        ///     - card: the card to negotiate a session key with
        ///     - can: the `CardAccessNumber` of the `HealthCard`
        ///     - writeTimeout: timeout in seconds. time <= 0 is no timeout
        ///     - readTimeout: timeout in seconds. time <= 0 is no timeout
        /// - Returns: Publisher that when successful emits PaceKey both this application and the card agreed on.
        @available(
            *,
            deprecated,
            renamed: "negotiateSessionKeyPublisher(card:can:writeTimeout:readTimeout:)"
        )
        public func negotiateSessionKey(
            card: HealthCardType,
            can: CAN,
            writeTimeout: TimeInterval = 10,
            readTimeout: TimeInterval = 10
        ) -> AnyPublisher<SecureMessaging, Swift.Error> {
            negotiateSessionKeyPublisher(card: card, can: can, writeTimeout: writeTimeout, readTimeout: readTimeout)
        }

        /// Negotiate a common key with a `HealthCard` given its `CardAccessNumber`
        ///
        /// - Parameters:
        ///     - card: the card to negotiate a session key with
        ///     - can: the `CardAccessNumber` of the `HealthCard`
        ///     - writeTimeout: timeout in seconds. time <= 0 is no timeout
        ///     - readTimeout: timeout in seconds. time <= 0 is no timeout
        /// - Returns: Instance of `SecureMessaging` employing the PACE key
        ///         that both this application and the card agreed on.
        public func negotiateSessionKeyAsync(
            card: HealthCardType,
            can: CAN,
            writeTimeout: TimeInterval = 10,
            readTimeout: TimeInterval = 10
        ) async throws -> SecureMessaging {
            switch self {
            case .idPaceEcdhGmAesCbcCmac128:
                // Set security environment
                _ = try await step0PaceEcdhGmAesCbcCmac128Async(
                    card: card,
                    writeTimeout: writeTimeout,
                    readTimeout: readTimeout
                )
                // Request nonceZ from card and decrypt it to nonceS as Data
                let nonceS = try await step1PaceEcdhGmAesCbcCmac128Async(
                    card: card,
                    can: can,
                    writeTimeout: writeTimeout,
                    readTimeout: readTimeout
                )
                // Generate first own public key (PK1_PCD) and send it to card.
                // Receive first public key (PK1_PICC) from card
                let (pk2Pcd, keyPair2) = try await step2PaceEcdhGmAesCbcCmac128Async(
                    card: card,
                    nonceS: nonceS,
                    writeTimeout: writeTimeout,
                    readTimeout: readTimeout
                )
                // Send own public key PK2_PCD to card and receive second public key (PK2_PICC) from card.
                // Derive PaceKey from all the information.
                let (pk2Picc, paceKey) = try await step3PaceEcdhGmAesCbcCmac128Async(
                    card: card,
                    pk2Pcd: pk2Pcd,
                    keyPair2: keyPair2,
                    writeTimeout: writeTimeout,
                    readTimeout: readTimeout
                )
                // Derive MAC_PCD from a key mac and from a auth token and send it to card
                // so the card can verify it.
                // Receive MAC_PICC from card and verify it.
                let verifyMacPicc = try await step4PaceEcdhGmAesCbcCmac128Async(
                    card: card,
                    pk2Picc: pk2Picc,
                    pk2Pcd: pk2Pcd,
                    paceKey: paceKey,
                    writeTimeout: writeTimeout,
                    readTimeout: readTimeout
                )
                guard verifyMacPicc else {
                    throw Error.macPiccVerificationFailedLocally
                }
                return paceKey
            }
        }
    }

    /// Set the appropriate security environment on card.
    private static func step0PaceEcdhGmAesCbcCmac128(
        card: HealthCardType,
        writeTimeout: TimeInterval,
        readTimeout: TimeInterval
    ) -> AnyPublisher<HealthCardResponseType, Swift.Error> {
        Just(Algorithm.idPaceEcdhGmAesCbcCmac128)
            .tryMap { algorithm -> (Key, ObjectIdentifier) in
                let algorithm = Algorithm.idPaceEcdhGmAesCbcCmac128
                let key = try Key(algorithm.affectedKeyId)
                let decodedOID = try ASN1Decoder.decode(asn1: try Data(hex: algorithm.protocolIdentifierHex))
                let oid = try ObjectIdentifier(from: decodedOID)
                return (key, oid)
            }
            .tryMap { key, oid -> HealthCardCommandType in
                try HealthCardCommand.ManageSE.selectPACE(symmetricKey: key, dfSpecific: false, oid: oid)
            }
            .flatMap {
                $0.publisher(for: card, writeTimeout: writeTimeout, readTimeout: readTimeout)
            }
            .eraseToAnyPublisher()
    }

    /// Set the appropriate security environment on card.
    private static func step0PaceEcdhGmAesCbcCmac128Async(
        card: HealthCardType,
        writeTimeout: TimeInterval,
        readTimeout: TimeInterval
    ) async throws -> HealthCardResponseType {
        let algorithm = Algorithm.idPaceEcdhGmAesCbcCmac128
        let key = try Key(algorithm.affectedKeyId)
        let decodedOID = try ASN1Decoder.decode(asn1: try Data(hex: algorithm.protocolIdentifierHex))
        let oid = try ObjectIdentifier(from: decodedOID)
        let selectPaceCommand = try HealthCardCommand.ManageSE.selectPACE(
            symmetricKey: key,
            dfSpecific: false,
            oid: oid
        )
        let selectPaceResponse = try await selectPaceCommand.transmit(
            to: card,
            writeTimeout: writeTimeout,
            readTimeout: readTimeout
        )
        return selectPaceResponse
    }

    /// Request nonceZ from card and decrypt it to nonceS as Data
    private static func step1PaceEcdhGmAesCbcCmac128(
        card: HealthCardType,
        can: CAN,
        writeTimeout: TimeInterval,
        readTimeout: TimeInterval
    ) -> AnyPublisher<Data, Swift.Error> {
        Just(HealthCardCommand.PACE.step1a())
            .setFailureType(to: Swift.Error.self)
            .flatMap {
                $0.publisher(for: card, writeTimeout: writeTimeout, readTimeout: readTimeout)
            }
            .tryMap { (response: HealthCardResponseType) -> Data in
                guard let responseData = response.data,
                      let nonceZ = try? KeyAgreement.extractPrimitive(constructedAsn1: responseData) else {
                    throw KeyAgreement.Error.unexpectedFormedAnswerFromCard
                }
                return nonceZ
            }
            .tryMap { (nonceZ: Data) -> Data in
                let derivedKey = KeyDerivationFunction.deriveKey(from: can.rawValue, mode: .password)
                return try AES.CBC128.decrypt(data: nonceZ, key: derivedKey)
            }
            .eraseToAnyPublisher()
    }

    /// Request nonceZ from card and decrypt it to nonceS as Data
    private static func step1PaceEcdhGmAesCbcCmac128Async(
        card: HealthCardType,
        can: CAN,
        writeTimeout: TimeInterval,
        readTimeout: TimeInterval
    ) async throws -> Data {
        let paceStep1aCommand = HealthCardCommand.PACE.step1a()
        let paceStep1aResponse = try await paceStep1aCommand.transmit(
            to: card,
            writeTimeout: writeTimeout,
            readTimeout: readTimeout
        )

        guard let responseData = paceStep1aResponse.data,
              let nonceZ = try? KeyAgreement.extractPrimitive(constructedAsn1: responseData)
        else {
            throw KeyAgreement.Error.unexpectedFormedAnswerFromCard
        }
        let derivedKey = KeyDerivationFunction.deriveKey(from: can.rawValue, mode: .password)
        return try AES.CBC128.decrypt(data: nonceZ, key: derivedKey)
    }

    /// Generate first own public key (PK1_PCD) and send it to card.
    /// Receive first public key (PK1_PICC) from card
    /// Calculate a shared secret generating point gTilde
    /// Generate a second keyPair2 PK2_PICD and public key PK2_PCD = gTilde * keyPair2.privateKey
    private static func step2PaceEcdhGmAesCbcCmac128(
        card: HealthCardType,
        nonceS: Data,
        writeTimeout: TimeInterval,
        readTimeout: TimeInterval
    ) -> AnyPublisher<(BrainpoolP256r1.KeyExchange.PublicKey, BrainpoolP256r1.KeyExchange.PrivateKey), Swift.Error> {
        Deferred { () -> AnyPublisher<BrainpoolP256r1.KeyExchange.PrivateKey, Swift.Error> in
            do {
                return Just(try BrainpoolP256r1.KeyExchange.generateKey())
                    .setFailureType(to: Swift.Error.self)
                    .eraseToAnyPublisher()
            } catch {
                return Fail(error: error).eraseToAnyPublisher()
            }
        }
        .tryMap { keyPair1 in
            let command = try HealthCardCommand.PACE.step2a(publicKey: keyPair1.publicKey.x962Value())
            return (keyPair1, command)
        }
        .flatMap { (keyPair1: BrainpoolP256r1.KeyExchange.PrivateKey, command: HealthCardCommandType) in
            command.publisher(for: card, writeTimeout: writeTimeout, readTimeout: readTimeout)
                .tryMap { pk1PiccResponse in
                    guard let pk1PiccResponseData = pk1PiccResponse.data else {
                        throw Error.unexpectedFormedAnswerFromCard
                    }
                    let pk1PiccData = try KeyAgreement.extractPrimitive(constructedAsn1: pk1PiccResponseData)
                    let pk1Picc = try BrainpoolP256r1.KeyExchange.PublicKey(x962: pk1PiccData)
                    let (pk2Pcd, keyPair2) = try keyPair1.paceMapNonce(nonce: nonceS, peerKey1: pk1Picc)

                    return (pk2Pcd, keyPair2)
                }
        }
        .eraseToAnyPublisher()
    }

    /// Generate first own public key (PK1_PCD) and send it to card.
    /// Receive first public key (PK1_PICC) from card
    /// Calculate a shared secret generating point gTilde
    /// Generate a second keyPair2 PK2_PICD and public key PK2_PCD = gTilde * keyPair2.privateKey
    private static func step2PaceEcdhGmAesCbcCmac128Async(
        card: HealthCardType,
        nonceS: Data,
        writeTimeout: TimeInterval,
        readTimeout: TimeInterval
    ) async throws -> (BrainpoolP256r1.KeyExchange.PublicKey, BrainpoolP256r1.KeyExchange.PrivateKey) {
        let keyPair1 = try BrainpoolP256r1.KeyExchange.generateKey()

        let paceStep2aCommand = try HealthCardCommand.PACE.step2a(publicKey: keyPair1.publicKey.x962Value())

        let pk1PiccResponse = try await paceStep2aCommand.transmit(
            to: card,
            writeTimeout: writeTimeout,
            readTimeout: readTimeout
        )
        guard let pk1PiccResponseData = pk1PiccResponse.data else {
            throw Error.unexpectedFormedAnswerFromCard
        }
        let pk1PiccData = try KeyAgreement.extractPrimitive(constructedAsn1: pk1PiccResponseData)
        let pk1Picc = try BrainpoolP256r1.KeyExchange.PublicKey(x962: pk1PiccData)
        let (pk2Pcd, keyPair2) = try keyPair1.paceMapNonce(nonce: nonceS, peerKey1: pk1Picc)

        return (pk2Pcd, keyPair2)
    }

    /// Send own public key PK2_PCD to card and receive second public key (PK2_PICC) from card
    /// Derive PACE key from all the information
    private static func step3PaceEcdhGmAesCbcCmac128(
        card: HealthCardType,
        pk2Pcd: BrainpoolP256r1.KeyExchange.PublicKey,
        keyPair2: BrainpoolP256r1.KeyExchange.PrivateKey,
        writeTimeout: TimeInterval,
        readTimeout: TimeInterval
    ) -> AnyPublisher<(BrainpoolP256r1.KeyExchange.PublicKey, AES128PaceKey), Swift.Error> {
        Just(pk2Pcd)
            .tryMap { pk2Pcd -> HealthCardCommandType in
                try HealthCardCommand.PACE.step3a(publicKey: pk2Pcd.x962Value())
            }
            .flatMap {
                $0.publisher(for: card, writeTimeout: writeTimeout, readTimeout: readTimeout)
            }
            .tryMap { (pk2PiccResponse: HealthCardResponseType) in
                guard let pk2PiccResponseResponseData = pk2PiccResponse.data else {
                    throw KeyAgreement.Error.unexpectedFormedAnswerFromCard
                }
                let pk2PiccData = try KeyAgreement.extractPrimitive(constructedAsn1: pk2PiccResponseResponseData)
                let pk2Picc = try BrainpoolP256r1.KeyExchange.PublicKey(x962: pk2PiccData)
                let paceKey = try KeyAgreement.derivePaceKeyEcdhAes128(publicKey: pk2Picc, keyPair: keyPair2)

                return (pk2Picc, paceKey)
            }
            .eraseToAnyPublisher()
    }

    /// Send own public key PK2_PCD to card and receive second public key (PK2_PICC) from card
    /// Derive PACE key from all the information
    private static func step3PaceEcdhGmAesCbcCmac128Async(
        card: HealthCardType,
        pk2Pcd: BrainpoolP256r1.KeyExchange.PublicKey,
        keyPair2: BrainpoolP256r1.KeyExchange.PrivateKey,
        writeTimeout: TimeInterval,
        readTimeout: TimeInterval
    ) async throws -> (BrainpoolP256r1.KeyExchange.PublicKey, AES128PaceKey) {
        let paceStep3Command = try HealthCardCommand.PACE.step3a(publicKey: pk2Pcd.x962Value())
        let pk2PiccResponse = try await paceStep3Command.transmit(
            to: card,
            writeTimeout: writeTimeout,
            readTimeout: readTimeout
        )
        guard let pk2PiccResponseResponseData = pk2PiccResponse.data else {
            throw KeyAgreement.Error.unexpectedFormedAnswerFromCard
        }
        let pk2PiccData = try KeyAgreement.extractPrimitive(constructedAsn1: pk2PiccResponseResponseData)
        let pk2Picc = try BrainpoolP256r1.KeyExchange.PublicKey(x962: pk2PiccData)
        let paceKey = try KeyAgreement.derivePaceKeyEcdhAes128(publicKey: pk2Picc, keyPair: keyPair2)

        return (pk2Picc, paceKey)
    }

    /// Derive MAC_PCD from a key mac and from a auth token and send it to card for verification
    /// Receive MAC_PICC from card and verify it
    private static func step4PaceEcdhGmAesCbcCmac128( // swiftlint:disable:this function_parameter_count
        card: HealthCardType,
        pk2Picc: BrainpoolP256r1.KeyExchange.PublicKey,
        pk2Pcd: BrainpoolP256r1.KeyExchange.PublicKey,
        paceKey: AES128PaceKey,
        writeTimeout: TimeInterval,
        readTimeout: TimeInterval
    ) -> AnyPublisher<Bool, Swift.Error> {
        let algorithm = Algorithm.idPaceEcdhGmAesCbcCmac128
        return Just(algorithm)
            .tryMap { algorithm -> HealthCardCommandType in
                let macPcd = try KeyAgreement.deriveMac(publicKeyX509: pk2Picc.x962Value(),
                                                        sessionKeyMac: paceKey.mac,
                                                        algorithm: algorithm)
                let macPcdToken = macPcd.prefix(algorithm.macTokenPrefixSize)
                return try HealthCardCommand.PACE.step4a(token: macPcdToken)
            }
            .flatMap {
                $0.publisher(for: card, writeTimeout: writeTimeout, readTimeout: readTimeout)
            }
            .tryMap { (macPiccResponse: HealthCardResponseType) -> Bool in
                if macPiccResponse.responseStatus != .success {
                    throw Error.macPcdVerificationFailedOnCard
                }
                guard let macPiccResponseData = macPiccResponse.data else {
                    throw Error.unexpectedFormedAnswerFromCard
                }
                let macPiccData = try extractPrimitive(constructedAsn1: macPiccResponseData)
                let verifyMacPiccData = try deriveMac(publicKeyX509: pk2Pcd.x962Value(),
                                                      sessionKeyMac: paceKey.mac,
                                                      algorithm: algorithm)

                return macPiccData == verifyMacPiccData.prefix(8)
            }
            .eraseToAnyPublisher()
    }

    /// Derive MAC_PCD from a key mac and from a auth token and send it to card for verification
    /// Receive MAC_PICC from card and verify it
    private static func step4PaceEcdhGmAesCbcCmac128Async( // swiftlint:disable:this function_parameter_count
        card: HealthCardType,
        pk2Picc: BrainpoolP256r1.KeyExchange.PublicKey,
        pk2Pcd: BrainpoolP256r1.KeyExchange.PublicKey,
        paceKey: AES128PaceKey,
        writeTimeout: TimeInterval,
        readTimeout: TimeInterval
    ) async throws -> Bool {
        let algorithm = Algorithm.idPaceEcdhGmAesCbcCmac128
        let macPcd = try KeyAgreement.deriveMac(
            publicKeyX509: pk2Picc.x962Value(),
            sessionKeyMac: paceKey.mac,
            algorithm: algorithm
        )
        let macPcdToken = macPcd.prefix(algorithm.macTokenPrefixSize)
        let paceStep4aCommand = try HealthCardCommand.PACE.step4a(token: macPcdToken)
        let macPiccResponse = try await paceStep4aCommand.transmit(
            to: card,
            writeTimeout: writeTimeout,
            readTimeout: readTimeout
        )
        if macPiccResponse.responseStatus != .success {
            throw Error.macPcdVerificationFailedOnCard
        }
        guard let macPiccResponseData = macPiccResponse.data else {
            throw Error.unexpectedFormedAnswerFromCard
        }
        let macPiccData = try extractPrimitive(constructedAsn1: macPiccResponseData)
        let verifyMacPiccData = try deriveMac(
            publicKeyX509: pk2Pcd.x962Value(),
            sessionKeyMac: paceKey.mac,
            algorithm: algorithm
        )

        return macPiccData == verifyMacPiccData.prefix(8)
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

    static func derivePaceKeyEcdhAes128(
        publicKey: BrainpoolP256r1.KeyExchange.PublicKey,
        keyPair: BrainpoolP256r1.KeyExchange.PrivateKey
    ) throws -> AES128PaceKey {
        let sharedSecret = try keyPair.sharedSecret(with: publicKey)
        let keyEnc = KeyDerivationFunction.deriveKey(from: sharedSecret, mode: .enc)
        let keyMac = KeyDerivationFunction.deriveKey(from: sharedSecret, mode: .mac)
        return AES128PaceKey(enc: keyEnc, mac: keyMac)
    }

    static func deriveMac(publicKeyX509: Data, sessionKeyMac: Data, algorithm: Algorithm) throws -> Data {
        let asn1AuthToken = try createAsn1AuthToken(
            publicKeyX962: publicKeyX509,
            protocolID: algorithm.protocolIdentifier
        )
        let cmac = try AES.CMAC(key: sessionKeyMac, data: asn1AuthToken)

        Logger.healthCardControl.debug("Derived cmac: \(cmac.hexString())")
        return cmac
    }

    private static func createAsn1AuthToken(publicKeyX962: Data, protocolID: String) throws -> Data {
        let asn1OID = try ObjectIdentifier.from(string: protocolID).asn1encode(tag: .taggedTag(0x6))
        let asn1 = create(tag: .taggedTag(0x6), data: ASN1Data.primitive(publicKeyX962))
        let asn1Vector = create(tag: .applicationTag(0x49), data: .constructed([asn1OID, asn1]))

        let serialized = try asn1Vector.serialize()
        Logger.healthCardControl.debug("Authentication token to derive a MAC from: \(serialized.hexString())")
        return serialized
    }
}
