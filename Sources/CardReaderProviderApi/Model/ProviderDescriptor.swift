//
//  ${GEMATIK_COPYRIGHT_STATEMENT}
//

import Foundation

/// Default ProviderDescriptor
public class ProviderDescriptor: ProviderDescriptorType {
    public let name: String
    public let license: String
    public let providerDescription: String
    public let shortDescription: String
    public let providerClassName: String

    public init(_ name: String, _ license: String, _ description: String, _ shortDesc: String, _ className: String) {
        self.name = name
        self.license = license
        self.providerDescription = description
        self.shortDescription = shortDesc
        self.providerClassName = className
    }
}
