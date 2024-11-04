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

import Helper
@testable import NFCDemo
import SnapshotTesting
import SwiftUI
import XCTest

// swiftlint:disable force_unwrapping
class ReadingResultsViewSnapshotTests: ERPSnapshotTestCase {
    func testReadingResultsViewSnapshotTests() throws {
        let sut = NavigationView {
            ReadingResultsView(
                readingResults: [
                    ReadingResult(
                        timestamp: "2021-05-26T10:59:37+00:00".date!,
                        result: ViewState.value(true),
                        commands: []
                    ),
                    ReadingResult(
                        timestamp: "2021-05-26T10:59:38+00:00".date!,
                        result: ViewState.value(true),
                        commands: []
                    ),
                    ReadingResult(
                        timestamp: "2021-05-26T10:59:39+00:00".date!,
                        result: .error(NFCLoginController.Error.invalidCanOrPinFormat),
                        commands: []
                    ),
                ]
            )
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        assertSnapshots(of: sut, as: snapshotModi())
    }

    func testReadingResultsDetailViewSnapshotTests() throws {
        let sut = NavigationView {
            ReadingResultsView.DetailView(
                result: ReadingResult(
                    timestamp: "2021-05-26T10:59:37+00:00".date!,
                    result: .error(NFCLoginController.Error.invalidCanOrPinFormat),
                    commands: [
                        Command(message: "Establish secure connection", type: .description),
                        Command(message: "00A4040CD2760001448000|ne:-1]", type: .send),
                        Command(message: "9000", type: .response),
                        Command(message: "Verify PIN", type: .description),
                        Command(message: "00A4040C", type: .sendSecureChannel),
                        Command(message: "sending something encrypted", type: .send),
                        Command(message: "some encrypted response", type: .response),
                        Command(message: "62C7", type: .responseSecureChannel),
                    ]
                )
            )
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        assertSnapshots(of: sut, as: snapshotModi())
    }
}

extension String {
    var date: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withColonSeparatorInTimeZone
        return formatter.date(from: self)
    }
}
