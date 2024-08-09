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

/// `NFCHealthCardSession` facilitates communication between iOS applications and NFC-enabled health cards.
/// It leverages Core NFC to establish a session with a health card and perform operations on it,
/// such as reading data or executing commands,
/// in a secure manner through a previously established secure channel (PACE).
///
/// Initialization
///
/// To create an instance of NFCHealthCardSession, the following parameters are required:
///
/// - pollingOption: Specifies the NFC polling option to use.
///  The default is .iso14443, which is suitable for most health cards.
/// - queue: The dispatch queue on which the NFC session callbacks are executed.
///  By default, it uses .global(qos: .userInitiated).
/// - messages: A struct of type Messages containing various user-facing messages displayed during NFC operations.
/// - can: The Card Access Number (CAN) required to establish a secure channel with the health card.
/// - operation: A closure that takes a `NFCHealthCardSessionHandle` as its argument
///  and allows for asynchronous execution of NFC operations.
///
/// `NFCHealthCardSessionHandle` provides an abstraction to the `NFCTagReaderSession`
/// allowing the updating of the user interface message and the invalidation of the session.
/// It also gives access to the `card`, representing the health card with which a secure channel has been established.
///
/// ```swift
/// let nfcSession = NFCHealthCardSession(
///     messages: Messages(
///        discoveryMessage: "Hold your iPhone near the health card",
///        connectMessage: "Initializing...",
///        secureChannelMessage: "Establishing secure connection...",
///        noCardMessage: "No card detected. Please try again.",
///        multipleCardsMessage: "Multiple cards detected. Please present only one card.",
///        unsupportedCardMessage: "Unsupported card. Please use a valid health card.",
///        connectionErrorMessage: "An error occurred during connection. Please try again."
///     ),
///     can: "123456",
///     operation: { sessionHandle in
///         // Perform operations with sessionHandle
///         // A secure channel (PACE) is established initially before executing the handle's operations
///         // Return the result of the operation
///         sessionHandle.updateAlert(message: NSLocalizedString("nfc_txt_msg_reset_withNewPin", comment: ""))
///         let changeReferenceDataResponse = try await sessionHandle.card.changeReferenceDataSetNewPin(
///             old: format2OldPin,
///             new: format2NewPin,
///             type: EgkFileSystem.Pin.mrpinHome,
///             dfSpecific: false
///         )
///         if case ChangeReferenceDataResponse.success = changeReferenceDataResponse {
///             sessionHandle.updateAlert(message: NSLocalizedString("nfc_txt_msg_reset_success", comment: ""))
///             return changeReferenceDataResponse
///         } else {
///             // handle this
///     }
/// )
/// ```
/// Methods
///
/// - executeOperation(): Asynchronously executes the operation provided during initialization.
/// This method establishes a secure channel (PACE) with the health card before executing the operation.
/// It returns the result of the operation or throws an error if the session could not be initialized
///  or the operation fails. This method should be called only once. The thrown error type is NFCHealthSessionError.
///
/// ```swift
/// let signedData: Data
/// do {
///     signedData = try await nfcHealthCardSession.executeOperation()
///
///     Task { @MainActor in self.pState = .value(signedData) }
/// } catch NFCHealthCardSessionError.coreNFC(.userCanceled) {
///     // error type is always `NFCHealthCardSessionError`
///     // here we especially handle when the user canceled the session
///     Task { @MainActor in self.pState = .idle } // Do some view-property update
///     // Calling .invalidateSession() is not strictly necessary
///     //  since nfcHealthCardSession does it while it's de-initializing.
///     nfcHealthCardSession.invalidateSession(with: nil)
///     return
/// } catch {
///     Task { @MainActor in self.pState = .error(error) }
///     nfcHealthCardSession.invalidateSession(with: error.localizedDescription)
///     return
/// }
/// ```
///
/// - invalidateSession(with error: String?): Invalidates the current NFC session.
///  If an error message is provided, the session ends with that error message; otherwise, it ends normally.

public class NFCHealthCardSession<Output>: NSObject, NFCTagReaderSessionDelegate {
    private typealias OperationCheckedContinuation = CheckedContinuation<Output, Error>
    private var operationContinuation: OperationCheckedContinuation?

    private let messages: Messages
    private let can: String

    private var session: NFCTagReaderSession?

    var operation: (NFCHealthCardSessionHandle) async throws -> Output

    /// Session object that has a handle to a NFC HealthCard to execute further commands on.
    /// A secure channel (PACE) is established initially before executing the handle's operations.
    ///
    /// The initializer only returns nil if `NFCTagReaderSession` could not be initialized.
    ///
    /// - Parameters:
    ///   - pollingOption: default iso14443
    ///   - queue: default .global(qos: .userInitiated)
    ///   - messages: the NFC alert dialog messages for the various states
    ///   - can: the card access number necessary to establish the secure channel
    ///   - operation: closure with a `NFCHealthCardSessionHandle` to send/receive commands/responses
    ///         to/from the NFC HealthCard and to update the user's interface message
    public init?(
        pollingOption: NFCTagReaderSession.PollingOption = .iso14443,
        on queue: DispatchQueue = .global(qos: .userInitiated),
        messages: Messages,
        can: String,
        operation: @escaping ((NFCHealthCardSessionHandle) async throws -> Output)
    ) {
        self.messages = messages
        self.can = can
        self.operation = operation
        super.init()

        guard let mNFCReaderSession = NFCTagReaderSession(
            pollingOption: pollingOption,
            delegate: self,
            queue: queue
        )
        else {
            Logger.nfcCardReaderProvider
                .debug("Could not start discovery for NFCCardReader: refused to init a NFCTagReaderSession")
            return nil
        }

        session = mNFCReaderSession
    }

