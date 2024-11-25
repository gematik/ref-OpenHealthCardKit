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

import Combine
import Foundation
import HealthCardAccess
import Helper

/// MF/DF.ESIGN.EF.C.CH.AUT type
public enum AutCertInfo {
    /// eGK2 ESign certificate
    case efAutR2048
    /// eGK2.1 ESign certificate
    case efAutE256

    /// The ESIGN file location on the card
    public var eSign: HealthCardAccess.ApplicationIdentifier {
        EgkFileSystem.DF.ESIGN.aid
    }

    /// The certificate file location on the card
    public var certificate: DedicatedFile {
        if case .efAutR2048 = self {
            return DedicatedFile(aid: eSign, fid: EgkFileSystem.EF.esignCChAutR2048.fid)
        } else {
            return DedicatedFile(aid: eSign, fid: EgkFileSystem.EF.esignCChAutE256.fid)
        }
    }

    /// The associated signing algorithm for the certificate type
    public var algorithm: PSOAlgorithm {
        if case .efAutR2048 = self {
            return .signPSS
        } else {
            return .signECDSA
        }
    }

    /// The associated key for signing
    public var key: Key {
        if case .efAutR2048 = self {
            return try! Key(2) // swiftlint:disable:this force_try
        } else {
            return try! Key(4) // swiftlint:disable:this force_try
        }
    }
}

/// Alias for the certificate response that holds the raw certificate + the AutCertInfo associated with it.
public struct AutCertificateResponse {
    /// Default initializer for AutCertificateResponse
    ///
    /// - Parameters:
    ///  - info: The AutCertInfo associated with the certificate
    ///  - certificate: Raw certificate data
    public init(info: AutCertInfo, certificate: Data) {
        self.info = info
        self.certificate = certificate
    }

    /// The AutCertInfo associated with the certificate
    public let info: AutCertInfo
    /// Raw certificate data
    public let certificate: Data
}

