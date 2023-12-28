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

import Foundation

/// Signature is raw signature Data without Algorithm information
public typealias Signature = Data
/// X509Certificate is DER encoded data
public typealias X509Certificate = Data

/// Holds the information the signature can be validated with.
public struct CertificateInfo {
    /// Certificate raw data
    public let certificate: X509Certificate
    /// Signature algorithm the signature is derived with
    public let signatureAlgorithm: SignatureAlgorithm

    /// Initialize a CertificateInfo with the signature raw data and the used signature algorithm.
    public init(certificate: X509Certificate, signatureAlgorithm: SignatureAlgorithm) {
        self.certificate = certificate
        self.signatureAlgorithm = signatureAlgorithm
    }
}