    /// Executes the operation on the NFC HealthCard.
    /// A secure channel (PACE) is established before executing the operation.
    /// It returns the result of the operation or throws an error if the session could not be initialized
    ///  or the operation fails.
    /// - Returns: The result of the operation.
    /// - Throws: `NFCHealthCardSessionError`
    ///
    /// - Note: NFCHealthCardSessionError members of special interest are:
    /// NFCHealthCardSessionError.coreNFC(.userCanceled) and NFCHealthCardSessionError.wrongCAN
    public func executeOperation() async throws -> Output {
        guard let session = self.session
        else {
            throw NFCHealthCardSessionError.couldNotInitializeSession
        }
        session.alertMessage = messages.discoveryMessage
        Logger.nfcCardReaderProvider.debug("Starting session: \(String(describing: self.session))")
        session.begin()

        let outcome = try await withCheckedThrowingContinuation { continuation in
            self.operationContinuation = continuation
        }
        return outcome
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
        operationContinuation?.resume(throwing: NFCHealthCardSessionError.coreNFC(coreNFCError))
        operationContinuation = nil
    }

    // swiftlint:disable:next function_body_length
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
            operationContinuation?.resume(throwing: NFCHealthCardSessionError.unsupportedTag)
            operationContinuation = nil
            return
        }

        session.alertMessage = messages.connectMessage

        Task {
            do {
                try await session.connect(to: tag)
            } catch {
                operationContinuation?.resume(throwing: NFCHealthCardSessionError.coreNFC(error.asCoreNFCError()))
                operationContinuation = nil
                return
            }

            session.alertMessage = messages.secureChannelMessage
            let card = NFCCard(isoTag: iso7816NfcTag)

            let secureHealthCard: HealthCardType
            do {
                secureHealthCard = try await card.openSecureSessionAsync(can: can)
            } catch let error as CoreNFCError {
                operationContinuation?.resume(throwing: NFCHealthCardSessionError.coreNFC(error))
                operationContinuation = nil
                return
            } catch HealthCardControl.KeyAgreement.Error.macPcdVerificationFailedOnCard {
                operationContinuation?.resume(throwing: NFCHealthCardSessionError.wrongCAN)
                operationContinuation = nil
                return
            } catch {
                operationContinuation?.resume(throwing: NFCHealthCardSessionError.establishingSecureChannel(error))
                operationContinuation = nil
                return
            }

            let myNFCCardSession = DefaultNFCHealthCardSessionHandle(
                card: secureHealthCard,
                session: session
            )

            do {
                let outcome = try await operation(myNFCCardSession)
                operationContinuation?.resume(returning: outcome)
                operationContinuation = nil
            } catch let error as CoreNFCError {
                operationContinuation?.resume(throwing: NFCHealthCardSessionError.coreNFC(error))
                operationContinuation = nil
                return
            } catch {
                operationContinuation?.resume(throwing: NFCHealthCardSessionError.operation(error))
                operationContinuation = nil
                return
            }
        }
    }
}

/// The (only) error type that is thrown by `.executeOperation().
public enum NFCHealthCardSessionError: Swift.Error {
    /// Indicates that the NFC session could not be initialized.
    case couldNotInitializeSession

    /// Represents an error when the detected tag is not supported, e.g. that not a Health Card.
    case unsupportedTag

    /// Encapsulates errors originating from the CoreNFC framework. This includes, but is not limited to,
    /// communication errors, user cancellation, or configuration issues.
    /// `CoreNFCError` is a bridge from `NFCReaderError`.
    case coreNFC(CoreNFCError)

    /// Signifies that the provided CAN (Card Access Number) is incorrect or failed verification, preventing
    /// establishment of a secure channel. It's a common sub case of the `establishingSecureChannel` error.
    case wrongCAN

    /// Occurs when establishing a secure channel with the health card fails. This includes errors during key agreement,
    /// authentication, or other security protocol failures.
    case establishingSecureChannel(Swift.Error)

    /// Generic error for failures during operation execution. This can include APDU de-/serialization errors, and
    /// errors thrown by the operation's instructions itself.
    case operation(Swift.Error)
}

/// Abstraction to the NFCTagReaderSession to update the alertMessage that is being displayed to the user.
/// And to close/invalidate the session
public protocol NFCHealthCardSessionHandle {
    /// Update the NFC Dialog message
    func updateAlert(message: String)

    /// End session
    ///
    /// - Parameter error: when set the session will end erroneously
    func invalidateSession(with error: String?)

    /// The underlying Card for the emitted NFCCardSession
    ///  The secure card channel has already been established initially
    var card: HealthCardType { get }
}

private struct DefaultNFCHealthCardSessionHandle: NFCHealthCardSessionHandle {
    let card: HealthCardType
    let session: NFCTagReaderSession

    func updateAlert(message: String) {
        Task { @MainActor in self.session.alertMessage = message }
    }

    func invalidateSession(with error: String?) {
        Task { @MainActor in
            if let error = error {
                session.invalidate(errorMessage: error)
            } else {
                session.invalidate()
            }
        }
    }
}

extension NFCHealthCardSession {
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
