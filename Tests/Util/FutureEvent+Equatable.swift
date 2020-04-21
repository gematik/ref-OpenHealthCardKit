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
import HealthCardAccess

extension FutureEvent: Equatable where T: Equatable {
    public static func ==(lhs: FutureEvent<T>, rhs: FutureEvent<T>) -> Bool {
        //swiftlint:disable:previous operator_whitespace
        switch (lhs, rhs) {
        case (.completed(let value1), .completed(let value2)): return value1 == value2
        case (.failed(let error1), .failed(let error2)): return error1 == error2
        default:
            return false
        }
    }
}

extension FutureEvent.Error: Equatable {
    public static func ==(lhs: FutureEvent.Error, rhs: FutureEvent.Error) -> Bool {
        //swiftlint:disable:previous operator_whitespace
        switch (lhs, rhs) {
        case (.error(let error1), .error(let error2)): return error1.localizedDescription == error2.localizedDescription
        case (.cancelled, .cancelled): return true
        default:
            return false
        }
    }
}
