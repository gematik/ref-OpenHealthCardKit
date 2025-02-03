//
//  Copyright (c) 2025 gematik GmbH
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
@preconcurrency import WebKit

// Delegate disables unused schemes
class DataPrivacyTermsOfUseNavigationDelegate: NSObject, WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 preferences _: WKWebpagePreferences,
                 decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        if let url = navigationAction.request.url {
            if url.scheme?.lowercased() == "file" {
                decisionHandler(.allow, webView.configuration.defaultWebpagePreferences)
                return
            } else if url.scheme?.lowercased() == "https" {
                UIApplication.shared.open(url)
            }
        }
        decisionHandler(.cancel, webView.configuration.defaultWebpagePreferences)
    }
}
