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

#if os(iOS)

import CardReaderProviderApi
import Combine
import CoreNFC
import Foundation
import OSLog

/// Abstraction to the NFCTagReaderSession to update the alertMessage that is being displayed to the user.
/// And to close/invalidate the session
public protocol NFCCardSession {
    /// Update the NFC Dialog message
    func updateAlert(message: String)

    /// End session
    ///
    /// - Parameter error: when set the session will end erroneously
    func invalidateSession(with error: String?)

    /// The underlying Card for the emitted NFCCardSession
    var card: CardType { get }
}

extension NFCTagReaderSession {
    public enum Error: Swift.Error {
        case couldNotInitializeSession
        case unsupportedTag
        case nfcTag(error: CoreNFCError)
    }

    public struct Publisher: Combine.Publisher {
        public typealias Output = NFCCardSession
        public typealias Failure = Error

        private let messages: Messages
        private let pollingOption: PollingOption
        private let queue: DispatchQueue

        init(pollingOption: PollingOption, on queue: DispatchQueue, messages: Messages) {
            self.messages = messages
            self.pollingOption = pollingOption
            self.queue = queue
        }

        public func receive<S: Subscriber>(subscriber: S) where Output == S.Input, Self.Failure == S.Failure {
            subscriber.receive(subscription: ActualSubscription(
                downstream: subscriber,
                pollingOption: pollingOption,
                on: queue,
                messages: messages
            ))
        }
    }

    /// NFCTagReaderSession messages
    public struct Messages {
        /// The message that is being displayed when polling for a NFC Card
        public let discoveryMessage: String
        /// The message when the card is being initialized for downstream usage
        public let connectMessage: String
        /// The message when 'something else' as a card is found, but not a card
        public let noCardMessage: String
        /// The message to display when multiple NFC Cards were detected
        public let multipleCardsMessage: String
        /// The message when the card type is unsupported
        public let unsupportedCardMessage: String
        /// The generic error message
        public let connectionErrorMessage: String

        /// Messages constructor
        ///
        /// - Parameters:
        ///   - discoveryMessage: The message that is being displayed when polling for a NFC Card
        ///   - connectMessage: The message when the card is being initialized for downstream usage
        ///   - noCardMessage: The message when 'something else' as a card is found, but not a card
        ///   - multipleCardsMessage: The message to display when multiple NFC Cards were detected
        ///   - unsupportedCardMessage:  The message when the card type is unsupported
        ///   - connectionErrorMessage: The generic (communication) error message
        public init(discoveryMessage: String, connectMessage: String, noCardMessage: String,
                    multipleCardsMessage: String, unsupportedCardMessage: String, connectionErrorMessage: String) {
            self.discoveryMessage = discoveryMessage
            self.connectMessage = connectMessage
            self.noCardMessage = noCardMessage
            self.multipleCardsMessage = multipleCardsMessage
            self.unsupportedCardMessage = unsupportedCardMessage
            self.connectionErrorMessage = connectionErrorMessage
        }
    }

    /// Publisher for NFCTagReaderSession
    /// The publisher emits found NFCCards downstream on the given queue
    ///
    /// - Parameters:
    ///   - pollingOption: default iso14443
    ///   - queue: default .global(qos: .userInitiated)
    ///   - messages: the NFC alert dialog messages for the various states
    /// - Returns: NFCTagReaderSession.Publisher
    @available(*, deprecated, message: "Use NFCHealthCardSession instead")
    public static func publisher(for pollingOption: PollingOption = .iso14443,
                                 on queue: DispatchQueue = .global(qos: .userInitiated),
                                 messages: Messages) -> Publisher {
        Publisher(pollingOption: pollingOption, on: queue, messages: messages)
    }
}

extension NFCTagReaderSession.Publisher {
    struct PublishedCardSession: NFCCardSession {
        let session: NFCTagReaderSession
        let card: CardType

        func updateAlert(message: String) {
            DispatchQueue.main.async {
                self.session.alertMessage = message
            }
        }

        func invalidateSession(with error: String?) {
            DispatchQueue.main.async {
                if let error = error {
                    session.invalidate(errorMessage: error)
                } else {
                    session.invalidate()
                }
            }
        }
    }

