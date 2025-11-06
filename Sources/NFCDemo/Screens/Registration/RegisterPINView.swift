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

import Combine
import Foundation
import SwiftUI

struct RegisterPINView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var can: String = ""
    @State var showStartNFCView = false
    #if DEBUG
    @AppStorage("pin") var storedPin: String = ""
    #else
    @State var storedPin: String = ""
    #endif
    @ObservedObject var keyboardHeight = KeyboardHeight()
    var buttonEnabled: Bool {
        storedPin.count > 3 && storedPin.count <= 12
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Section(header: HeaderView(), footer: FooterView()) {
                VStack(spacing: 20) {
                    SecureField("pin_edt_enter_pin", text: $storedPin)
                        .keyboardType(.numberPad)
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Colors.grayBorder, lineWidth: 1))
                        .accessibility(identifier: "pin_edt_enter_pin")

                    Button {
                        UIApplication.shared.dismissKeyboard()
                        showStartNFCView = true
                    } label: {
                        GTextButton(label: "pin_btn_next", enabled: self.buttonEnabled)
                            .accessibility(identifier: "pin_btn_next")
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
        .navigationTitle("pin_txt_title")
        .fullScreenCover(isPresented: $showStartNFCView,
                         onDismiss: {
                             showStartNFCView = false
                         }, content: {
                             NavigationView {
                                 StartNFCView(can: can, puk: "", oldPin: "", pin: storedPin, useCase: .signingFunction)
                             }
                         })
    }

    struct HeaderView: View {
        var body: some View {
            HStack {
                Text("pin_txt_intro")
                    .font(.subheadline)
                    .accessibility(identifier: "pin_txt_intro")
                Spacer()
            }.padding(.vertical)
        }
    }

    struct FooterView: View {
        var body: some View {
            VStack(alignment: .leading) {
                Text("pin_txt_help")
                    .font(.subheadline)
                    .padding(.vertical, 4)
                    .accessibility(identifier: "pin_txt_help")

                Text("pin_txt_explanation")
                    .font(.footnote)
                    .accessibility(identifier: "pin_txt_explanation")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#if DEBUG
struct RegisterPINView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterPINView(
            can: "1234"
        )
    }
}
#endif
