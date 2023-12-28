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

/// Represent the CardVersion2 information of HealthCard
/// gemSpec_Karten_Fach_TIP_G2_1_3_0_0 #2.3 EF.Version2
public struct CardVersion2 {
    /// CardVersion2 Error
    public enum Error: Swift.Error {
        /// In case of a parse error upon initializing CardVersion2 from ASN.1 Data
        case parseError(String)
    }

    /// Information of C0 with version of filling instruction for version2
    public let fillingInstructionsVersion: Data
    /// Information of C1 with version of card object system
    public let objectSystemVersion: Data
    /// Information of C2 with version of product identification object system
    public let productIdentificationObjectSystemVersion: Data
    /// Information of C4 with version of filling instruction for EF.GDO
    public let fillingInstructionsEfGdoVersion: Data
    /// Information of C5 with version of filling instruction for EF.ATR
    public let fillingInstructionsEfAtrVersion: Data
    /// Information of C6 with version of filling instruction for EF.KeyInfo
    /// - Note: Only filled for gSMC-K and gSMC-KT
    public let fillingInstructionsEfKeyInfoVersion: Data?
    /// Information of C3 with version of filling instruction for Environment Settings
    /// - Note: Only filled for gSMC-K
    public let fillingInstructionsEfEnvironmentSettingsVersion: Data? // swiftlint:disable:this identifier_name
    /// Information of C7 with version of filling instruction for EF.GDO
    /// - Note: Only filled for egk
    public let fillingInstructionsEfLoggingVersion: Data?

    /// Parse a CardVersion2 model from ASN.1 encoded data
    /// - Parameter data: ASN.1 encoded CardVersions
    /// - Throws: CardVersion2.Error
    public init(data: Data) throws {
        let asn1 = try ASN1Decoder.decode(asn1: data)
        guard let objects = asn1.data.items else {
            throw Error.parseError("Unexpected ASN.1 format [root is not constructed]")
        }
        let taggedObjectsMap = [UInt: ASN1Object](uniqueKeysWithValues: objects.compactMap { object in
            guard let tag = object.tagNo else {
                return nil
            }
            return (tag, object)
        })

        func get(tag: UInt) throws -> Data {
            guard let data = taggedObjectsMap[tag]?.data.primitive else {
                throw Error.parseError("Unexpected ASN.1 format [object with tag: \(tag) is not found and/or " +
                    "is not primitive]")
            }
            return data
        }

        fillingInstructionsVersion = try get(tag: 0)
        objectSystemVersion = try get(tag: 1)
        productIdentificationObjectSystemVersion = try get(tag: 2)
        fillingInstructionsEfGdoVersion = try get(tag: 4)
        fillingInstructionsEfAtrVersion = try get(tag: 5)
        fillingInstructionsEfKeyInfoVersion = try? get(tag: 6)
        fillingInstructionsEfEnvironmentSettingsVersion = try? get(tag: 3)
        fillingInstructionsEfLoggingVersion = try? get(tag: 7)
    }

    /// Parse the `objectSystemVersion` parameter to a `CardGeneration` or nil when unknown/unsupported.
    public func generation() -> CardGeneration? {
        CardGeneration.parseCardGeneration(data: objectSystemVersion)
    }
}
