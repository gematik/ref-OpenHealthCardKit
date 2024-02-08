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

import CardReaderProviderApi
import Combine
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
    /// - Note: This Publisher keeps reading till the received number of bytes is `size`
    ///   or the channel returns 0x6282: endOfFileWarning.
    ///   When the current channel `maxResponseLength` is less than the expected `size`,
    ///   the file is read in chunks and returned as a whole.
    ///
    /// - Throws: Emits `ReadError` on the Publisher in case of failure.
    ///
    /// - Returns: Publisher that reads the current selected file
    @available(*, deprecated, message: "Use structured concurrency version instead")
    public func readSelectedFile(expected size: Int?, failOnEndOfFileWarning: Bool = true, offset: Int = 0)
        -> AnyPublisher<Data, Error> {
        let maxResponseLength = currentCardChannel.maxResponseLength - 2 // allow for 2 status bytes sw1, sw2
        let expectedResponseLength = size ?? 0x10000
        let responseLength = min(maxResponseLength, expectedResponseLength)
        return Just(responseLength)
            .tryMap { responseLength in
                try HealthCardCommand.Read.readFileCommand(ne: responseLength, offset: offset)
            }
            .flatMap { command in
                command.publisher(for: self)
                    .tryMap { response -> (Bool, Data) in
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
                        let continueReading = responseData.count < expectedResponseLength &&
                            response.responseStatus != .endOfFileWarning
                        return (continueReading, responseData)
                    }
                    .flatMap { readAgain, responseData -> AnyPublisher<Data, Error> in
                        if readAgain {
                            // Continue reading
                            return self.readSelectedFile(
                                expected: size != nil ?
                                    (expectedResponseLength - responseData.count) : nil,
                                failOnEndOfFileWarning: failOnEndOfFileWarning,
                                offset: offset + responseData.count
                            )
                            .map {
                                responseData + $0
                            }
                            .eraseToAnyPublisher()
                        } else {
                            // Done
                            return Just(responseData).setFailureType(to: Error.self).eraseToAnyPublisher()
                        }
                    }
            }
            .eraseToAnyPublisher()
    }

    /// Read the current selected DF/EF File
    ///
    /// - Parameters:
    ///     - size: The expected file size. must be greater than 0 or nil.
    ///             Note that failOnEndOfFileWarning must be `false` for this operation to succeed when `size` = nil.
    ///     - failOnEndOfFileWarning: whether the operation must execute 'clean' or till the end-of-file warning.
    ///             [default: true]
    ///
    /// - Note: This Publisher keeps reading till the received number of bytes is `size`
    ///   or the channel returns 0x6282: endOfFileWarning.
    ///   When the current channel `maxResponseLength` is less than the expected `size`,
    ///   the file is read in chunks and returned as a whole.
    ///
    /// - Throws: Emits `ReadError` on the Publisher in case of failure.
    ///
    /// - Returns: `Data` that was read form the currently selected file
    public func readSelectedFile(
        expected size: Int?,
        failOnEndOfFileWarning: Bool = true,
        offset: Int = 0
    ) async throws -> Data {
        let maxResponseLength = currentCardChannel.maxResponseLength - 2 // allow for 2 status bytes sw1, sw2
        let expectedResponseLength = size ?? 0x10000
        let responseLength = min(maxResponseLength, expectedResponseLength)
        let readFileCommand = try HealthCardCommand.Read.readFileCommand(ne: responseLength, offset: offset)
        let readFileResponse = try await readFileCommand.transmit(to: self)
        guard readFileResponse.responseStatus == .success ||
            (!failOnEndOfFileWarning && readFileResponse.responseStatus == .endOfFileWarning)
        else {
            // Fail because we received an end-of-file warning or did not succeed
            throw ReadError.unexpectedResponse(state: readFileResponse.responseStatus)
        }
        guard let responseData = readFileResponse.data,
              !responseData.isEmpty
        else {
            // No data received
            throw ReadError.noData(state: readFileResponse.responseStatus)
        }
        let continueReading = responseData.count < expectedResponseLength &&
            readFileResponse.responseStatus != .endOfFileWarning

        if continueReading {
            // Continue reading
            let continued = try await readSelectedFile(
                expected: size != nil ? (expectedResponseLength - responseData.count) : nil,
                failOnEndOfFileWarning: failOnEndOfFileWarning,
                offset: offset + responseData.count
            )
            return responseData + continued
        } else {
            // Done
            return responseData
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
    /// - Returns: Publisher chain that selects the given file when executed
    @available(*, deprecated, message: "Use structured concurrency version instead")
    public func selectDedicated(file: DedicatedFile, fcp: Bool = false, length: Int = 256)
        -> AnyPublisher<(ResponseStatus, FileControlParameter?), Error> {
        let channel = self
        return HealthCardCommand.Select.selectFile(with: file.aid)
            .publisher(for: channel)
            .tryMap { response -> HealthCardResponseType in
                guard response.responseStatus == .success else {
                    throw SelectError.failedToSelectAid(file.aid, status: response.responseStatus)
                }
                return response
            }
            .flatMap { response -> AnyPublisher<(ResponseStatus, FileControlParameter?), Error> in
                guard let fid = file.fid else {
                    return Just<(ResponseStatus, FileControlParameter?)>((response.responseStatus, nil))
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                let publisher: AnyPublisher<HealthCardResponseType, Error>
                do {
                    let command = fcp ?
                        try HealthCardCommand.Select.selectEfRequestingFcp(with: fid,
                                                                           expectedLength: length)
                        : HealthCardCommand.Select.selectEf(with: fid)
                    publisher = command.publisher(for: channel).eraseToAnyPublisher()
                } catch {
                    publisher = Fail(error: error).eraseToAnyPublisher()
                }
                return publisher.tryMap { fidResponse in
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
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    /// Select a dedicated file with or without requesting the FileIdentifier's File Control Parameter.
    ///
    /// - Parameters:
    ///     - file: file to select
    ///     - fcp: whether to request the File Control Parameter
    ///     - length: expected fcp length - only applicable when fcp = true
    ///
    /// - Throws: `SelectError` (or `ReadError` is case no FCP data could be read and fcp = true)
    ///
    /// - Returns: `(ResponseStatus, FileControlParameter?)` after trying to select the given file
    public func selectDedicated(
        file: DedicatedFile,
        fcp: Bool = false,
        length: Int = 256
    ) async throws -> (ResponseStatus, FileControlParameter?) {
        let selectFileCommand = HealthCardCommand.Select.selectFile(with: file.aid)
        let selectFileResponse = try await selectFileCommand.transmit(to: self)

        guard selectFileResponse.responseStatus == .success
        else {
            throw SelectError.failedToSelectAid(file.aid, status: selectFileResponse.responseStatus)
        }
        guard let fid = file.fid
        else {
            return (selectFileResponse.responseStatus, nil)
        }

        let selectEfCommand = fcp ?
            try HealthCardCommand.Select.selectEfRequestingFcp(with: fid, expectedLength: length) :
            HealthCardCommand.Select.selectEf(with: fid)
        let selectEfResponse = try await selectEfCommand.transmit(to: self)

        guard selectEfResponse.responseStatus == .success
        else {
            throw SelectError.failedToSelectFid(fid, status: selectEfResponse.responseStatus)
        }
        if fcp {
            guard let fcpData = selectEfResponse.data else {
                throw ReadError.noData(state: selectEfResponse.responseStatus)
            }
            let fcp = try FileControlParameter.parse(data: fcpData)
            return (selectEfResponse.responseStatus, fcp)
        } else {
            return (selectEfResponse.responseStatus, nil)
        }
    }
}
