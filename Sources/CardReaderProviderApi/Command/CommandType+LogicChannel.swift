//
//  ${GEMATIK_COPYRIGHT_STATEMENT}
//

import Foundation

/// Error when an invalid channel number is chosen
public struct InvalidCommandChannel: Error {
    /// The invalid channel number
    public let channelNo: UInt8
}

extension CommandType {
    /// Convert a Command to be send on a given channel No
    /// - Parameter channelNo: The channel number. Must be < 20.
    /// - Throws: `CardError` or `APDU.Error`
    /// - Returns: Command for channel
    public func toLogicalChannel(channelNo: UInt8) throws -> CommandType {
        var claByte = cla
        if channelNo < 4 {
            claByte &= 0xfc
            claByte |= channelNo
        } else if channelNo < 20 {
            claByte |= 0x40
            claByte |= channelNo - 4
        } else {
            throw CardError.illegalState(InvalidCommandChannel(channelNo: channelNo))
        }
        return try APDU.Command(cla: claByte, ins: ins, p1: p1, p2: p2, data: data, ne: ne)
    }
}
