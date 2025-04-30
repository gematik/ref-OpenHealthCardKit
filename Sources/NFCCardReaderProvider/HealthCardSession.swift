//
//  Copyright (c) 2024 gematik GmbH
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
import HealthCardAccess
import HealthCardControl
import OSLog

public class HealthCardSession: NSObject, NFCTagReaderSessionDelegate {
    private let messages: Messages
    private let can: String
    private var secureHealthCard: HealthCardType?
    private var session: NFCTagReaderSession?

    public init(messages: Messages, can: String) {
        self.messages = messages
        self.can = can
        super.init()
    }

    /// - Parameters:
    ///   - pollingOption: default iso14443
    ///   - queue: default .global(qos: .userInitiated)
    ///   - messages: the NFC alert dialog messages for the various states
    ///   - can: the card access number necessary to establish the secure channel
    ///   - operation: closure with a `NFCHealthCardSessionHandle` to send/receive commands/responses
    ///         to/from the NFC HealthCard and to update the user's interface message
    public func beginNFCSession(
        pollingOption: NFCTagReaderSession.PollingOption = .iso14443,
        on queue: DispatchQueue = .global(qos: .userInitiated)
    ) async throws {
        guard let mNFCReaderSession = NFCTagReaderSession(
            pollingOption: pollingOption,
            delegate: self,
            queue: queue
        )
        else {
            Logger.nfcCardReaderProvider
                .debug("Could not start discovery for NFCCardReader: refused to init a NFCTagReaderSession")
            throw NFCHealthCardSessionError.couldNotInitializeSession
        }

        session = mNFCReaderSession
        mNFCReaderSession.alertMessage = messages.discoveryMessage
        Logger.nfcCardReaderProvider.debug("Starting session: \(String(describing: session))")
        mNFCReaderSession.begin()
    }

    public func sendAPDU(_ apdu: Data) async throws -> ResponseType {
        guard let secureHealthCard = secureHealthCard else {
            throw NFCHealthCardSessionError.couldNotInitializeSession
        }

        let command = try APDU.Command(apduData: apdu)
        let response = try await secureHealthCard.currentCardChannel.transmitAsync(
            command: command,
            writeTimeout: 0,
            readTimeout: 0
        )

        return response
    }

    deinit {
        Logger.nfcCardReaderProvider.debug("Deinit MyNFCSession")
        session?.invalidate()
    }

    /// Invalidates the current NFC session. Optionally, an error message can be provided
    ///  to end the session with a specific error.
    /// - Parameter error: An optional error message. If provided, the session ends with this error message;
    ///  otherwise, it ends normally.
    public func invalidateSession(with error: String?) {
        if let error = error {
            session?.invalidate(errorMessage: error)
        } else {
            session?.invalidate()
        }
    }

    // MARK: - NFCTagReaderSessionDelegate

    public func tagReaderSessionDidBecomeActive(_: NFCTagReaderSession) {
        Logger.nfcCardReaderProvider.debug("NFC reader session became active")
    }

    public func tagReaderSession(_: NFCTagReaderSession, didInvalidateWithError error: Swift.Error) {
        Logger.nfcCardReaderProvider.debug("NFC reader session was invalidated: \(error)")
        let coreNFCError = error.asCoreNFCError()
        session?.alertMessage = NFCHealthCardSessionError.coreNFC(coreNFCError).localizedDescription
    }

    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
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
        guard case let .iso7816(iso7816NfcTag) = tag else {
            session.invalidate(errorMessage: messages.unsupportedCardMessage)
            return
        }

        session.alertMessage = messages.connectMessage

        Task {
            do {
                try await session.connect(to: tag)
            } catch {
                return
            }

            session.alertMessage = messages.secureChannelMessage
            let card = NFCCard(isoTag: iso7816NfcTag)

            do {
                secureHealthCard = try await card.openSecureSessionAsync(can: can)
            } catch let error as CoreNFCError {
                session.invalidate(errorMessage: error.localizedDescription)
                return
            } catch HealthCardControl.KeyAgreement.Error.macPcdVerificationFailedOnCard {
                session.invalidate(errorMessage: NFCHealthCardSessionError.wrongCAN.localizedDescription)
                return
            } catch {
                session
                    .invalidate(errorMessage: NFCHealthCardSessionError.establishingSecureChannel(error)
                        .localizedDescription)
                return
            }
        }
    }
}

extension HealthCardSession {
    /// NFCTagReaderSession messages
    public struct Messages {
        /// The message that is being displayed when polling for a NFC Card
        public let discoveryMessage: String
        /// The message when the card is being initialized for downstream usage
        public let connectMessage: String
        /// The message during establishing a secure card channel after the connect
        public let secureChannelMessage: String
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
        ///   - secureChannelMessage: The message during establishing a secure card channel after the connect
        ///   - noCardMessage: The message when 'something else' as a card is found, but not a card
        ///   - multipleCardsMessage: The message to display when multiple NFC Cards were detected
        ///   - unsupportedCardMessage:  The message when the card type is unsupported
        ///   - connectionErrorMessage: The generic (communication) error message
        public init(
            discoveryMessage: String,
            connectMessage: String,
            secureChannelMessage: String,
            noCardMessage: String,
            multipleCardsMessage: String,
            unsupportedCardMessage: String,
            connectionErrorMessage: String
        ) {
            self.discoveryMessage = discoveryMessage
            self.connectMessage = connectMessage
            self.secureChannelMessage = secureChannelMessage
            self.noCardMessage = noCardMessage
            self.multipleCardsMessage = multipleCardsMessage
            self.unsupportedCardMessage = unsupportedCardMessage
            self.connectionErrorMessage = connectionErrorMessage
        }
    }
}

#endif
