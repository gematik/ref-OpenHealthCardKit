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

@testable import CardReaderProviderApi
import Nimble
import XCTest

final class APDUResponseTest: XCTestCase {
    func testAPDUResponse_valid() throws {
        let responseMessage = [0xFE, 0x12, 0x34, 0x90, 0x00].data
        let response = try APDU.Response(apdu: responseMessage)

        expect(response.sw1).to(equal(0x90))
        expect(response.sw2).to(equal(0x0))
        expect(response.sw).to(equal(0x9000))
        expect(response.nr).to(equal(3))
        let expectedData = [0xFE, 0x12, 0x34].data
        expect(response.data).to(equal(expectedData))
    }

    func testAPDUResponse_valid_convenience_initializer() throws {
        let responseBody = [0xFE, 0x12, 0x34].data
        let response = try APDU.Response(body: responseBody, sw1: 0x90, sw2: 0x0)

        expect(response.sw1).to(equal(0x90))
        expect(response.sw2).to(equal(0x0))
        expect(response.sw).to(equal(0x9000))
        expect(response.nr).to(equal(3))
        let expectedData = [0xFE, 0x12, 0x34].data
        expect(response.data).to(equal(expectedData))
    }

    func testAPDUResponse_ok() throws {
        let responseMessage = [0x90, 0x00].data
        let response = try APDU.Response(apdu: responseMessage)

        expect(response.sw1).to(equal(0x90))
        expect(response.sw2).to(equal(0x0))
        expect(response.sw).to(equal(0x9000))

        expect(response.nr).to(equal(0))
        expect(response.data).to(beNil())
    }

    func testAPDUResponse_equality() throws {
        let responseMessage = [0x01, 0x02, 0x90, 0x00].data
        let response = try APDU.Response(apdu: responseMessage)
        let responseMessage2 = [0x01, 0x02, 0x90, 0x00].data
        let response2 = try APDU.Response(apdu: responseMessage2)
        let responseMessage3 = [0x03, 0x02, 0x90, 0x00].data
        let response3 = try APDU.Response(apdu: responseMessage3)
        expect(response == response2).to(beTrue())
        expect(response == response3).to(beFalse())
    }

    func testAPDUResponse_emptyData() {
        expect(try APDU.Response(apdu: Data.empty))
            .to(throwError(APDU.Error.insufficientResponseData(data: Data.empty)))
    }

    func testAPDUResponseException_insufficientResponseData() {
        let responseData = [0x01].data
        expect {
            try APDU.Response(apdu: responseData)
        }.to(throwError { (error: APDU.Error) in
            expect(error.data).to(equal(Data([0x1])))
        })
    }
}
