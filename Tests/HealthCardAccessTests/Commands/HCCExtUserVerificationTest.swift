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

import Foundation
@testable import HealthCardAccess
import Nimble
import XCTest

final class HCCExtUserVerificationTest: XCTestCase {
    func testChangeReferenceData() throws {
        let oldPin = "123456" as Format2Pin
        let newPin = "654321" as Format2Pin
        let password = "12" as Password

        let expected = Data([0x0, 0x24, 0x0, 0x92, 0x10] + oldPin.pin + newPin.pin)
        expect {
            try HealthCardCommand.ChangeReferenceData.change(
                password: (password: password, dfSpecific: true, old: oldPin, new: newPin)
            )
            .bytes
        } == expected
        // Check response status
        let statusKeys = try HealthCardCommand.ChangeReferenceData.change(
            password: (password: password, dfSpecific: true, old: oldPin, new: newPin)
        )
        .responseStatuses.keys
        expect(statusKeys).to(contain(
            [0x9000, 0x63C0, 0x63C1, 0x63C2, 0x63C3, 0x63C4, 0x63C5, 0x63C6, 0x63C7, 0x63C8, 0x63C9, 0x63CA,
             0x63CB, 0x63CC, 0x63CD, 0x63CE, 0x63CF, 0x6581, 0x6982, 0x6983, 0x6985, 0x6A88]
        ))
    }

    func testSetReferenceData() throws {
        let pin = "654321" as Format2Pin
        let password = "12" as Password

        let expected = Data([0x0, 0x24, 0x1, 0x12, 0x8] + pin.pin)
        expect {
            HealthCardCommand.ChangeReferenceData.set(password: (password: password,
                                                                 dfSpecific: false, pin: pin))
                .bytes
        } == expected

        // Check response status
        let statusKeys = HealthCardCommand.ChangeReferenceData
            .set(password: (password: password, dfSpecific: true, pin: pin))
            .responseStatuses.keys
        expect(statusKeys).to(contain(
            [0x9000, 0x63C0, 0x63C1, 0x63C2, 0x63C3, 0x63C4, 0x63C5, 0x63C6, 0x63C7, 0x63C8, 0x63C9, 0x63CA,
             0x63CB, 0x63CC, 0x63CD, 0x63CE, 0x63CF, 0x6581, 0x6982, 0x6983, 0x6985, 0x6A88]
        ))
    }

    func testDisableVerificationRequirement() throws {
        let verificationData = "654321" as Format2Pin
        let password = "12" as Password

        let expectedWithVerificationData = Data([0x0, 0x26, 0x0, 0x12, 0x8] + verificationData.pin)
        expect {
            try HealthCardCommand.DisableVerificationRequirement
                .disable(password: (password: password, dfSpecific: false, verificationData: verificationData))
                .bytes
        } == expectedWithVerificationData

        let expectedWithoutVerificationData = Data([0x0, 0x26, 0x1, 0x12])
        expect {
            try HealthCardCommand.DisableVerificationRequirement
                .disable(password: (password: password, dfSpecific: false, verificationData: nil))
                .bytes
        } == expectedWithoutVerificationData

        // Check response status
        let statusKeys = try HealthCardCommand.DisableVerificationRequirement
            .disable(password: (password: password, dfSpecific: true, verificationData: verificationData))
            .responseStatuses.keys
        expect(statusKeys).to(contain(
            [0x9000, 0x63C0, 0x63C1, 0x63C2, 0x63C3, 0x63C4, 0x63C5, 0x63C6, 0x63C7, 0x63C8, 0x63C9, 0x63CA,
             0x63CB, 0x63CC, 0x63CD, 0x63CE, 0x63CF, 0x6581, 0x6982, 0x6983, 0x6985, 0x6A88]
        ))
    }

