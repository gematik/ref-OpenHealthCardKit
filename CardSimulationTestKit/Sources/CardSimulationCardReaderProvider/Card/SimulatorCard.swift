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
import Foundation
import OSLog
import SwiftSocket

public class SimulatorCard: CardType {
    public private(set) var atr: ATR
    public private(set) var `protocol`: CardProtocol
    let host: String
    let port: Int32
    let connectTimeout: Int
    var basicChannel: SimulatorCardChannel? {
        didSet {
            try? oldValue?.closePublisher()
        }
    }

    public var maxMessageLength: Int = 4096
    public var maxResponseLength: Int = 4096

    required init(host: String, port: Int32, channel protocol: CardProtocol = .t1, timeout: Int = 10) {
        self.protocol = `protocol`
        atr = Data()
        self.host = host
        self.port = port
        connectTimeout = timeout
    }

    public func openBasicChannel() throws -> CardChannelType {
        let client = TCPClient(address: host, port: port)
        switch client.connect(timeout: connectTimeout) {
        case .success:
            basicChannel = SimulatorCardChannel(
                card: self,
                client: client,
                messageLength: maxMessageLength,
                responseLength: maxResponseLength
            )
            return basicChannel! // swiftlint:disable:this force_unwrapping
        case let .failure(error):
            throw CardError.connectionError(error)
        }
    }

    public func openLogicChannel() throws -> CardChannelType {
        throw CardError.connectionError(nil)
    }

    public func openLogicChannelAsync() async throws -> CardChannelType {
        throw CardError.connectionError(nil)
    }

    public func disconnect(reset _: Bool) throws {
        do {
            try basicChannel?.closePublisher()
        } catch {
            Logger.cardSimulationCardReaderProvider.fault("Error while closing basicChannel: [\(error)]")
        }
    }

    deinit {
        do {
            try disconnect(reset: false)
        } catch {
            Logger.cardSimulationCardReaderProvider.fault("Error while deinit: [\(error)]")
        }
    }

    public var description: String {
        "SimulatorCard: [\(host):\(port)]"
    }
}
