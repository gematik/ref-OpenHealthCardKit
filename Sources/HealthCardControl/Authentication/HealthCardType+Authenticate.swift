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

/// The expected result when signing data that can be used to authenticate
public typealias AuthenticationResult = (certificate: CertificateInfo, signature: Signature)

extension HealthCardType {
    /// Authenticate a challenge on HealthCardType
    ///
    /// - Note: the HealthCard needs to be in a unlocked (e.g. mrPinHome verified) state.
    ///
    /// - Parameter challenge: the data to sign
    /// - Returns: Published Aut certificate combined with its signature method and DSA signed challenge data
    @available(*, deprecated, message: "Use structured concurrency version instead")
    public func authenticate(challenge: Data) -> AnyPublisher<AuthenticationResult, Error> {
        readAutCertificate()
            .tryMap { try $0.certificateInfo() }
            .flatMap { info in
                self.sign(data: challenge)
                    .tryMap { (response: HealthCardResponseType) in
                        guard response.responseStatus == .success,
                              let signatureData = response.data else {
                            throw HealthCard.Error.unexpectedResponse(
                                actual: response.responseStatus, expected: .success
                            )
                        }
                        return (info as CertificateInfo, signatureData as Signature)
                    }
            }
            .eraseToAnyPublisher()
    }

    /// Authenticate a challenge on HealthCardType
    ///
    /// - Note: the HealthCard needs to be in a unlocked (e.g. mrPinHome verified) state.
    ///
    /// - Parameter challenge: the data to sign
    /// - Returns: AuthenticationResult (Aut certificate and its signature method and DSA signed challenge data)
    public func authenticateAsync(challenge: Data) async throws -> AuthenticationResult {
        let autCertificate = try await readAutCertificateAsync()
        let certificateInfo = try autCertificate.certificateInfo()
        let signResponse = try await signAsync(data: challenge)
        guard signResponse.responseStatus == .success,
              let signatureData = signResponse.data
        else {
            throw HealthCard.Error.unexpectedResponse(actual: signResponse.responseStatus, expected: .success)
        }
        return (certificateInfo as CertificateInfo, signatureData as Signature)
    }
}

extension AutCertificateResponse {
    /// Read the MF/DF.ESIGN.EF.C.CH.AUT.[E256/R2048] certificate from the HealthCardType
    ///
    /// - Returns: Published Aut certificated with its signature method
    func certificateInfo() throws -> CertificateInfo {
        let algorithm = info.algorithm
        let certificateDER = certificate
        guard let signatureAlgorithm = SignatureAlgorithm.from(psoAlgorithm: algorithm) else {
            throw HealthCard.Error.operational
        }
        return CertificateInfo(
            certificate: certificateDER,
            signatureAlgorithm: signatureAlgorithm
        )
    }
}
