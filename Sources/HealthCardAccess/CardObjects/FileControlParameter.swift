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
import DataKit
import Foundation

public struct FileControlParameter: CardItemType {
    /**
       Describes the LifeCycle state of an EF/DF
       according to the ISO/IEC 7816-4:2005(E) #5.3.3.2 Life cycle status byte.

       b8|b7|b6|b5|b4|b3|b2|b1|meaning
       --|--|--|--|--|--|--|--|-------
       0|0|0|0|0|0|0|0|No information given
       0|0|0|0|0|0|0|1|Created
       0|0|0|0|0|0|1|1|Initialized
       0|0|0|0|0|1|-|1|Active
       0|0|0|0|0|1|-|0|Deactivated
       0|0|0|0|1|1|-|-|Terminated
       |||not all zero||x|x|x|x|Proprietary
     */
    public enum LifeCycleState: Equatable {
        /// No information given (when all bits are 0)
        case unknown
        /// File is created (when only bit 1 is set)
        case creation
        /// File is initialized (when bit 2 is set and 3 and 4 not
        case initialisation
        /// File is active [normal] (when bit 3 and 1 are set)
        case activated
        /// File is not-active [hidden] (when bit 3 is set and bit 1 not)
        case deactivated
        /// File is permanently `.deactivated` (when bit 4 and 3 are set)
        case terminated
        /// File is proprietary - values from 0x10 - 0xff
        case proprietary

        /// Parse a LifeCycleStatus Byte
        ///
        /// - Parameter byte: the LCS byte
        /// - Returns: the LCS or nil when invalid (E.g. 0x2, 0x8)
        public static func parseLifeCycle(byte: UInt8) -> LifeCycleState? {
            if byte & 0b1111_0000 > 0 {
                return .proprietary
            }
            if byte & 0b1100 == 0b1100 {
                return .terminated
            }
            if byte & 0b101 == 0b0101 {
                return .activated
            }
            if byte & 0b101 == 0b100 {
                return .deactivated
            }
            if byte & 0b11 == 0b11 {
                return .initialisation
            }
            if byte & 0b1 == 0b1 {
                return .creation
            }
            if byte == 0x0 {
                return .unknown
            }
            return nil
        }
    }

    // gemSpec_COS#N013.900 Application specific and constructed content with tagNo 2
    public static let tag: UInt = 0x02

    public enum Tag: UInt {
        // gemSpec_COS#N014.000
        case numberOfOctets = 0x00
        // gemSpec_COS#N014.100
        case fileDescriptor = 0x02
        // gemSpec_COS#N014.200
        case fileIdentifier = 0x03
        // gemSpec_COS#N014.300
        case applicationIdentifier = 0x04
        /// gemSpec_COS#N014.700
        case endOfFilePosition = 0x05
        // gemSpec_COS#N014.400
        case shortFileIdentifier = 0x08
        // gemSpec_COS#N014.500
        case lifeCycleStatus = 0x0A
    }

    public let status: LifeCycleState
    /// Max File size (numberOfOctets gemSpec_COS#N014.000)
    public let size: UInt
    /// File size (positionLogicalEndOfFile gemSpec_COS#N014.700)
    public let readSize: UInt?
    /// Hex String
    public let fileDescriptor: String?
    public let fileIdentifier: FileIdentifier?
    public let applicationIdentifier: ApplicationIdentifier?
    public let shortFileIdentifier: ShortFileIdentifier?

    public init(status: LifeCycleState, size: UInt, fileDescriptor: String?, fid: FileIdentifier?,
                aid: ApplicationIdentifier?, shortFid: ShortFileIdentifier?, readSize: UInt?) {
        self.status = status
        self.size = size
        self.fileDescriptor = fileDescriptor
        fileIdentifier = fid
        applicationIdentifier = aid
        shortFileIdentifier = shortFid
        self.readSize = readSize
    }

