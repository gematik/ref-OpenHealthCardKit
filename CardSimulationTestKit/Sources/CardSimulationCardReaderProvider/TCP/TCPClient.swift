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

import Foundation
import NIO
import NIOConcurrencyHelpers

//  SwiftNIO-based TCPClient implementation providing the same API as SwiftSocket

// swiftlint:disable missing_docs
public typealias Byte = UInt8

public enum SocketError: Error {
    case queryFailed
    case connectionClosed
    case connectionTimeout
    case unknownError
}

public enum Result {
    case success
    case failure(Error)
}

// MARK: - TCPClient

public class TCPClient {
    private let group: MultiThreadedEventLoopGroup
    private var channel: Channel?
    private let host: String
    private let port: Int
    private let lock = NIOLock()
    private var receiveBuffer: [UInt8] = []
    private var ownsGroup = true

    /// Returns true when the socket is connected
    public var isConnected: Bool {
        channel != nil
    }

    public init(host: String, port: Int) {
        self.host = host
        self.port = port
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        ownsGroup = true
    }

    /// Internal initializer for server-accepted connections
    internal init(channel: Channel, group: MultiThreadedEventLoopGroup) {
        self.channel = channel
        host = channel.remoteAddress?.ipAddress ?? ""
        port = channel.remoteAddress?.port ?? 0
        self.group = group
        ownsGroup = false
    }

    deinit {
        try? close()
        if ownsGroup {
            try? group.syncShutdownGracefully()
        }
    }

    /// Connect to the server with timeout
    public func connect(timeout: Int) -> Result {
        let bootstrap = ClientBootstrap(group: group)
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .connectTimeout(TimeAmount.seconds(Int64(timeout)))
            .channelInitializer { [weak self] channel in
                channel.pipeline.addHandler(TCPClientDataHandler(client: self))
            }

        do {
            let channel = try bootstrap.connect(host: host, port: port).wait()
            self.channel = channel
            return .success
        } catch {
            if case ChannelError.connectTimeout = error {
                return .failure(SocketError.connectionTimeout)
            }
            return .failure(SocketError.unknownError)
        }
    }

    /// Close the connection
    public func close() throws {
        guard let channel = channel else { return }
        try channel.close().wait()
        self.channel = nil
    }

    /// Send data to server
    public func send(data: Data) -> Result {
        guard let channel = channel else {
            return .failure(SocketError.connectionClosed)
        }

        var buffer = channel.allocator.buffer(capacity: data.count)
        buffer.writeBytes(data)

        do {
            try channel.writeAndFlush(buffer).wait()
            return .success
        } catch {
            return .failure(SocketError.unknownError)
        }
    }

    /// Send byte array to server
    public func send(data: [Byte]) -> Result {
        send(data: Data(data))
    }

    /// Read up to expectlen bytes with optional timeout
    // swiftlint:disable:next discouraged_optional_collection
    public func read(_ expectlen: Int, timeout: Int = -1) -> [Byte]? {
        guard channel != nil else { return nil }

        let deadline: Date?
        if timeout > 0 {
            deadline = Date(timeIntervalSinceNow: TimeInterval(timeout))
        } else if timeout == 0 {
            deadline = Date() // immediate
        } else {
            deadline = nil // no timeout, but don't block forever - use a reasonable default
        }

        // Wait for data to arrive
        while true {
            lock.lock()
            if !receiveBuffer.isEmpty {
                let count = min(expectlen, receiveBuffer.count)
                let result = Array(receiveBuffer.prefix(count))
                receiveBuffer.removeFirst(count)
                lock.unlock()
                return result
            }
            lock.unlock()

            if let deadline = deadline, Date() >= deadline {
                return nil
            }

            // Small sleep to prevent busy waiting
            Thread.sleep(forTimeInterval: 0.001)
        }
    }

    /// Get bytes available for reading
    public func bytesAvailable() -> Int32? {
        guard channel != nil else { return nil }
        lock.lock()
        let count = Int32(receiveBuffer.count)
        lock.unlock()
        return count
    }

    // MARK: - Internal: called by handler

    func didReceiveData(_ data: [UInt8]) {
        lock.lock()
        receiveBuffer.append(contentsOf: data)
        lock.unlock()
    }

    func didDisconnect() {
        channel = nil
    }
}

// MARK: - Channel Handler

private final class TCPClientDataHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer

    private weak var client: TCPClient?

    init(client: TCPClient?) {
        self.client = client
    }

    func channelRead(context _: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data)
        if let bytes = buffer.readBytes(length: buffer.readableBytes) {
            client?.didReceiveData(bytes)
        }
    }

    func channelInactive(context: ChannelHandlerContext) {
        client?.didDisconnect()
        context.fireChannelInactive()
    }

    func errorCaught(context: ChannelHandlerContext, error _: Error) {
        client?.didDisconnect()
        context.close(promise: nil)
    }
}

// MARK: - TCPServer (for tests)

class TCPServer {
    private let group: MultiThreadedEventLoopGroup
    private var serverChannel: Channel?
    private let address: String
    var port: Int32
    private var acceptedClients: [TCPClient] = []
    private let acceptLock = NIOLock()
    private var acceptHandler: TCPServerAcceptHandler?

    init(address: String, port: Int32) {
        self.address = address
        self.port = port
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    }

    deinit {
        close()
        try? group.syncShutdownGracefully()
    }

    func listen() -> Result {
        let handler = TCPServerAcceptHandler(server: self)
        acceptHandler = handler

        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { [weak self] channel in
                guard let self = self else {
                    return channel.eventLoop.makeSucceededFuture(())
                }
                // Create a TCPClient wrapper for this accepted connection
                let client = TCPClient(channel: channel, group: self.group)
                self.acceptLock.lock()
                self.acceptedClients.append(client)
                self.acceptLock.unlock()
                return channel.pipeline.addHandler(TCPClientDataHandler(client: client))
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)

        do {
            let channel = try bootstrap.bind(host: address, port: Int(port)).wait()
            serverChannel = channel

            // If port was 0, get the actual assigned port
            if port == 0, let localAddress = channel.localAddress {
                port = Int32(localAddress.port ?? 0)
            }

            return .success
        } catch {
            return .failure(SocketError.unknownError)
        }
    }

    /// Accept an incoming connection (blocking with optional timeout)
    func accept(timeout: Int32 = 0) -> TCPClient? {
        let deadline: Date?
        if timeout > 0 {
            deadline = Date(timeIntervalSinceNow: TimeInterval(timeout))
        } else {
            deadline = Date(timeIntervalSinceNow: 5.0) // Default 5 second timeout
        }

        while Date() < (deadline ?? Date.distantFuture) {
            acceptLock.lock()
            if !acceptedClients.isEmpty {
                let client = acceptedClients.removeFirst()
                acceptLock.unlock()
                return client
            }
            acceptLock.unlock()
            Thread.sleep(forTimeInterval: 0.001)
        }
        return nil
    }

    func close() {
        try? serverChannel?.close().wait()
        serverChannel = nil
        acceptLock.lock()
        acceptedClients.removeAll()
        acceptLock.unlock()
    }
}

private final class TCPServerAcceptHandler: ChannelInboundHandler {
    typealias InboundIn = Channel

    private weak var server: TCPServer?

    init(server: TCPServer) {
        self.server = server
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        // Child channel was accepted - handled in childChannelInitializer
        context.fireChannelRead(data)
    }
}

// swiftlint:enable missing_docs
