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

extension String {
    func loadAsResource(at path: String = "DSA", bundle: Bundle, bundleName: String = "Resources") -> Data {
        let filename = "\(path)/\(self)"
        let filePath = bundle.testResourceFilePath(in: bundleName, for: filename)
        guard let fileData = try? filePath.readFileContents() else {
            fatalError("Could not read: [\(filename)]")
        }
        return fileData
    }
}
