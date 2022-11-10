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

import SnapshotTesting
import SwiftUI
import XCTest

/// The default `perceptualPrecision` to use if a specific value is not provided.
private let defaultPerceptualPrecision: Float = 0.93

extension XCTestCase {
    func snapshotModi<T>() -> [String: Snapshotting<T, UIImage>] where T: SwiftUI.View {
        [
            "light": .image(perceptualPrecision: defaultPerceptualPrecision),
            "dark": .image(
                precision: 1,
                perceptualPrecision: defaultPerceptualPrecision,
                traits: UITraitCollection(userInterfaceStyle: .dark)
            ),
            "accessibilityBig": .image(
                perceptualPrecision: defaultPerceptualPrecision,
                traits: UITraitCollection(preferredContentSizeCategory: .extraExtraExtraLarge)
            ),
            "accessibilitySmall": .image(
                perceptualPrecision: defaultPerceptualPrecision,
                traits: UITraitCollection(preferredContentSizeCategory: .extraSmall)
            ),
        ]
    }
}