extension HealthCardType {
    /// Read the MF/DF.ESIGN.EF.C.CH.AUT.[E256/R2048] certificate from the receiver
    ///
    /// - Returns: Publisher that tries to read the authentication certificate file and ESignInfo associated to it
    @available(*, deprecated, message: "Use structured concurrency version instead")
    public func readAutCertificatePublisher() -> AnyPublisher<AutCertificateResponse, Error> {
        CommandLogger.commands.append(Command(message: "Read Auth Certificate", type: .description))
        let expectedFcpLength = currentCardChannel.maxResponseLength
        return Deferred { () -> AnyPublisher<AutCertificateResponse, Error> in
            guard let info = self.status.type?.autCertInfo else {
                return Fail(error: HealthCard.Error.unsupportedCardType).eraseToAnyPublisher()
            }
            return self.selectDedicatedPublisher(file: info.certificate, fcp: true, length: expectedFcpLength)
                .tryMap { status, fcp in
                    guard let fcp = fcp, let readSize = fcp.readSize else {
                        throw ReadError.fcpMissingReadSize(state: status)
                    }
                    return readSize
                }
                .flatMap { (readSize: UInt) in
                    self.readSelectedFilePublisher(expected: Int(readSize))
                        .map { certificate in
                            AutCertificateResponse(info: info, certificate: certificate)
                        }
                }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    /// Read the MF/DF.ESIGN.EF.C.CH.AUT.[E256/R2048] certificate from the receiver
    ///
    /// - Returns: Publisher that tries to read the authentication certificate file and ESignInfo associated to it
    @available(*, deprecated, renamed: "readAutCertificatePublisher()")
    public func readAutCertificate() -> AnyPublisher<AutCertificateResponse, Error> {
        readAutCertificatePublisher()
    }

    /// Read the MF/DF.ESIGN.EF.C.CH.AUT.[E256/R2048] certificate from the receiver
    ///
    /// - Returns: `AutCertificateResponse` after trying to read the authentication certificate file
    ///         and ESignInfo associated to it
    public func readAutCertificateAsync() async throws -> AutCertificateResponse {
        CommandLogger.commands.append(Command(message: "Read Auth Certificate", type: .description))
        let expectedFcpLength = currentCardChannel.maxResponseLength
        guard let info = self.status.type?.autCertInfo else {
            throw HealthCard.Error.unsupportedCardType
        }

        let (status, fcp) = try await selectDedicatedAsync(file: info.certificate, fcp: true, length: expectedFcpLength)
        guard let fcp = fcp, let readSize = fcp.readSize else {
            throw ReadError.fcpMissingReadSize(state: status)
        }

        let certificate = try await readSelectedFileAsync(expected: Int(readSize))
        return AutCertificateResponse(info: info, certificate: certificate)
    }
}

extension HealthCardPropertyType {
    /// Return the card's certificate information
    /// - Note: Only supports eGK Card types
    public var autCertInfo: AutCertInfo? {
        if case let .egk(generation) = self {
            if case .g2_1 = generation {
                return .efAutE256
            }
            return .efAutR2048
        }
        /// Other cards are unsupported for now
        return nil
    }
}

extension AutCertInfo {
    /// Return the authentication signature digest method
    public var signatureHashMethod: (Data) -> Data {
        switch self {
        case .efAutE256: return { data in data.sha256() }
        case .efAutR2048: return { data in data.sha256() }
        }
    }
}

extension HealthCardType {
    /// Sign a challenge (for example a hash value) for authentication.
    ///
    /// - Parameters:
    ///   - data: The data to be signed
    ///   - hasher: function that hashes the data before signing it
    ///         Defaults to a hash function according to the `AutCertInfo` that is read from `self` in the process.
    /// - Note: If `data` is already hashed properly and/or needs no hashing, you must provide a no-op hasher
    ///         e.g. { data, _ in return data }
    /// - Returns: Executable that signs the given data on the card
    @available(*, deprecated, message: "Use structured concurrency version instead")
    public func signPublisher(
        data: Data,
        hasher: @escaping (Data, AutCertInfo) -> Data = { data, cert in cert.signatureHashMethod(data) }
    )
        -> AnyPublisher<HealthCardResponseType, Error> {
        Deferred { () -> AnyPublisher<HealthCardResponseType, Error> in
            guard let info = self.status.type?.autCertInfo else {
                return Fail(error: HealthCard.Error.unsupportedCardType).eraseToAnyPublisher()
            }
            return HealthCardCommand.Select.selectFile(with: info.eSign)
                .publisher(for: self)
                .flatMap { (response: HealthCardResponseType) -> AnyPublisher<HealthCardResponseType, Error> in
                    guard response.responseStatus == .success else {
                        return Fail(error: HealthCard.Error.operational).eraseToAnyPublisher()
                    }
                    do {
                        return try HealthCardCommand.ManageSE.selectSigning(
                            key: info.key,
                            dfSpecific: true,
                            algorithm: info.algorithm
                        )
                        .publisher(for: self)
                        .flatMap { response -> AnyPublisher<HealthCardResponseType, Error> in
                            guard response.responseStatus == .success else {
                                return Fail(error: HealthCard.Error.operational).eraseToAnyPublisher()
                            }
                            do {
                                let digest = hasher(data, info)
                                return try HealthCardCommand.PsoDSA.sign(digest)
                                    .publisher(for: self)
                                    .eraseToAnyPublisher()
                            } catch {
                                return Fail(error: error).eraseToAnyPublisher()
                            }
                        }
                        .eraseToAnyPublisher()
                    } catch {
                        return Fail(error: error).eraseToAnyPublisher()
                    }
                }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    /// Sign a challenge (for example a hash value) for authentication.
    ///
    /// - Parameters:
    ///   - data: The data to be signed
    ///   - hasher: function that hashes the data before signing it
    ///         Defaults to a hash function according to the `AutCertInfo` that is read from `self` in the process.
    /// - Note: If `data` is already hashed properly and/or needs no hashing, you must provide a no-op hasher
    ///         e.g. { data, _ in return data }
    /// - Returns: Executable that signs the given data on the card
    @available(*, deprecated, renamed: "signPublisher(data:hasher:)")
    public func sign(
        data: Data,
        hasher _: @escaping (Data, AutCertInfo) -> Data = { data, cert in cert.signatureHashMethod(data) }
    )
        -> AnyPublisher<HealthCardResponseType, Error> {
        signPublisher(data: data)
    }

    /// Sign a challenge (for example a hash value) for authentication.
    ///
    /// - Parameters:
    ///   - data: The data to be signed
    ///   - hasher: function that hashes the data before signing it
    ///         Defaults to a hash function according to the `AutCertInfo` that is read from `self` in the process.
    /// - Note: If `data` is already hashed properly and/or needs no hashing, you must provide a no-op hasher
    ///         e.g. { data, _ in return data }
    /// - Returns: HealthCardResponseType after PsoDSA.sign trying to sign the given data on the card
    public func signAsync(
        data: Data,
        hasher: @escaping (Data, AutCertInfo) -> Data = { data, cert in cert.signatureHashMethod(data) }
    ) async throws -> HealthCardResponseType {
        guard let info = status.type?.autCertInfo
        else {
            throw HealthCard.Error.unsupportedCardType
        }
        let selectFileCommand = HealthCardCommand.Select.selectFile(with: info.eSign)
        let selectFileResponse = try await selectFileCommand.transmit(to: self)
        guard selectFileResponse.responseStatus == .success
        else {
            throw HealthCard.Error.operational
        }
        let selectSigningCommand = try HealthCardCommand.ManageSE.selectSigning(
            key: info.key,
            dfSpecific: true,
            algorithm: info.algorithm
        )
        let selectSigningResponse = try await selectSigningCommand.transmit(to: self)
        guard selectSigningResponse.responseStatus == .success
        else {
            throw HealthCard.Error.operational
        }
        let digest = hasher(data, info)
        let psoDsaSignCommand = try HealthCardCommand.PsoDSA.sign(digest)
        let psoDsaSignResponse = try await psoDsaSignCommand.transmit(to: self)
        return psoDsaSignResponse
    }
}
