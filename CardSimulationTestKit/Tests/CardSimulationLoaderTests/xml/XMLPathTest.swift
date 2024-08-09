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

import AEXML
@testable import CardSimulationLoader
import Nimble
import OSLog
import XCTest

final class XMLPathTest: XCTestCase {
    static var soapRequest: AEXMLDocument!

    var soapRequest: AEXMLDocument! {
        XMLPathTest.soapRequest
    }

    override class func setUp() {
        super.setUp()

        do {
            let xmlData = try Bundle(for: XMLPathTest.self)
                .testResourceFilePath(in: "Resources", for: "soapRequest.xml")
                .readFileContents()
            soapRequest = try AEXMLDocument(xml: xmlData)
        } catch {
            Nimble.fail("Error in setup XMLPathTest")
        }
    }

    func testXMLPath() {
        let path: XMLPath = "configuration.node.element"
        expect(path.components).to(equal(["configuration", "node", "element"]))
    }

    func testAEXMLDocument_resolve_path() {
        let path: XMLPath = "soap:Envelope.soap:Header.m:Trans"
        expect(self.soapRequest.resolve(path: path)?.value).to(equal("234"))
        expect(self.soapRequest.resolve(path: "soap:Header.m:Trans")).to(beNil())
        expect(self.soapRequest.resolve(path: "configuration.non.existing")).to(beNil())
    }

    func testAEXMLDocument_resolve_path_element_at_index() {
        /// Test fetching child elements by index
        let bodyPath: XMLPath = "soap:Envelope.soap:Body.m:GetStockPrice.m:StockName"
        expect(self.soapRequest.resolve(path: bodyPath)?.value).to(equal("AAPL"))
        let bodyPathIndex1: XMLPath = "soap:Envelope.soap:Body.m:GetStockPrice[1].m:StockName"
        let googelement = soapRequest.resolve(path: bodyPathIndex1)
        expect(googelement?.value).to(equal("GOOG"))
    }

    func testAEXMLDocument_resolve_path_element_with_attribute() {
        let bodyPathAttribute: XMLPath = "soap:Envelope.soap:Body.m:GetStockPrice{attribute:attr_value}.m:StockName"
        let element = soapRequest.resolve(path: bodyPathAttribute)
        expect(element?.value).to(equal("ATTR"))
    }

    func testAEXMLDocument_replace_path() {
        /// Load document per test-case since the test will modify its contents
        do {
            let xmlData = try Bundle(for: XMLPathTest.self)
                .testResourceFilePath(in: "Resources", for: "soapRequest.xml")
                .readFileContents()

            let xmlDoc = try AEXMLDocument(xml: xmlData)
            let xmlPath: XMLPath = "soap:Envelope.soap:Header.m:Trans"
            let elementBefore = xmlDoc.resolve(path: xmlPath)
            expect(elementBefore).toNot(beNil())
            let element = AEXMLElement(name: "ReplacedElement", value: "WithValue", attributes: [:])
            expect(xmlDoc.replace(path: xmlPath, with: element)).to(beTrue())
            expect(xmlDoc.resolve(path: xmlPath)).to(beNil())
            let elementAfter = xmlDoc.resolve(path: "soap:Envelope.soap:Header.ReplacedElement")
            expect(elementAfter?.xml).to(equal(element.xml))
            expect(elementAfter?.xml).toNot(equal(elementBefore?.xml))
        } catch {
            Logger.cardSimulationLoaderTests.fault("Test-case failed with exception: [\(error)]")
            Nimble.fail("Failed with error \(error)")
        }
    }

    func testAEXMLDocument_replace_path_when_not_found() {
        let xmlPath: XMLPath = "soap:Envelope.soap:NoHeader.m:NoTrans"
        let elementBefore = soapRequest.resolve(path: xmlPath)
        expect(elementBefore).to(beNil())
        let element = AEXMLElement(name: "ReplacedElement", value: "WithValue", attributes: [:])
        expect(self.soapRequest.replace(path: xmlPath, with: element)).to(beFalse())
        let elementAfter = soapRequest.resolve(path: xmlPath)
        expect(elementAfter).to(beNil())
    }

    func testAEXMLDocument_replace_path_root_should_fail() {
        let xmlPath: XMLPath = "soap:Envelope"
        let elementBefore = soapRequest.resolve(path: xmlPath)
        expect(elementBefore).toNot(beNil())
        let element = AEXMLElement(name: "ReplacedElement", value: "WithValue", attributes: [:])
        expect(self.soapRequest.replace(path: xmlPath, with: element)).to(beFalse())
        let elementAfter = soapRequest.resolve(path: xmlPath)
        expect(elementBefore?.xml).to(equal(elementAfter?.xml))
    }

    static var allTests = [
        ("testXMLPath", testXMLPath),
        ("testAEXMLDocument_resolve_path", testAEXMLDocument_resolve_path),
        ("testAEXMLDocument_resolve_path_element_with_attribute",
         testAEXMLDocument_resolve_path_element_with_attribute),
        ("testAEXMLDocument_resolve_path_element_at_index", testAEXMLDocument_resolve_path_element_at_index),
        ("testAEXMLDocument_replace_path_root_should_fail", testAEXMLDocument_replace_path_root_should_fail),
        ("testAEXMLDocument_replace_path_when_not_found", testAEXMLDocument_replace_path_when_not_found),
        ("testAEXMLDocument_replace_path", testAEXMLDocument_replace_path),
    ]
}
