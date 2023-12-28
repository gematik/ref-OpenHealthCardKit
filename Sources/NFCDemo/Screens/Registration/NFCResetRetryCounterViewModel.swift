//
//  Copyright (c) 2023 gematik GmbH
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
import Helper
import NFCCardReaderProvider
import SwiftUI

protocol ResetRetryCounter {
    var state: Published<ViewState<Bool, Error>>.Publisher { get }

    func resetRetryCounter(can: String, puk: String)

    func resetRetryCounterWithNewPin(can: String, puk: String, newPin: String)

    func dismissError()
}

class NFCResetRetryCounterViewModel: ObservableObject {
    @Environment(\.resetRetryCounterController) var resetRetryCounterController: ResetRetryCounter
    @Published var state: ViewState<Bool, Error> = .idle
    @Published var results: [ReadingResult] = []

    private var disposables = Set<AnyCancellable>()

    init(state: ViewState<Bool, Error> = .idle, results: [ReadingResult] = []) {
        self.state = state
        self.results = results
        resetRetryCounterController.state
            .dropFirst()
            .sink { [weak self] viewState in
                self?.state = viewState

                guard !viewState.isLoading, !viewState.isIdle else {
                    return
                }

                let result = ReadingResult(result: viewState,
                                           commands: CommandLogger.commands)
                self?.results.append(result)
                CommandLogger.commands = []
            }
            .store(in: &disposables)
    }

    func resetRetryCounter(can: String, puk: String) {
        resetRetryCounterController.resetRetryCounter(can: can, puk: puk)
    }

    func resetRetryCounterWithNewPin(can: String, puk: String, newPin: String) {
        resetRetryCounterController.resetRetryCounterWithNewPin(can: can, puk: puk, newPin: newPin)
    }

    func dismissError() {
        resetRetryCounterController.dismissError()
    }
}
