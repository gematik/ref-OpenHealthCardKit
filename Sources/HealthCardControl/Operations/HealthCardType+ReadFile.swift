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

import CardReaderProviderApi
import Foundation
import HealthCardAccess

/// Domain error cases for Reading files from a `HealthCardType` e.g. `CardChannelType`
public enum ReadError: Swift.Error, Equatable {
    /// The response status did not match the expected response status
    case unexpectedResponse(state: ResponseStatus)
    /// No data has been returned
    case noData(state: ResponseStatus)
    case fcpMissingReadSize(state: ResponseStatus)
}

public enum SelectError: Swift.Error, Equatable {
    case failedToSelectAid(_: ApplicationIdentifier, status: ResponseStatus?)
    case failedToSelectFid(_: FileIdentifier, status: ResponseStatus?)
}

extension HealthCardType {
    /// Read the current selected DF/EF File
    ///
    /// - Parameters:
    ///     - size: The expected file size. must be greater than 0 or nil.
    ///             Note that failOnEndOfFileWarning must be `false` for this operation to succeed when `size` = nil.
    ///     - failOnEndOfFileWarning: whether the operation must execute 'clean' or till the end-of-file warning.
    ///             [default: true]
    ///
    /// - Note: This executable keeps reading till the received number of bytes is `size`
    ///         or the channel returns 0x6282: endOfFileWarning.
    ///         When the current channel `maxResponseLength` is less than the expected `size`, the file is read in
    ///         chunks and returned as a whole.
    ///
    /// - Throws: Emits `ReadError` on the Executable in case of failure.
    ///
    /// - Returns: Executable that reads the current selected file
    public func readSelectedFile(expected size: Int?, failOnEndOfFileWarning: Bool = true, offset: Int = 0)
                    -> Executable<Data> {
        let maxResponseLength = self.currentCardChannel.maxResponseLength - 2 // allow for 2 status bytes sw1, sw2
        let expectedResponseLength = size ?? 0x10000
        let responseLength = min(maxResponseLength, expectedResponseLength)
        return Executable<Data>
                .evaluate {
                    try HealthCardCommand.Read.readFileCommand(ne: responseLength, offset: offset)
                }
                .flatMap { command in
                    command.execute(on: self)
                }
                .flatMap { response in
                    guard response.responseStatus == .success ||
                                  (!failOnEndOfFileWarning &&
                                          response.responseStatus == .endOfFileWarning) else {
                        // Fail because we received an end-of-file warning or did not succeed
                        throw ReadError.unexpectedResponse(state: response.responseStatus)
                    }
                    guard let responseData = response.data, !responseData.isEmpty else {
                        // No data received
                        throw ReadError.noData(state: response.responseStatus)
                    }
                    guard responseData.count < expectedResponseLength &&
                                  response.responseStatus != .endOfFileWarning else {
                        // Done
                        return Executable<Data>.unit(responseData)
                    }
                    // Continue reading
                    return self.readSelectedFile(
                                    expected: size != nil ? (expectedResponseLength - responseData.count) : nil,
                                    failOnEndOfFileWarning: failOnEndOfFileWarning,
                                    offset: offset + responseData.count
                            )
                            .map {
                                responseData + $0
                            }
                }
    }

    /// Select a dedicated file with or without requesting the FileIdentifier's File Control Parameter.
    ///
    /// - Parameters:
    ///     - file: file to select
    ///     - fcp: whether to request the File Control Parameter
    ///     - length: expected fcp length - only applicable when fcp = true
    ///
    /// - Throws: emits `SelectError` (or `ReadError` is case no FCP data could be read and fcp = true)
    ///
    /// - Returns: Executable chain that selects the given file when executed
    public func selectDedicated(file: DedicatedFile, fcp: Bool = false, length: Int = 256)
                    -> Executable<(ResponseStatus, FileControlParameter?)> {
        return Executable<(ResponseStatus, FileControlParameter?)>
                .unit(HealthCardCommand.Select.selectFile(with: file.aid))
                .flatMap { command in
                    command.execute(on: self)
                }
                .flatMap { response in
                    guard response.responseStatus == .success else {
                        throw SelectError.failedToSelectAid(file.aid, status: response.responseStatus)
                    }
                    guard let fid = file.fid else {
                        return Executable<(ResponseStatus, FileControlParameter?)>.unit((response.responseStatus, nil))
                    }
                    let command = fcp ?
                            try HealthCardCommand.Select.selectEfRequestingFcp(with: fid, expectedLength: length)
                            : HealthCardCommand.Select.selectEf(with: fid)
                    return command.execute(on: self).map { fidResponse in
                        guard fidResponse.responseStatus == .success else {
                            throw SelectError.failedToSelectFid(fid, status: fidResponse.responseStatus)
                        }
                        if fcp {
                            guard let fcpData = fidResponse.data else {
                                throw ReadError.noData(state: fidResponse.responseStatus)
                            }
                            let fcp = try FileControlParameter.parse(data: fcpData)
                            return (fidResponse.responseStatus, fcp)
                        } else {
                            return (fidResponse.responseStatus, nil)
                        }
                    }
                }
    }
}
