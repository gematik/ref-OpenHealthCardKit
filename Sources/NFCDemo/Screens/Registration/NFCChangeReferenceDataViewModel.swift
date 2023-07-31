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

protocol ChangeReferenceData {
    var state: Published<ViewState<Bool, Error>>.Publisher { get }

    func changeReferenceDataSetNewPin(can: String, oldPin: String, newPin: String)

    func dismissError()
}

class NFCChangeReferenceDataViewModel: ObservableObject {
    @Environment(\.changeReferenceDataController) var changeReferenceDataController: ChangeReferenceData
    @Published var state: ViewState<Bool, Error> = .idle
    @Published var results: [ReadingResult] = []

    private var disposables = Set<AnyCancellable>()

    init(state: ViewState<Bool, Error> = .idle, results: [ReadingResult] = []) {
        self.state = state
        self.results = results
        changeReferenceDataController.state
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

    func changeReferenceDataSetNewPin(can: String, oldPin: String, newPin: String) {
        changeReferenceDataController.changeReferenceDataSetNewPin(can: can, oldPin: oldPin, newPin: newPin)
    }

    func dismissError() {
        changeReferenceDataController.dismissError()
    }
}
