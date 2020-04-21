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
