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
import GemCommonsKit

/// The protocol represents the behavior for a ServiceLoader that provides `CardReaderControllerType`s
public protocol CardReaderControllerManagerType: class {
    /// An array with card reader controllers for all card reader providers
    var cardReaderControllers: [CardReaderControllerType] { get }

    /// An array with all card reader provider descriptors found
    var cardReaderProviderDescriptors: [ProviderDescriptorType] {get}
}

/**
    The `CardReaderControllerManager` acts as a typical Java ServiceLoader for loading `CardReaderControllerType`
    via providers that conform to the `CardReaderProviderType` protocol.
 */
public class CardReaderControllerManager: CardReaderControllerManagerType {

    /// The main/shared instance for general purpose use.
    public static let shared: CardReaderControllerManagerType = {
        CardReaderControllerManager()
    }()

    private let _cardReaderProviders: [CardReaderProviderType.Type]

    /// Lazy initialize CardReaderControllers
    private lazy var _cardReaderControllers = {
        _cardReaderProviders.map {
            $0.provideCardReaderController().value
        }
    }()

    /// An array of all complete Provider Descriptors of each card reader provider available
    public var cardReaderProviderDescriptors: [ProviderDescriptorType] {
        return _cardReaderProviders.map {
            $0.descriptor
        }
    }

    /// The lazy loaded CardReaderControllers that where found by protocol reflection.
    public var cardReaderControllers: [CardReaderControllerType] {
        return _cardReaderControllers
    }

    /**
        Internal initializer for testing purposes.
        For general purpose use see `CardReaderControllerManager.shared`.
     */
    internal init(_ providers: [CardReaderProviderType.Type]
                  = CardReaderControllerManager.loadCardReaderProviders()) {
        _cardReaderProviders = providers
    }
}

extension CardReaderControllerManagerType {
    /// An array of all names of each card reader provider available
    public var cardReaderProviderNames: [String] {
        return cardReaderProviderDescriptors.map {
            $0.name
        }
    }
}

extension CardReaderControllerManager {
    private class func loadCardReaderProviders() -> [CardReaderProviderType.Type] {
        return loadClassesConformingTo(protocol: CardReaderProviderType.self)
                .compactMap {
                    ($0 as? CardReaderProviderType.Type)
                }
    }
}
