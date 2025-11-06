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

import Foundation
import Nimble
import XCTest

enum ResourceLoader {
    static func loadResource(
        resource name: String,
        withExtension: String? = nil,
        directory: String
    ) -> String {
        // First try to get the URL for the resource directly
        if let resourceURL = Bundle.module.url(
            forResource: name,
            withExtension: withExtension
        ) {
            return resourceURL.path
        }

        guard let resourceURL = Bundle.module.url(
            forResource: name,
            withExtension: withExtension,
            subdirectory: "Resources.bundle/\(directory)"
        ) else {
            print("Available resources in bundle: \(Bundle.module.paths(forResourcesOfType: "dat", inDirectory: nil))")
            fail("Bundle could not find resource \(name).dat in directory \(directory)")
            return ""
        }

        return resourceURL.path
    }

    static func loadResourceAsData(
        resource name: String,
        withExtension: String? = nil,
        directory: String
    ) -> Data {
        let resource = loadResource(
            resource: name,
            withExtension: withExtension,
            directory: directory
        )
        do {
            return try Data(contentsOf: URL(fileURLWithPath: resource))
        } catch {
            fail("Could not read resource \(name): \(error)")
            return Data()
        }
    }
}
