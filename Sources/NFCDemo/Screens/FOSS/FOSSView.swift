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

import SwiftUI
import WebKit

// Webview containing local html without javascript
struct FOSSView: View {
    var body: some View {
        WebView()
    }
}

extension FOSSView {
    struct WebView: UIViewRepresentable {
        // swiftlint:disable:next weak_delegate
        let navigationDelegate = DataPrivacyTermsOfUseNavigationDelegate()

        func makeUIView(context _: Context) -> WKWebView {
            let wkWebView = WKWebView()
            //  disabled javascript
            wkWebView.configuration.defaultWebpagePreferences.allowsContentJavaScript = false
            if let url = Bundle.main.url(forResource: "FOSS", withExtension: "html") {
                wkWebView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            }
            wkWebView.navigationDelegate = navigationDelegate
            return wkWebView
        }

        func updateUIView(_: WKWebView, context _: UIViewRepresentableContext<WebView>) {
            // this is a static html page - nothing needs to be updated
        }
    }
}

#Preview {
    FOSSView()
}
