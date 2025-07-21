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
@testable import HealthCardAccess
import Nimble
import XCTest

final class GemCvCertificateTest: XCTestCase {
    lazy var gemCvCertificate: GemCvCertificate = {
        do {
            let pubKey = try Data(hex: "04699F14B0CB2082EE0FE95B4604AF42C2ED24C4EA3EE1482992D6B63ECFCB846342935ADB" +
                "32715A3BD441DC9C5693F2BA938A25E165678BA4B317D16DA4847710")
            return GemCvCertificate(
                certificateBody: CVCBody(
                    certificateProfileIdentifier: try Data(hex: "70"),
                    certificateAuthorityReference: try Data(hex: "4445475858100218"),
                    publicKey: CVCPublicKey(
                        oid: try ObjectIdentifier.from(string: "1.3.36.3.5.3.1"),
                        pubKey: pubKey
                    ),
                    certificateHolderReference: try Data(hex: "000680276883110000205690"),
                    certificateHolderAuthorization: CVCChat(
                        terminalType: try ObjectIdentifier.from(string: "1.2.276.0.76.4.152"),
                        relativeAuthorization: try Data(hex: "005D29DAA0BB00")
                    ),
                    certificateEffectiveDate: try Data(hex: "010801000101"),
                    certificateExpirationDate: try Data(hex: "020001000101"),
                    certificateExtensions: []
                ),
                signature: try Data(hex: "0BAAA7590567250698043A6D5E3E83383A7DA724141B3B83A8EAA7C91E52B12D5C2503" +
                    "2DBFDA581E28E2537828049A1FBB81ABBAB4ED3F6E6B4098D6C685D1F6")
            )
        } catch {
            fatalError("expected GemCvCertificate creation failed: \(error)")
        }
    }()

    func testGemCvCertificateDecodingFromASN1() {
        let certData = ResourceLoader.loadResourceAsData(
            resource: "EF.C.HPC.AUTR_CVC.E256",
            withExtension: "der",
            directory: "CVC"
        )

        expect {
            try GemCvCertificate.from(data: certData)
        } == gemCvCertificate
    }

    func testGemCvCertificateEncodingToASN1() {
        let certData = ResourceLoader.loadResourceAsData(
            resource: "EF.C.HPC.AUTR_CVC.E256",
            withExtension: "der",
            directory: "CVC"
        )

        expect {
            try self.gemCvCertificate.asn1encode()
        } == certData
    }

    static let allTests = [
        ("testGemCvCertificateDecodingFromASN1", testGemCvCertificateDecodingFromASN1),
        ("testGemCvCertificateEncodingToASN1", testGemCvCertificateEncodingToASN1),
    ]
}
