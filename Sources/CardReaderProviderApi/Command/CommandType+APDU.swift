// swiftlint:disable:this file_name
//
//  ${GEMATIK_COPYRIGHT_STATEMENT}
//

import Foundation

extension APDU.Command: CommandType {
    /// APDU body data
    public var data: Data? {
        let subData = self.apdu.subdata(in: self.dataOffset..<self.rawNc + self.dataOffset)
        return subData.isEmpty ? nil : subData
    }

    /// APDU class identifier
    public var cla: UInt8 {
        return self.apdu[0] & 0xff
    }

    /// APDU Instruction
    public var ins: UInt8 {
        return self.apdu[1] & 0xff
    }

    // swiftlint:disable identifier_name

    /// APDU P1
    public var p1: UInt8 {
        return self.apdu[2] & 0xff
    }

    /// APDU P2
    public var p2: UInt8 {
        return self.apdu[3] & 0xff
    }

    /// APDU Le - Expected length in response body
    public var ne: Int? {
        return self.rawNe
    }

    /// APDU Lc - Command body length
    public var nc: Int {
        return self.rawNc
    }

    /// APDU raw
    public var bytes: Data {
        return self.apdu
    }
    // swiftlint:enable identifier_name
}
