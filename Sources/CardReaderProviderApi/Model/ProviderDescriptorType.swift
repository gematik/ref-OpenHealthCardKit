//
//  ${GEMATIK_COPYRIGHT_STATEMENT}
//

import Foundation

/// Card Reader Provider information
@objc public protocol ProviderDescriptorType {
    /// Provider (displayable) commercial name
    var name: String { get }
    /// License
    var license: String { get }
    /// Provider and/or card reader description
    var providerDescription: String { get }
    /// Short description
    var shortDescription: String { get }
    /// Principle className for communication with the (hardware) card reader
    var providerClassName: String { get }
}