    func testEnableVerificationRequirement() throws {
        let verificationData = "654321" as Format2Pin
        let password = "12" as Password

        let expectedWithVerificationData = Data([0x0, 0x28, 0x0, 0x12, 0x8] + verificationData.pin)
        expect {
            try HealthCardCommand.EnableVerificationRequirement
                .enable(password: (password: password, dfSpecific: false, verificationData: verificationData))
                .bytes
        } == expectedWithVerificationData

        let expectedWithoutVerificationData = Data([0x0, 0x28, 0x1, 0x12])
        expect {
            try HealthCardCommand.EnableVerificationRequirement
                .enable(password: (password: password, dfSpecific: false, verificationData: nil))
                .bytes
        } == expectedWithoutVerificationData

        // Check response status
        let statusKeys = try HealthCardCommand.EnableVerificationRequirement
            .enable(password: (password: password, dfSpecific: true, verificationData: verificationData))
            .responseStatuses.keys
        expect(statusKeys).to(contain(
            [0x9000, 0x63C0, 0x63C1, 0x63C2, 0x63C3, 0x63C4, 0x63C5, 0x63C6, 0x63C7, 0x63C8, 0x63C9, 0x63CA,
             0x63CB, 0x63CC, 0x63CD, 0x63CE, 0x63CF, 0x6581, 0x6982, 0x6983, 0x6985, 0x6A88]
        ))
    }

    func testResetRetryCounter() throws {
        let puk = "12345678" as Format2Pin
        let newPin = "654321" as Format2Pin
        let password = "12" as Password

        let expectedCommand = Data([0x0, 0x2C, 0x01, 0x12, 0x08] + puk.pin)
        expect {
            try HealthCardCommand.ResetRetryCounter.resetRetryCounterWithPukWithoutNewSecret(
                password: password,
                dfSpecific: false,
                puk: puk
            )
            .bytes
        } == expectedCommand

        let expectedCommandWithNewPin = Data([0x0, 0x2C, 0x0, 0x12, 0x10] + puk.pin + newPin.pin)
        expect {
            try HealthCardCommand.ResetRetryCounter.resetRetryCounterWithPukWithNewSecret(
                password: password,
                dfSpecific: false,
                puk: puk,
                newPin: newPin
            )
            .bytes
        } == expectedCommandWithNewPin

        // Check response status
        let statusKeys = try HealthCardCommand.ResetRetryCounter.resetRetryCounterWithPukWithNewSecret(
            password: password,
            dfSpecific: false,
            puk: puk,
            newPin: newPin
        )
        .responseStatuses
        .keys

        expect(statusKeys).to(
            contain(
                [
                    0x9000, 0x63C0, 0x63C1, 0x63C2, 0x63C3, 0x63C4, 0x63C5, 0x63C6, 0x63C7, 0x63C8, 0x63C9,
                    0x63CA, 0x63CB, 0x63CC, 0x63CD, 0x63CE, 0x63CF, 0x6581, 0x6982, 0x6983, 0x6985, 0x6A88,
                ]
            )
        )
    }

    func testVerifyPassword() throws {
        let pin = "654321" as Format2Pin
        let password = "12" as Password

        let expected = Data([0x0, 0x20, 0x0, 0x12, 0x8] + pin.pin)
        expect {
            HealthCardCommand.Verify.verify(password: (password: password, dfSpecific: false, pin: pin))
                .bytes
        } == expected

        // Check response status
        let statusKeys = HealthCardCommand.ChangeReferenceData
            .set(password: (password: password, dfSpecific: true, pin: pin))
            .responseStatuses.keys
        expect(statusKeys).to(contain(
            [0x9000, 0x63C0, 0x63C1, 0x63C2, 0x63C3, 0x63C4, 0x63C5, 0x63C6, 0x63C7, 0x63C8, 0x63C9, 0x63CA,
             0x63CB, 0x63CC, 0x63CD, 0x63CE, 0x63CF, 0x6581, 0x6982, 0x6983, 0x6985, 0x6A88]
        ))
    }

    func testGetPinStatus() throws {
        let password = "12" as Password
        let expectedGlobal = Data([0x80, 0x20, 0x0, 0x12])
        let expectedSpecific = Data([0x80, 0x20, 0x0, 0x92])

        expect {
            HealthCardCommand.Status.status(for: (password: password, dfSpecific: false)).bytes
        } == expectedGlobal
        expect {
            HealthCardCommand.Status.status(for: (password: password, dfSpecific: true)).bytes
        } == expectedSpecific

        // Check response status
        let statusKeys = HealthCardCommand.Status.status(for: (password: password, dfSpecific: false))
            .responseStatuses.keys
        expect(statusKeys).to(contain(
            [0x62C1, 0x62C7, 0x62D0, 0x63C0, 0x63C1, 0x63C2, 0x63C3, 0x63C4, 0x63C5, 0x63C6,
             0x63C7, 0x63C8, 0x63C9, 0x63CA, 0x63CB, 0x63CC, 0x63CD, 0x63CE, 0x63CF, 0x9000]
        ))
    }
}
