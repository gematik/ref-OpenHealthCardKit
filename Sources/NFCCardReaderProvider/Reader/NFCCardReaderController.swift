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
import Foundation
import GemCommonsKit

public class NFCCardReaderController: CardReaderControllerType {
    private let cardReaderDelegates = WeakArray<CardReaderControllerDelegate>()

    public var cardReaders: [CardReaderType] {
        if let reader = nfcReader {
            return [reader]
        } else {
            return []
        }
    }

    private var nfcReader: NFCCardReader? {
        willSet {
            guard let reader = nfcReader else {
                return
            }
            if newValue == nil {
                DLog("NFC reader disappeared")
                cardReaderDelegates.array.forEach { delegate in
                    delegate.cardReader(controller: self, didDisconnect: reader)
                }
            }
        }
        didSet {
            if let reader = nfcReader {
                cardReaderDelegates.array.forEach { delegate in
                    delegate.cardReader(controller: self, didConnect: reader)
                }
            }
        }
    }

    public var name: String {
        return NFCCardReaderProvider.name
    }

    public func add(delegate: CardReaderControllerDelegate) {
        if cardReaderDelegates.index(of: delegate) == nil {
            cardReaderDelegates.add(object: delegate)
        }
    }

    public func remove(delegate: CardReaderControllerDelegate) {
        guard let index = cardReaderDelegates.index(of: delegate) else {
            return
        }
        cardReaderDelegates.removeObject(at: index)
    }

    init() {
        if NFCTagReaderSession.readingAvailable {
            nfcReader = NFCCardReader(controllerName: name)
        } else {
            DLog("NFC reading feature is not available")
        }
    }
}
