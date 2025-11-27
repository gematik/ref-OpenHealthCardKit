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

import ASN1Kit
import Foundation
@testable import HealthCardAccess
import Nimble
import XCTest

class HCCExtMiscTest: XCTestCase {
    func testFingerprint() throws {
        let prefix = Data(repeating: 0xA5, count: 128)
        let expected = Data([0x80, 0xFA, 0x0, 0x0, 0x80] + prefix + [0x0])

        let command = try HealthCardCommand.Misc.fingerprint(for: prefix)
        expect {
            command.bytes
        } == expected

        expect(
            command.responseStatuses.keys
        ).to(contain([0x9000, 0x6982]))

        expect {
            try HealthCardCommand.Misc.fingerprint(for: Data())
        }.to(throwError(HealthCardCommandBuilder.InvalidArgument.illegalSize(0, expected: 128)))
    }

    func testGenerateAsymmetricKeyPair() { // swiftlint:disable:this function_body_length
        guard let key = try? Key(8) else {
            Nimble.fail("could not create reference key")
            return
        }
        let responseStatus: [UInt16] = [
            0x9000, 0x6400, 0x6581, 0x6982, 0x6985, 0x6A88, 0x63C0, 0x63C1, 0x63C2, 0x63C3, 0x63C4,
            0x63C5, 0x63C6, 0x63C7, 0x63C8, 0x63C9, 0x63CA, 0x63CB, 0x63CC, 0x63CD, 0x63CE, 0x63CF,
        ]
        typealias GAKPTestCase = (name: String, expected: (Data, [UInt16]), mode: HealthCardCommand.Misc.GenerationMode)
        let testCases: [GAKPTestCase] = [
            (
                name: "ReadOnly",
                expected: (Data([0x0, 0x46, 0x81, 0x0, 0x0, 0x0, 0x0]), responseStatus),
                mode: .readOnly(reference: nil, dfSpecific: false)
            ),
            (
                name: "ReadOnly with key",
                expected: (Data([0x0, 0x46, 0x81, 0x8, 0x0, 0x0, 0x0]), responseStatus),
                mode: .readOnly(reference: key, dfSpecific: false)
            ),
            (
                name: "ReadOnly with dfSpecific key",
                expected: (Data([0x0, 0x46, 0x81, 0x88, 0x0, 0x0, 0x0]), responseStatus),
                mode: .readOnly(reference: key, dfSpecific: true)
            ),
            // Generate out
            (
                name: "Generate out",
                expected: (Data([0x0, 0x46, 0x80, 0x0, 0x0, 0x0, 0x0]), responseStatus),
                mode: .generate(reference: nil, dfSpecific: false, overwrite: false, out: true)
            ),
            (
                name: "Generate with Key and out",
                expected: (Data([0x0, 0x46, 0x80, 0x8, 0x0, 0x0, 0x0]), responseStatus),
                mode: .generate(reference: key, dfSpecific: false, overwrite: false, out: true)
            ),
            (
                name: "Generate with dfSpecific Key and out",
                expected: (Data([0x0, 0x46, 0x80, 0x88, 0x0, 0x0, 0x0]), responseStatus),
                mode: .generate(reference: key, dfSpecific: true, overwrite: false, out: true)
            ),
            // Generate no-out
            (
                name: "Generate No-out",
                expected: (Data([0x0, 0x46, 0x84, 0x0]), responseStatus),
                mode: .generate(reference: nil, dfSpecific: false, overwrite: false, out: false)
            ),
            (
                name: "Generate with key and No-out",
                expected: (Data([0x0, 0x46, 0x84, 0x8]), responseStatus),
                mode: .generate(reference: key, dfSpecific: false, overwrite: false, out: false)
            ),
            (
                name: "Generate with dfSpecific Key and No-out",
                expected: (Data([0x0, 0x46, 0x84, 0x88]), responseStatus),
                mode: .generate(reference: key, dfSpecific: true, overwrite: false, out: false)
            ),
            // Generate overwrite and out
            (
                name: "Generate overwrite out",
                expected: (Data([0x0, 0x46, 0xC0, 0x0, 0x0, 0x0, 0x0]), responseStatus),
                mode: .generate(reference: nil, dfSpecific: false, overwrite: true, out: true)
            ),
            (
                name: "Generate overwrite with key and out",
                expected: (Data([0x0, 0x46, 0xC0, 0x8, 0x0, 0x0, 0x0]), responseStatus),
                mode: .generate(reference: key, dfSpecific: false, overwrite: true, out: true)
            ),
            (
                name: "Generate overwrite with dfSpecific Key and out",
                expected: (Data([0x0, 0x46, 0xC0, 0x88, 0x0, 0x0, 0x0]), responseStatus),
                mode: .generate(reference: key, dfSpecific: true, overwrite: true, out: true)
            ),
            // Generate overwrite and no-out
            (
                name: "Generate overwrite No-out",
                expected: (Data([0x0, 0x46, 0xC4, 0x0]), responseStatus),
                mode: .generate(reference: nil, dfSpecific: false, overwrite: true, out: false)
            ),
            (
                name: "Generate overwritewith key and No-out",
                expected: (Data([0x0, 0x46, 0xC4, 0x8]), responseStatus),
                mode: .generate(reference: key, dfSpecific: false, overwrite: true, out: false)
            ),
            (
                name: "Generate overwritewith dfSpecific Key and No-out",
                expected: (Data([0x0, 0x46, 0xC4, 0x88]), responseStatus),
                mode: .generate(reference: key, dfSpecific: true, overwrite: true, out: false)
            ),
        ]
        testCases.forEach { testCase in
            let errors = Nimble.gatherFailingExpectations(silently: true) {
                // Do test
                let command = HealthCardCommand.Misc.generateAsymmetricKeyPair(mode: testCase.mode)
                expect {
                    command.bytes
                } == testCase.expected.0

                expect {
                    command.responseStatuses.keys
                }.to(contain(testCase.expected.1))
            }
            if !errors.isEmpty {
                Nimble.fail("Test (GAKP): [\(testCase.name)] failed!")
                errors.forEach { assertion in
                    Nimble.fail(String(describing: assertion))
                }
            }
        }
    }

