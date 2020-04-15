//
//  ${GEMATIK_COPYRIGHT_STATEMENT}
//

import Foundation

/**
    The `CardReaderProviderType` protocol serves as the gateway for third-party
    CardReaderController adapters/drivers to register their implementations for CardReaderController(s)
    and/or CardReaderProvider(s) within the HealthCardAccess domain.
 */
@objc public protocol CardReaderProviderType {
    /**
        Tell the provider to load and initialize the CardReaderController

        - Note: this method should not throw

        - Returns: Wrapped `CardReaderControllerType`
     */
    static func provideCardReaderController() -> CardReaderControllerObjcWrapper

    /// Card Reader Provider information
    static var descriptor: ProviderDescriptorType { get }
}

/// We need to use a wrapper to bridge the `CardReaderControllerType` since its Type cannot be represented in ObjC
public class CardReaderControllerObjcWrapper: NSObject {
    /// The bridged CardReaderController
    public let value: CardReaderControllerType

    /**
        Initialize the wrapper with the wrapped controller.

        - Parameter value: the card reader controller
     */
    public required init(_ value: CardReaderControllerType) {
        self.value = value
    }
}
