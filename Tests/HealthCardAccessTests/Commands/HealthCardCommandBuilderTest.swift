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

import CardReaderProviderApi
import Foundation
@testable import HealthCardAccess
import Nimble
import XCTest

final class HealthCardCommandBuilderTest: XCTestCase {
    func testHealthCardCommandBuilder_setParameters() {
        expect(try HealthCardCommandBuilder().build().cla).toNot(equal(0x99))
        expect(try HealthCardCommandBuilder().set(cla: 0x99).build().cla).to(equal(0x99))
        expect(try HealthCardCommandBuilder().set(ins: 0x99).build().ins).to(equal(0x99))
        expect(try HealthCardCommandBuilder().set(p1: 0x99).build().p1).to(equal(0x99))
        expect(try HealthCardCommandBuilder().set(p2: 0x99).build().p2).to(equal(0x99))
        expect(try HealthCardCommandBuilder().set(data: Data(count: 4)).build().data).to(equal(Data(count: 4)))
        expect(try HealthCardCommandBuilder().set(ne: 0x9999).build().ne).to(equal(0x9999))
    }

    func testHealthCardCommandBuilder_failSetParameters() {
        // length of data not feasible for HealthCardCommand
        expect(try HealthCardCommandBuilder().set(data: Data(count: 70000)).build()).to(throwError())
    }

    func testFromCommand() {
        let selectCommand = HealthCardCommand.Select.selectParent()
        expect {
            try HealthCardCommandBuilder.builder(from: selectCommand).build().bytes
        } == selectCommand.bytes
    }

    static let allTests = [
        ("testHealthCardCommandBuilder_setParameters", testHealthCardCommandBuilder_setParameters),
        ("testHealthCardCommandBuilder_failSetParameters", testHealthCardCommandBuilder_failSetParameters),
        ("testFromCommand", testFromCommand),
    ]
}
