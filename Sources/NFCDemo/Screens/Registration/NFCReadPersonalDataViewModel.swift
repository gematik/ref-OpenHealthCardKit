//
//  Copyright (c) 2024 gematik GmbH
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

struct PersonalData {
    let name: String
    let firstName: String
    let address: String
    let insuranceNumber: String

    static let dummy = PersonalData(
        name: "Dummy Data",
        firstName: "Max",
        address: "Musterstraße 1, 12345 Musterstadt",
        insuranceNumber: "A123456789"
    )
}

protocol ReadPersonalData {
    var state: Published<ViewState<PersonalData, Error>>.Publisher { get }

    func readPersonalData(can: String) async

    func dismissError() async
}

class NFCReadPersonalDataViewModel: ObservableObject, Observable {
    @Environment(\.readPersonalDataController) var readPersonalDataController: ReadPersonalData
    @Published var state: ViewState<PersonalData, Error> = .idle
    @Published var results: [ReadingResult] = []

    private var disposables = Set<AnyCancellable>()

    init(state: ViewState<PersonalData, Error> = .idle) {
        self.state = state
        results = results
        readPersonalDataController.state
            .dropFirst()
            .sink { [weak self] viewState in
                self?.state = viewState

                guard !viewState.isLoading, !viewState.isIdle else {
                    return
                }
            }
            .store(in: &disposables)
    }

    func readPersonalData(can: String) async {
        await readPersonalDataController.readPersonalData(can: can)
    }
}
