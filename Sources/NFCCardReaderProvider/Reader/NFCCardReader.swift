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
import CoreNFC
import DataKit
import Foundation
import GemCommonsKit
import HealthCardAccess

public class NFCCardReader: NSObject, CardReaderType {

    /// The Use-case message key for the `connect()` method to display to the user
    public static let keyDiscoveryMessage = "USE_CASE_MESSAGE"
    /// The message to display to the user when the secure PACE channel is being setup
    public static let keyConnectMessage = "CONNECT_MESSAGE"
    /// The no card found error message when no card is found by `connect()`
    public static let keyNoCardMessage = "NO_CARD_MESSAGE"
    /// The multiple cards detected error message when more than 1 card is found by `connect()`
    public static let keyMultipleCardMessage = "MULTIPLE_CARD_MESSAGE"
    /// The unsupported card message
    public static let keyUnsupportedCardMessage = "UNSUPPORTED_MESSAGE"
    /// The generic no connection message
    public static let keyConnectionError = "CONNECTION_ERROR_MESSAGE"

    public enum Error: Swift.Error, Equatable {
        case noCardPresent
        case transferException(name: String)
        case sendTimeout

        public var connectionError: CardError {
            return CardError.connectionError(self)
        }

        public var illegalState: CardError {
            return CardError.illegalState(self)
        }
    }

    public init(controllerName: String) {
        self.name = controllerName
    }

    typealias CardEventBlockType = (CardReaderType) -> Void

    private let cardPresenceBlock = SynchronizedVar<CardEventBlockType?>(nil)
    private var detectedTag: NFCISO7816Tag?

    public let name: String
    private(set) var nfcReaderSession: NFCTagReaderSession?

    public var cardPresent: Bool {
        DLog("(detectedTag != nil): \((detectedTag != nil))")
        return (detectedTag != nil)
    }

    public func onCardPresenceChanged(_ block: @escaping (CardReaderType) -> Void) {
        cardPresenceBlock.value = block
    }

    public func connect(_ params: [String: Any]) throws -> CardType? {
        guard let tag = detectedTag,
              tag.isAvailable else {
            throw Error.noCardPresent.illegalState
        }

        return NFCCard(isoTag: tag, reader: self)
    }

    func onCardPresent(tag: NFCISO7816Tag) {
        DLog("card present: \(tag)")
        detectedTag = tag

        if let callback = cardPresenceBlock.value {
            Self.scheduleCardPresenceCallback(callback, cardReader: self)
        }

        DLog("tag.isAvailable onCardPresent: \(tag.isAvailable)")
    }

    func onCardRemoved() {
        DLog("card removed: \(String(describing: detectedTag))")
        detectedTag = nil

        if let callback = cardPresenceBlock.value {
            Self.scheduleCardPresenceCallback(callback, cardReader: self)
        }
    }

    private static func scheduleCardPresenceCallback(_ block: @escaping (CardReaderType) -> Void,
                                                     cardReader: CardReaderType) {
        DispatchQueue.global().async {
            DispatchQueue.main.sync {
                block(cardReader)
            }
        }
    }

    var messages: [String: String] = [:]

    /// (Re-)Start polling for NFC card
    public func startDiscovery(with messages: [String: String]) {
        self.messages = messages
        let message = messages[Self.keyDiscoveryMessage] ?? "Please tap your eGK to your iPhone/iPad"
        if let session = nfcReaderSession, !session.isReady {
            session.restartPolling()
            session.alertMessage = message
        } else {
            if let mNfcReaderSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: self) {
                nfcReaderSession = mNfcReaderSession
                mNfcReaderSession.alertMessage = message
                DLog("Starting session: \(mNfcReaderSession)")
                mNfcReaderSession.begin()
            } else {
                ALog("Could not start discovery for NFCCardReader refused to init a NFCTagReaderSession")
            }
        }
    }

    /// Close session when a session has been started
    /// - Parameter error: the error message or nil when the session has been successful
    public func invalidateSession(error: String? = nil) {
        if let session = nfcReaderSession {
            DLog("Invalidating session: \(session) | Error: [\(error ?? "none")]")
            if let error = error {
                session.invalidate(errorMessage: error)
            } else {
                // End successfully
                session.invalidate()
            }
            nfcReaderSession = nil
        }
    }

    deinit {
        invalidateSession()
    }
}
