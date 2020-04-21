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
@testable import HealthCardAccess
import Nimble
import XCTest

final class HCCExtUserVerificationTest: XCTestCase {

    func testChangeReferenceData() {
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
        expect {
            try HealthCardCommand.ChangeReferenceData.change(
                    password: (password: password, dfSpecific: true, old: oldPin, new: newPin)
            )
                    .responseStatuses.keys
        }.to(contain([0x9000, 0x63c0, 0x63c1, 0x63c2, 0x63c3, 0x63c4, 0x63c5, 0x63c6, 0x63c7, 0x63c8, 0x63c9, 0x63ca,
                      0x63cb, 0x63cc, 0x63cd, 0x63ce, 0x63cf, 0x6581, 0x6982, 0x6983, 0x6985, 0x6a88]))
    }

    func testSetReferenceData() {
        let pin = "654321" as Format2Pin
        let password = "12" as Password

        let expected = Data([0x0, 0x24, 0x1, 0x12, 0x8] + pin.pin)
        expect {
            HealthCardCommand.ChangeReferenceData.set(password: (password: password,
                    dfSpecific: false, pin: pin))
                    .bytes
        } == expected

        // Check response status
        expect {
            HealthCardCommand.ChangeReferenceData.set(password: (password: password,
                    dfSpecific: true, pin: pin))
                    .responseStatuses.keys
        }.to(contain([0x9000, 0x63c0, 0x63c1, 0x63c2, 0x63c3, 0x63c4, 0x63c5, 0x63c6, 0x63c7, 0x63c8, 0x63c9, 0x63ca,
                      0x63cb, 0x63cc, 0x63cd, 0x63ce, 0x63cf, 0x6581, 0x6982, 0x6983, 0x6985, 0x6a88]))
    }

    func testDisableVerificationRequirement() {
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
        expect {
            try HealthCardCommand.DisableVerificationRequirement
                    .disable(password: (password: password, dfSpecific: true, verificationData: verificationData))
                    .responseStatuses.keys
        }.to(contain([0x9000, 0x63c0, 0x63c1, 0x63c2, 0x63c3, 0x63c4, 0x63c5, 0x63c6, 0x63c7, 0x63c8, 0x63c9, 0x63ca,
                      0x63cb, 0x63cc, 0x63cd, 0x63ce, 0x63cf, 0x6581, 0x6982, 0x6983, 0x6985, 0x6a88]))
    }

    func testEnableVerificationRequirement() {
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
        expect {
            try HealthCardCommand.EnableVerificationRequirement
                    .enable(password: (password: password, dfSpecific: true, verificationData: verificationData))
                    .responseStatuses.keys
        }.to(contain([0x9000, 0x63c0, 0x63c1, 0x63c2, 0x63c3, 0x63c4, 0x63c5, 0x63c6, 0x63c7, 0x63c8, 0x63c9, 0x63ca,
                      0x63cb, 0x63cc, 0x63cd, 0x63ce, 0x63cf, 0x6581, 0x6982, 0x6983, 0x6985, 0x6a88]))
    }

    func testVerifyPassword() {
        let pin = "654321" as Format2Pin
        let password = "12" as Password

        let expected = Data([0x0, 0x20, 0x0, 0x12, 0x8] + pin.pin)
        expect {
            HealthCardCommand.Verify.verify(password: (password: password, dfSpecific: false, pin: pin))
                    .bytes
        } == expected

        // Check response status
        expect {
            HealthCardCommand.ChangeReferenceData.set(password: (password: password,
                    dfSpecific: true, pin: pin))

                    .responseStatuses.keys
        }.to(contain([0x9000, 0x63c0, 0x63c1, 0x63c2, 0x63c3, 0x63c4, 0x63c5, 0x63c6, 0x63c7, 0x63c8, 0x63c9, 0x63ca,
                      0x63cb, 0x63cc, 0x63cd, 0x63ce, 0x63cf, 0x6581, 0x6982, 0x6983, 0x6985, 0x6a88]))
    }

    func testGetPinStatus() {
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
        expect {
            HealthCardCommand.Status.status(for: (password: password, dfSpecific: false))
                    .responseStatuses
                    .keys
        }.to(contain([0x62c1, 0x62c7, 0x62d0, 0x63c0, 0x63c1, 0x63c2, 0x63c3, 0x63c4, 0x63c5, 0x63c6,
                      0x63c7, 0x63c8, 0x63c9, 0x63ca, 0x63cb, 0x63cc, 0x63cd, 0x63ce, 0x63cf, 0x9000]))
    }

    static let allTests = [
        ("testChangeReferenceData", testChangeReferenceData),
        ("testSetReferenceData", testSetReferenceData),
        ("testDisableVerificationRequirement", testDisableVerificationRequirement),
        ("testEnableVerificationRequirement", testEnableVerificationRequirement),
        ("testVerifyPassword", testVerifyPassword),
        ("testGetPinStatus", testGetPinStatus)
    ]
}
