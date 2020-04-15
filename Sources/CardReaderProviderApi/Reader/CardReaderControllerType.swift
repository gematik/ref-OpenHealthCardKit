//
//  ${GEMATIK_COPYRIGHT_STATEMENT}
//

import Foundation

/// Delegate methods for the CardReaderController
public protocol CardReaderControllerDelegate: class {
    /**
        Inform the delegate of a (new) connected/available `CardReaderType`.

        - Parameters:
            - controller: the calling (owning) controller
            - cardReader: the card reader that became available
     */
    func cardReader(controller: CardReaderControllerType, didConnect cardReader: CardReaderType)

    /**
        Inform the delegate of a card reader disconnect.

        - Parameters:
            - controller: the calling (owning) controller
            - reader: the terminal that became unavailable
     */
    func cardReader(controller: CardReaderControllerType, didDisconnect cardReader: CardReaderType)
}

/// Controller representation for managing card readers
public protocol CardReaderControllerType: class {
    /// The identifier name for the controller
    var name: String { get }

    /// The currently available card readers
    var cardReaders: [CardReaderType] { get }

    /**
        Add a delegate to get informed when the cardReaders array changes.
        
        - Parameter delegate: The delegate that should be added and informed upon updates.
     */
    func add(delegate: CardReaderControllerDelegate)

    /**
        Remove a previously added delegate.

        - Parameter delegate: The delegate that should be removed from receiving updates.
     */
    func remove(delegate: CardReaderControllerDelegate)
}
