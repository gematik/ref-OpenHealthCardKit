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
