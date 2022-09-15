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

struct ChangeReferenceDataSetNewPINView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var can: String = ""
    @State var showStartNFCView = false
    @State var oldPin: String = ""
    @State var newPin: String = ""
    @ObservedObject var keyboardHeight = KeyboardHeight()
    var buttonEnabled: Bool {
        newPin.count >= 5 && newPin.count <= 6 && oldPin.count > 5 && oldPin.count <= 6
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Section(header: HeaderView()) {
                VStack(spacing: 20) {
                    SecureField("change_edt_enter_old_pin", text: $oldPin)
                        .keyboardType(.numberPad)
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Colors.grayBorder, lineWidth: 1))
                        .accessibility(identifier: "change_edt_enter_old_pin")

                    SecureField("change_edt_enter_new_pin", text: $newPin)
                        .keyboardType(.numberPad)
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Colors.grayBorder, lineWidth: 1))
                        .accessibility(identifier: "change_edt_enter_new_pin")

                    Button {
                        UIApplication.shared.dismissKeyboard()
                        showStartNFCView = true
                    } label: {
                        GTextButton(label: "change_btn_next", enabled: buttonEnabled)
                            .accessibility(identifier: "change_btn_next")
                            .disabled(!buttonEnabled)
                    }
                    .disabled(!buttonEnabled)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal)
        .background(Color(.secondarySystemBackground).ignoresSafeArea())
        .padding(.bottom, keyboardHeight.height)
        .edgesIgnoringSafeArea(.bottom)
        .navigationTitle("change_txt_title")
        .fullScreenCover(
            isPresented: $showStartNFCView,
            onDismiss: { showStartNFCView = false },
            content: {
                NavigationView {
                    StartNFCView(
                        can: can,
                        puk: "",
                        oldPin: oldPin,
                        pin: newPin,
                        useCase: .changeReferenceDataSetNewPin
                    )
                }
            }
        )
    }

    struct HeaderView: View {
        var body: some View {
            HStack {
                Text("change_txt_intro")
                    .font(.subheadline)
                    .accessibility(identifier: "change_txt_intro")
                Spacer()
            }.padding(.vertical)
        }
    }
}

#if DEBUG
struct ChangeReferenceDataSetNewPIN_Previews: PreviewProvider {
    static var previews: some View {
        ChangeReferenceDataSetNewPINView(
            can: "1234"
        )
    }
}
#endif
