//
//  ${GEMATIK_COPYRIGHT_STATEMENT}
//

import Foundation

/// Error cases for the (Smart)Card domain
public enum CardError: Error {
    /// When a particular action is not allowed
    case securityError(Error?)
    /// When a connection failed to establish or went away unexpectedly
    case connectionError(Error?)
    /// Upon encountering an illegal/unexpected state for a certain action
    case illegalState(Error?)
    /// An ObjC NSException was thrown
    case objcError(NSException?)
}
