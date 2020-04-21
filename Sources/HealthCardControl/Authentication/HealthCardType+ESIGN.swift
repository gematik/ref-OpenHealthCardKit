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

import Foundation
import HealthCardAccess

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
public typealias AutCertificateResponse = (info: AutCertInfo, certificate: Data)

extension HealthCardType {
    /// Read the MF/DF.ESIGN.EF.C.CH.AUT.[E256/R2048] certificate from the receiver
    ///
    /// - Returns: the certificate file and ESignInfo association to it
    public func readAutCertificate() -> Executable<AutCertificateResponse> {
        return Executable<AutCertificateResponse>.evaluate {
                guard let info = self.status.type?.autCertInfo else {
                    throw HealthCard.Error.unsupportedCardType
                }
                return info
        }
            .flatMap { info in
                return self.selectDedicated(file: info.certificate, fcp: true)
                    .flatMap { status, fcp in
                        guard let fcp = fcp, let readSize = fcp.readSize else {
                            throw ReadError.fcpMissingReadSize(state: status)
                        }
                        return self.readSelectedFile(expected: Int(readSize))
                    }
                    .map { certificate in
                        return (info: info, certificate: certificate)
                    }
            }
    }
}

extension HealthCardPropertyType {
    /// Return the card's certificate information
    /// - Note: Only supports eGK Card types
    public var autCertInfo: AutCertInfo? {
        if case .egk(let generation) = self {
            if case .g2_1 = generation {
                return .efAutE256
            }
            return .efAutR2048
        }
        /// Other cards are unsupported for now
        return nil
    }
}

extension HealthCardType {
    /// Sign a challenge (for example a hash value) for authentication.
    ///
    /// - Parameter challenge: The data to be signed
    ///
    /// - Note: Only supports eGK Card types
    ///
    /// - Returns: Executable that signs the given challenge on the card
    public func sign(challenge: Data) -> Executable<HealthCardResponseType> {
        return Executable<HealthCardResponseType>
                .evaluate {
                    guard let info = self.status.type?.autCertInfo else {
                        throw HealthCard.Error.unsupportedCardType
                    }
                    return info
                }
                .flatMap { (info: AutCertInfo) in
                    HealthCardCommand.Select.selectFile(with: info.eSign)
                            .execute(on: self)
                            .flatMap { (response: HealthCardResponseType) in
                                guard response.responseStatus == .success else {
                                    throw HealthCard.Error.operational
                                }
                                return try HealthCardCommand.ManageSE.selectSigning(key: info.key,
                                                                                    dfSpecific: true,
                                                                                    algorithm: info.algorithm)
                                        .execute(on: self)
                            }
                            .flatMap { (response: HealthCardResponseType) in
                                guard response.responseStatus == .success else {
                                    throw HealthCard.Error.operational
                                }
                                return try HealthCardCommand.PsoDSA.sign(challenge).execute(on: self)
                            }
                }
    }
}
