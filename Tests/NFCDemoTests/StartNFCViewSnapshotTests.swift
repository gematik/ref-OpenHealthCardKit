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

@testable import NFCDemo
import SnapshotTesting
import SwiftUI
import XCTest

class StartNFCViewSnapshotTests: XCTestCase {
    func testStartNFCViewSnapshotTests() throws {
        let sut = NavigationView { StartNFCView(can: "123456", puk: "12345678", pin: "123", useCase: .login) }
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        assertSnapshots(matching: sut, as: snapshotModi())
    }
}