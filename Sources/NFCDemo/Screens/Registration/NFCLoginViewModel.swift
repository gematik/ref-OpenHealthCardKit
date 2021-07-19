//
//  Copyright (c) 2021 gematik GmbH
//  
//  Licensed under the Apache License, Version 2.0 (the License);
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//      http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an 'AS IS' BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Combine
import Foundation
import SwiftUI

protocol LoginController {
    var state: Published<ViewState<Bool, Error>>.Publisher { get }

    func login(can: String, pin: String)
    func dismissError()
}

class NFCLoginViewModel: ObservableObject {
    @Environment(\.loginController) var loginController: LoginController
    @Published var state: ViewState<Bool, Error> = .idle

    private var disposables = Set<AnyCancellable>()

    init() {
        loginController.state
            .assign(to: \.state, on: self)
            .store(in: &disposables)
    }

    func login(can: String, pin: String) {
        loginController.login(can: can, pin: pin)
    }

    func dismissError() {
        loginController.dismissError()
    }
}
