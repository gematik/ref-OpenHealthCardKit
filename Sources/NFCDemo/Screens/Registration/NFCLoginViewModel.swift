//
//  Copyright (c) 2022 gematik GmbH
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

protocol LoginController {
    var state: Published<ViewState<Bool, Error>>.Publisher { get }

    func login(can: String, pin: String, checkBrainpoolAlgorithm: Bool)
    func dismissError()
}

class NFCLoginViewModel: ObservableObject {
    @Environment(\.loginController) var loginController: LoginController
    @Published var state: ViewState<Bool, Error> = .idle
    @Published var results: [ReadingResult] = []

    private var disposables = Set<AnyCancellable>()

    init(state: ViewState<Bool, Error> = .idle, results: [ReadingResult] = []) {
        self.state = state
        self.results = results
        loginController.state
            .dropFirst()
            .sink { [weak self] viewState in
                self?.state = viewState

                guard !viewState.isLoading, !viewState.isIdle else { return }

                let result = ReadingResult(result: viewState,
                                           commands: CommandLogger.commands)
                self?.results.append(result)
                CommandLogger.commands = []
            }
            .store(in: &disposables)
    }

    func login(can: String, pin: String, checkBrainpoolAlgorithm: Bool) {
        loginController.login(can: can, pin: pin, checkBrainpoolAlgorithm: checkBrainpoolAlgorithm)
    }

    func dismissError() {
        loginController.dismissError()
    }
}

struct ReadingResult: Identifiable {
    let id: UUID // swiftlint:disable:this identifier_name
    let timestamp: Date
    let result: ViewState<Bool, Error>
    let commands: [Command]

    init(
        identifier: UUID = UUID(),
        timestamp: Date = Date(),
        result: ViewState<Bool, Error>,
        commands: [Command]
    ) {
        id = identifier
        self.timestamp = timestamp
        self.result = result
        self.commands = commands
    }

    func formattedDescription() -> String {
        var description = "# SMART CARD\n\n"

        description += "Date: \(timestamp.description)\n"

        description += "\n# RESULT\n\n"

        if let error = result.error {
            description += "Finished with error message: '\(error.localizedDescription)'\n"
            description += "error: \(error)\n"
        }

        if let success = result.value {
            description += "Finished process with success: '\(success == true ? "true" : "false")'\n"
        }

        description += "\n# COMMANDS\n\n"

        guard !commands.isEmpty else {
            description += "No commands between smart card and device have been sent!\n"
            return description
        }

        for command in commands {
            switch command.type {
            case .send:
                description += "SEND:\n"
                description += "\(command.message)\n"
            case .sendSecureChannel:
                description += "SEND (secure channel, header only):\n"
                description += "\(command.message)\n\n"
            case .response:
                description += "\nRESPONSE:\n"
                description += "\(command.message)\n\n"
            case .responseSecureChannel:
                description += "RESPONSE (secure channel):\n"
                description += "\(command.message)\n\n"
            case .description:
                description += "\n\n*** \(command.message) ***\n\n"
            default: break
            }
        }
        return description
    }
}
