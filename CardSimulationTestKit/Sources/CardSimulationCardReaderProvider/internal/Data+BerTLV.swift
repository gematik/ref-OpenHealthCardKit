//
// Copyright (Change Date see Readme), gematik GmbH
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// *******
//
// For additional notes and disclaimer from gematik and in case of changes by gematik find details in the "Readme" file.
//

import ASN1Kit
import Foundation

extension Data {
    /// Decode the data by stripping the Ber TLV prefix header
    /// - Throws: `SimulatorCardReader.SimulatorError`
    /// - Returns: The decoded part of the data when a Ber TLV header was found, otherwise self is returned
    public func berTlvDecoded() throws -> Data {
        do {
            let asn1object = try ASN1Decoder.decode(asn1: self)
            guard let data = asn1object.data.primitive else {
                throw SimulatorCardChannel.SimulatorError.asn1coding("Illegal BER-TLV Data structure")
            }
            return data
        } catch {
            throw SimulatorCardChannel.SimulatorError.asn1coding(error)
        }
    }

    /// Add a Ber TLV header to the Data blob
    /// - Throws: `SimulatorCardReader.SimulatorError`
    /// - Returns: the data with the Ber TLV header in front
    public func berTlvEncoded() throws -> Data {
        try asn1encode(tag: .taggedTag(0)).serialize()
    }
}

extension String: Error {}