    private final class ActualSubscription<Downstream: Subscriber>: NSObject, Subscription,
        NFCTagReaderSessionDelegate where Downstream.Input == NFCCardSession,
        Downstream.Failure == NFCTagReaderSession.Error {
        private let downstream: Downstream
        private let queue: DispatchQueue
        private let messages: NFCTagReaderSession.Messages
        private var session: NFCTagReaderSession?
        private var card: NFCCard?

        init(downstream: Downstream, pollingOption: NFCTagReaderSession.PollingOption, on queue: DispatchQueue,
             messages: NFCTagReaderSession.Messages) {
            self.downstream = downstream
            self.messages = messages
            self.queue = queue
            super.init()
            if let mNfcReaderSession = NFCTagReaderSession(pollingOption: pollingOption, delegate: self, queue: queue) {
                session = mNfcReaderSession
                mNfcReaderSession.alertMessage = messages.discoveryMessage
                Logger.nfcCardReaderProvider.debug("Starting session: \(mNfcReaderSession)")
                mNfcReaderSession.begin()
            } else {
                Logger.nfcCardReaderProvider
                    .debug("Could not start discovery for NFCCardReader refused to init a NFCTagReaderSession")
                complete(with: .couldNotInitializeSession)
            }
        }

        /// PRAGMA MARK: Combine Subscription

        @Synchronized private var demand: Subscribers.Demand = .none

        func request(_ demand: Subscribers.Demand) {
            queue.async {
                self.demand += demand
                self.fulfillDemand()
            }
        }

        func cancel() {
            demand = .none
            session?.invalidate()
            session = nil
        }

        private func fulfillDemand() {
            // fulfill when demand > 0
            if demand > 0, let card = card, let session = session {
                queue.async {
                    Logger.nfcCardReaderProvider.debug("Fulfilling demand: \(card), session: \(session)")
                    // moreDemand is the downstream's way of letting us know, how many *more* than the initial demand,
                    // it wishes to receive after this fulfillment.
                    let moreDemand = self.downstream.receive(PublishedCardSession(session: session, card: card))
                    // addition before subtraction so we don't inadvertently go below demand threshold
                    self.demand += moreDemand
                    if self.demand > 0 {
                        self.demand -= 1
                    }
                }
            }
        }

        private func complete(with error: Downstream.Failure?) {
            queue.async {
                if let error = error {
                    self.downstream.receive(completion: .failure(error))
                } else {
                    self.downstream.receive(completion: .finished)
                }
            }
        }

        /// PRAGMA MARK: NFCTagReaderSessionDelegate

        func tagReaderSessionDidBecomeActive(_: NFCTagReaderSession) {
            Logger.nfcCardReaderProvider.debug("NFC reader session became active")
        }

        func tagReaderSession(_: NFCTagReaderSession, didInvalidateWithError error: Swift.Error) {
            Logger.nfcCardReaderProvider.debug("NFC reader session was invalidated: \(error)")
            let coreNFCError = error.asCoreNFCError()
            complete(with: .nfcTag(error: coreNFCError))
            demand = .none
        }

        func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
            Logger.nfcCardReaderProvider.debug("tagReaderSession:didDetect - [\(tags)]")
            if tags.count > 1 {
                session.alertMessage = messages.multipleCardsMessage
                DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(500)) {
                    session.restartPolling()
                }
                return
            }

            guard let tag = tags.first else {
                session.alertMessage = messages.noCardMessage
                DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(500)) {
                    session.restartPolling()
                }
                return
            }
            guard case let .iso7816(nfcTag) = tag else {
                session.invalidate(errorMessage: messages.unsupportedCardMessage)
                complete(with: .unsupportedTag)

                return
            }

            session.alertMessage = messages.connectMessage

            // Connect to tag
            session.connect(to: tag) { [weak self] (error: Swift.Error?) in
                guard let self = self else { return }
                if let error = error?.asCoreNFCError() {
                    session.invalidate(errorMessage: self.messages.connectionErrorMessage)
                    self.complete(with: .nfcTag(error: error))
                    return
                }
                self.card = NFCCard(isoTag: nfcTag)
                self.fulfillDemand()
            }
        }
    }
}

#endif

@propertyWrapper
struct Synchronized<T> {
    private let backing: SynchronizedVar<T>

    /// Initialize a Synchronized wrapper
    ///
    /// - Parameter backing: the initial value
    init(wrappedValue backing: T) {
        self.backing = SynchronizedVar(backing)
    }

    /// Get/Set the backed value
    var wrappedValue: T {
        get {
            backing.value
        }
        set {
            backing.set { _ in
                newValue
            }
        }
    }

    /// Projected self
    var projectedValue: Synchronized<T> {
        get {
            self
        }
        mutating set {
            self = newValue
        }
    }
}

class SynchronizedVar<T> {
    private var _value: T
    private let mutex = NSRecursiveLock()

    /// Canonical constructor
    init(_ value: T) {
        _value = value
    }

    /**
        Get/Set the value for this SynchronizedVar in a
        thread-safe (blocking) manner
     */
    var value: T {
        mutex.lock()
        defer {
            mutex.unlock()
        }
        return _value
    }

    /// Set a new value in a transaction to make sure there is no potential 'gap' between get and consecutive set
    ///
    /// - Parameter block: the transaction that gets the oldValue and must return the newValue that will be stored
    ///                    in the backing value.
    func set(transaction block: @escaping (T) -> T) {
        mutex.lock()
        _value = block(_value)
        mutex.unlock()
    }
}
