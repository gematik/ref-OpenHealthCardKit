//
// Copyright (Change Date see Readme), gematik GmbH
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// *******
//
// For additional notes and disclaimer from gematik and in case of changes by gematik find details in the "Readme" file.
//

import CardReaderAccess
import CardReaderProviderApi
@testable import CardSimulationCardReaderProvider
import Nimble
import XCTest

final class SimulatorCardReaderProviderTest: XCTestCase {
    func testProvider() {
        let wrappedController = SimulatorCardReaderProvider.provideCardReaderController()
        expect(type(of: wrappedController.value)).to(beIdenticalTo(SimulatorCardReaderController.self))
    }

    func testProviderRegistration() {
        let manager = CardReaderControllerManager.shared
        let controllers: [CardReaderControllerType] = manager.cardReaderControllers
        expect {
            controllers.first {
                type(of: $0) == SimulatorCardReaderController.self
            }
        }.toNot(beNil())
    }

    static var allTests = [
        ("testProvider", testProvider),
        ("testProviderRegistration", testProviderRegistration),
    ]
}
