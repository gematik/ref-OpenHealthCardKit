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

import CardReaderProviderApi
@testable import HealthCardAccess
import Nimble
import XCTest

final class HealthCardResponseTest: XCTestCase {

    func testHealthCardResponse_OK() {
        guard let ok9000 = try? APDU.Response(apdu: Data([0x90, 0x0])) else {
            Nimble.fail("Could not create APDU response")
            return
        }

        let hcResponse = HealthCardResponse(response: ok9000, responseStatus: .success)
        expect(hcResponse.responseStatus).to(equal(ResponseStatus.success))
        expect(hcResponse.sw).to(equal(0x9000))
        expect(hcResponse.data).to(beNil())
    }

    static let allTests = [
        ("testHealthCardResponse_OK", testHealthCardResponse_OK)
    ]
}