    func testChallengeCommand() {
        typealias ChallengeTestCase = (name: String, mode: HealthCardCommand.Misc.ChallengeParameter,
                                       expected: (Data, [UInt16]))
        let responseCodes: [UInt16] = [0x9000] // no errors specified
        let testCases: [ChallengeTestCase] = [
            (name: "DES Challenge", mode: .des, expected: (Data([0x0, 0x84, 0x0, 0x0, 0x8]), responseCodes)),
            (name: "AES Challenge", mode: .aes, expected: (Data([0x0, 0x84, 0x0, 0x0, 0x10]), responseCodes)),
            (name: "RSA Challenge", mode: .rsa, expected: (Data([0x0, 0x84, 0x0, 0x0, 0x8]), responseCodes)),
            (name: "ELC Challenge", mode: .elc, expected: (Data([0x0, 0x84, 0x0, 0x0, 0x10]), responseCodes)),
        ]

        testCases.forEach { testCase in
            let errors = Nimble.gatherFailingExpectations(silently: true) {
                // Do test
                let command = HealthCardCommand.Misc.challenge(mode: testCase.mode)
                expect {
                    command.bytes
                } == testCase.expected.0

                expect {
                    command.responseStatuses.keys
                }.to(contain(testCase.expected.1))
            }
            if !errors.isEmpty {
                Nimble.fail("Test (Challenge): [\(testCase.name)] failed!")
                errors.forEach { assertion in
                    Nimble.fail(String(describing: assertion))
                }
            }
        }
    }

    func testRandomCommand() {
        let responseCodes: [UInt16] = [0x9000, 0x6982]
        for length in 0 ... 255 {
            let expected = Data([0x80, 0x84, 0x0, 0x0, UInt8(length)])
            let command = try? HealthCardCommand.Misc.random(length: length)
            expect {
                command?.bytes
            } == expected
            expect {
                command?.responseStatuses.keys
            }.to(contain(responseCodes))
        }

        expect {
            try HealthCardCommand.Misc.random(length: 256)
        }.to(throwError(HealthCardCommandBuilder.InvalidArgument.illegalValue(256, for: "length", expected: 0 ..< 256)))

        expect {
            try HealthCardCommand.Misc.random(length: -1)
        }.to(throwError(HealthCardCommandBuilder.InvalidArgument.illegalValue(-1, for: "length", expected: 0 ..< 256)))
    }

    func testListPublicKeys() {
        let expected = Data([0x80, 0xCA, 0x01, 0x0, 0x0, 0x0, 0x0])
        let responseCodes: [UInt16] = [0x9000, 0x6200]

        let command = HealthCardCommand.Misc.listPublicKeys()
        expect {
            command.bytes
        } == expected

        expect {
            command.responseStatuses.keys
        }.to(contain(responseCodes))
    }

    let manageChannelResponseCodes: [UInt16] = [0x9000, 0x6981]

    func testOpenLogicChannel() {
        let expected = Data([0x0, 0x70, 0x0, 0x0, 0x1])

        let command = HealthCardCommand.Misc.openLogicChannel()
        expect {
            command.bytes
        } == expected

        expect {
            command.responseStatuses.keys
        }.to(contain(manageChannelResponseCodes))
    }

    func testCloseLogicChannel() {
        let channel: UInt8 = 0x1
        let expected = Data([channel, 0x70, 0x80, 0x0])

        let command = HealthCardCommand.Misc.closeLogicChannel(number: channel)
        expect {
            command.bytes
        } == expected

        expect {
            command.responseStatuses.keys
        }.to(contain(manageChannelResponseCodes))
    }

    func testResetLogicChannel() {
        let channel: UInt8 = 0x1
        let expected = Data([channel, 0x70, 0x40, 0x0])

        let command = HealthCardCommand.Misc.resetLogicChannel(number: channel)
        expect {
            command.bytes
        } == expected

        expect {
            command.responseStatuses.keys
        }.to(contain(manageChannelResponseCodes))
    }

    func testResetApplication() {
        let expected = Data([0x0, 0x70, 0x40, 0x1])

        expect {
            HealthCardCommand.Misc.resetApplication().bytes
        } == expected

        expect {
            HealthCardCommand.Misc.resetApplication().responseStatuses.keys
        }.to(contain(manageChannelResponseCodes))
    }

    static let allTests = [
        ("testFingerprint", testFingerprint),
        ("testGenerateAsymmetricKeyPair", testGenerateAsymmetricKeyPair),
        ("testChallengeCommand", testChallengeCommand),
        ("testRandomCommand", testRandomCommand),
        ("testOpenLogicChannel", testOpenLogicChannel),
        ("testCloseLogicChannel", testCloseLogicChannel),
        ("testResetLogicChannel", testResetLogicChannel),
        ("testResetApplication", testResetApplication),
    ]
}
