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

import Combine
import Foundation
import SwiftUI

struct ResetRetryCounterView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var can: String = ""
    @State var showStartNFCView = false
    #if DEBUG
    @AppStorage("puk") var puk: String = ""
    #else
    @State var puk: String = ""
    #endif
    @ObservedObject var keyboardHeight = KeyboardHeight()
    var buttonEnabled: Bool {
        puk.count > 5 && puk.count <= 10
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Section(header: HeaderView(), footer: FooterView()) {
                VStack(spacing: 20) {
                    SecureField("reset_edt_enter_puk", text: $puk)
                        .keyboardType(.numberPad)
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Colors.grayBorder, lineWidth: 1))
                        .accessibility(identifier: "reset_edt_enter_puk")

                    Button {
                        UIApplication.shared.dismissKeyboard()
                        showStartNFCView = true
                    } label: {
                        GTextButton(label: "reset_btn_next", enabled: self.buttonEnabled)
                            .accessibility(identifier: "reset_btn_next")
                            .disabled(!buttonEnabled)
                    }
                    .disabled(!buttonEnabled)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal)
        .background(Color(.secondarySystemBackground).ignoresSafeArea())
        .padding(.bottom, self.keyboardHeight.height)
        .edgesIgnoringSafeArea(.bottom)
        .navigationTitle("Karte entsperren")
        .fullScreenCover(
            isPresented: $showStartNFCView,
            onDismiss: {
                showStartNFCView = false
            }, content: {
                NavigationView {
                    StartNFCView(can: can, puk: puk, pin: "", useCase: .resetRetryCounter)
                }
            }
        )
    }

    struct HeaderView: View {
        var body: some View {
            HStack {
                Text("Authorisieren Sie sich mit Ihrer PUK")
                    .font(.subheadline)
                    .accessibility(identifier: "Authorisieren Sie sich mit Ihrer PUK")
                Spacer()
            }.padding(.vertical)
        }
    }

    struct FooterView: View {
        var body: some View {
            VStack(alignment: .leading) {
                Text("reset_txt_help")
                    .font(.subheadline)
                    .padding(.vertical, 4)
                    .accessibility(identifier: "reset_txt_help")

                Text("reset_txt_explanation")
                    .font(.footnote)
                    .accessibility(identifier: "reset_txt_explanation")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#if DEBUG
struct ResetRetryCounterView_Previews: PreviewProvider {
    static var previews: some View {
        ResetRetryCounterWithNewPINView(
            can: "1234"
        )
    }
}
#endif