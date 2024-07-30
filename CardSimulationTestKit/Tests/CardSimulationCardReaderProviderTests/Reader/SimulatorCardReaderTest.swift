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

@testable import CardSimulationCardReaderProvider
import Nimble
import XCTest

final class SimulatorCardReaderTest: XCTestCase {
    func testCardCardReader_properties() {
        let mockRunner = MockSimulationRunner()
        let cardReader = SimulatorCardReader(cardReader: mockRunner, host: "my-host")

        expect(cardReader.name).to(equal("cardsim-my-host-?"))
        expect(cardReader.cardPresent).to(beFalse())

        mockRunner.mode = .initializing
        expect(cardReader.name).to(equal("cardsim-my-host-?"))
        expect(cardReader.cardPresent).to(beFalse())

        mockRunner.mode = .running(onTCPPort: 3000)
        expect(cardReader.name).to(equal("cardsim-my-host-3000"))
        expect(cardReader.cardPresent).to(beTrue())

        mockRunner.mode = .terminated(terminationStatus: -1)
        expect(cardReader.name).to(equal("cardsim-my-host-x"))
        expect(cardReader.cardPresent).to(beFalse())
    }

    func testCardCardReader_on_card_present() {
        var blockInvoked = 0
        let block: SimulatorCardReader.CardPresentBlock = { _ in
            blockInvoked += 1
        }
        var earlyBlockInvoked = 0
        let earlyBlock: SimulatorCardReader.CardPresentBlock = { _ in
            earlyBlockInvoked += 1
        }
        let mockRunner = MockSimulationRunner()
        mockRunner.mode = .running(onTCPPort: 900)
        let cardReader = SimulatorCardReader(cardReader: mockRunner)
        cardReader.onCardPresenceChanged(earlyBlock)
        expect(earlyBlockInvoked).to(equal(1))
        mockRunner.mode = .initializing

        cardReader.onCardPresenceChanged(block)
        cardReader.checkRunnerModeDidChange()
        expect(blockInvoked).to(equal(0))

        mockRunner.mode = .running(onTCPPort: 1000)
        expect(blockInvoked).to(equal(0))
        cardReader.checkRunnerModeDidChange()
        expect(blockInvoked).to(equal(1))
        // make sure we have only one callback, so earlyBlock should not have been invoked
        expect(earlyBlockInvoked).to(equal(1))
        mockRunner.mode = .initializing
        cardReader.checkRunnerModeDidChange()
        expect(blockInvoked).to(equal(1))
        mockRunner.mode = .running(onTCPPort: 1001)
        cardReader.checkRunnerModeDidChange()
        expect(blockInvoked).to(equal(2))
    }

    func testCardCardReader_connect() {
        let mockRunner = MockSimulationRunner()
        let cardReader = SimulatorCardReader(cardReader: mockRunner, host: "testhost")

        expect(try? cardReader.connect([:])).to(beNil())
        mockRunner.mode = .running(onTCPPort: 1000)
        guard let card = try? cardReader.connect([:]), let simCard = card as? SimulatorCard else {
            Nimble.fail("Could not connect to cardReader or is not type(of: SimulatorCard)")
            return
        }
        expect(simCard.port).to(equal(1000))
        expect(simCard.host).to(equal("testhost"))
    }

    static var allTests = [
        ("testCardCardReader_properties", testCardCardReader_properties),
        ("testCardCardReader_on_card_present", testCardCardReader_on_card_present),
        ("testCardCardReader_connect", testCardCardReader_connect),
    ]
}
