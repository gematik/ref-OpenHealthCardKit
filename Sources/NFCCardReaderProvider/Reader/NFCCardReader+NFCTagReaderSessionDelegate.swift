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

import CoreNFC
import Foundation
import GemCommonsKit

extension NFCCardReader: NFCTagReaderSessionDelegate {

    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        DLog("NFC reader session became active")
    }

    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Swift.Error) {
        DLog("NFC reader session was invalidated: \(error)")
        self.invalidateSession()
        onCardRemoved()
    }

    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        DLog("tagReaderSession:didDetect - \(tags[0])")
        if tags.count > 1 {
            let message = messages[Self.keyNoCardMessage] ?? "More than 1 cards were found. Please present only 1 card."
            session.alertMessage = message
            return
        }

        guard let tag = tags.first else {
            let message = messages[Self.keyNoCardMessage] ?? "No card found"
            session.alertMessage = message
            return
        }
        guard case .iso7816(let nfcTag) = tag else {
            let message = messages[Self.keyUnsupportedCardMessage] ?? "Invalid card"
            self.invalidateSession(error: message)
            return
        }

        session.alertMessage = messages[Self.keyConnectMessage] ?? "Connecting"

        // Connect to tag
        session.connect(to: tag) { [unowned self] (error: Swift.Error?) in
            if error != nil {
                let message = self.messages[Self.keyConnectionError] ?? "Connection error. Please try again."
                self.invalidateSession(error: message)
                return
            }
            self.onCardPresent(tag: nfcTag)
        }
    }
}
