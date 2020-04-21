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

/// Represent the card generation of health card
///
/// | Version   | Version with 2 digits | INT Value for Version | Card generation
/// | < 3.0.3   |  03.00.03             | 30003                 | G1
/// | < 4.0.0   |  04.00.00             | 40000                 | G1P
/// | >= 4.0.0  |  04.00.00             | 40000                 | G2
/// | >= 4.4.0  |  04.04.00             | 40400                 | G2_1
///
public enum CardGeneration {
    //swiftlint:disable identifier_name
    /// Generation G1 (< 3.0.3)
    case g1
    /// Generation G1P (3.0.3 - < 4.0.0)
    case g1P
    /// Generation G2 (4.0.0 - < 4.4.0)
    case g2
    /// Generation G2.1 (4.4.0+)
    case g2_1

    private static let version_3_0_3 = 30003
    private static let version_4_0_0 = 40000
    private static let version_4_4_0 = 40400

    /// Return the CardGeneration for ObjectSystemVersion
    ///
    /// - Parameter version: value like 30003, 40000 (for details see class description)
    /// - Returns: Generation Value or nil when version is unrecognized
    public static func parseCardGeneration(version: Int) -> CardGeneration? {

        switch version {
        case 0..<version_3_0_3: return g1
        case version_3_0_3..<version_4_0_0: return g1P
        case version_4_0_0..<version_4_4_0: return g2
        case version_4_4_0...:return g2_1
        default:
            return nil
        }
    }

    /// Length in bytes [objectSystemVersion]
    static let cardVersionLength = 3

    /// Parse the CardGeneration from the `objectSystemVersion` from the `CardVersion2`
    public static func parseCardGeneration(data: Data) -> CardGeneration? {
        guard data.count == cardVersionLength else {
            return nil
        }
        let hex = data.hexString()
        // Radix 10 is not entirely correct here, but we assume version nrs not to grow beyond 99
        // See also Java implementation: de.gematik.ti.healthcard.control.entities.CardGeneration
        guard let versionInt = Int(hex, radix: 10) else {
            return nil
        }
        return parseCardGeneration(version: versionInt)
    }
}