    public enum Error: Swift.Error, Equatable {
        case illegalArgument(String)
        case asn1ParseError(asn1: Data, reason: String)
        case invalidCard(String)
    }

    /**
        Parse FCP (File Control Parameter) from ASN.1 formatted Data

        - Parameter data: ASN.1 encoded data

        - Throws: FileControlParameter.Error when ASN.1 parsing fails

        - Returns: FCP
     */
    public static func parse(data: Data) throws -> FileControlParameter {
        guard !data.isEmpty else {
            throw Error.illegalArgument("Non-empty value expected to create FileControlParameter")
        }

        guard let asn1Doc = try? ASN1Decoder.decode(asn1: data), asn1Doc.tag.isApplicationSpecific else {
            throw Error.asn1ParseError(asn1: data, reason: "ASN1Decoder did not return ApplicationSpecific ASN1Object")
        }

        guard asn1Doc.tagNo == FileControlParameter.tag else {
            throw Error.invalidCard("Unexpected tag [0x\(asn1Doc.tag)] " +
                "found, while converting response data to FCP. " +
                "Expected: [0x\(String(FileControlParameter.tag, radix: 16))]")
        }

        guard !(asn1Doc.data.items?.isEmpty ?? true) else {
            throw Error.asn1ParseError(asn1: data, reason: "No elements found in FCP Tag")
        }

        return try extract(from: asn1Doc)
    }

    private static func extract(from asn1: ASN1Object) throws -> FileControlParameter {
        var numberOfOctets: UInt = 0
        var fileDescriptor: String?
        var fileIdentifier: FileIdentifier?
        var applicationIdentifier: ApplicationIdentifier?
        var lifeCycleStatus: LifeCycleState?
        var shortFileIdentifier: ShortFileIdentifier?
        var readSize: UInt?

        try asn1.data.items?.forEach { (object: ASN1Object) in
            guard !object.constructed else {
                return
            }

            switch (object.tagNo, object.data.primitive) {
            case (Tag.numberOfOctets.rawValue, let primitive):
                numberOfOctets = primitive?.unsignedIntValue ?? 0
            case (Tag.fileDescriptor.rawValue, let .some(primitive)):
                fileDescriptor = primitive.hexString()
            case (Tag.fileIdentifier.rawValue, let .some(primitive)):
                fileIdentifier = try FileIdentifier(primitive)
            case (Tag.applicationIdentifier.rawValue, let .some(primitive)):
                applicationIdentifier = try ApplicationIdentifier(primitive)
            case (Tag.shortFileIdentifier.rawValue, let .some(primitive)):
                shortFileIdentifier = try ShortFileIdentifier(asn1: primitive)
            case (Tag.lifeCycleStatus.rawValue, let .some(primitive)):
                lifeCycleStatus = LifeCycleState.parseLifeCycle(byte: primitive[0])
            case (Tag.endOfFilePosition.rawValue, let primitive):
                readSize = primitive?.unsignedIntValue
            default: break
            }
        }

        guard let lcs = lifeCycleStatus else {
            throw Error.invalidCard("FCP could not be created because of missing parameter(s)")
        }
        return FileControlParameter(
            status: lcs,
            size: numberOfOctets,
            fileDescriptor: fileDescriptor,
            fid: fileIdentifier,
            aid: applicationIdentifier,
            shortFid: shortFileIdentifier,
            readSize: readSize
        )
    }
}

extension FileControlParameter: CustomDebugStringConvertible, CustomStringConvertible {
    public var debugDescription: String {
        """
        FCP
            size: \(size)
            readSize: \(String(describing: readSize))
            fileDescriptor: \(fileDescriptor ?? "none")
            status: \(status)
            fileIdentifier: \(fileIdentifier?.description ?? "none")
            applicationIdentifier: \(applicationIdentifier?.description ?? "none")
            shortFileIdentifier: \(shortFileIdentifier?.description ?? "none")
        """
    }

    public var description: String {
        debugDescription
    }
}
