//
//  Copyright (c) 2021 gematik GmbH
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

struct RegisterPINView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var can: String = ""
    @State var pin: String = ""
    @ObservedObject var keyboardHeight = KeyboardHeight()
    @State var buttonEnabled = false
    @ObservedObject var loginState = NFCLoginViewModel()
    @State var error: Swift.Error?
    @State private var showAlert = false
    @State var loading = false
    @State var loggedIn = false

    private func startLogin() {
        loginState.login(can: can, pin: pin)
    }

    var body: some View {
        ZStack {
            BackgroundView()
            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading) {
                        Text("onb_txt_sign_up_pin_intro")
                            .font(.system(size: 15))
                            .foregroundColor(Colors.lightText)
                            .padding(.vertical)
                            .accessibility(identifier: "onb_txt_sign_up_pin_intro")

                        VStack {
                            SecureField("onb_edt_sign_up_pin_enter_pin", text: self.$pin)
                                .foregroundColor(.black)
                                .keyboardType(.numberPad)
                                .disabled(self.loading)
                                .padding()
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Colors.grayBorder, lineWidth: 1))
                                .padding(20)
                                .accessibility(identifier: "onb_edt_sign_up_pin_enter_pin")
                            Button(action: self.startLogin) {
                                GTextButton(label: "onb_btn_connect", enabled: self.buttonEnabled && !self.loading)
                                    .padding(.horizontal, 30)
                                    .accessibility(identifier: "onb_btn_connect")
                            }.disabled(!self.buttonEnabled || self.loading)
                                .padding(.bottom, 20)
                        }
                        .background(LinearGradient(
                            gradient: Gradient(colors: [Color.white, Colors.secondary]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .cornerRadius(15)
                        .padding(.bottom)

                        Text("onb_txt_sign_up_pin_help")
                            .font(.system(size: 15))
                            .foregroundColor(Colors.lightText)
                            .padding(.vertical)
                            .accessibility(identifier: "onb_txt_sign_up_pin_help")

                        Text("onb_txt_sign_up_pin_explanation")
                            .font(.system(size: 15))
                            .lineSpacing(1.7)
                            .foregroundColor(Colors.lightText)
                            .accessibility(identifier: "onb_txt_sign_up_pin_explanation")

                        Spacer()
                    }.padding()
                }
                .frame(minWidth: geometry.size.width, minHeight: geometry.size.height, maxHeight: .infinity)
            }
            .padding(.bottom, self.keyboardHeight.height)
            .edgesIgnoringSafeArea(.bottom)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("alert_error_title"),
                message: Text(error?.localizedDescription ?? "alert_error_message_unknown"),
                dismissButton: .default(Text("alert_btn_ok")) {
                    self.loginState.dismissError()
                }
            )
        }
        .onReceive(Just(pin)) { number in
            // Enable/disable next button based on pin input
            self.buttonEnabled = number.count > 3
        }
        .onReceive(loginState.$state) { state in
            self.loading = state.isLoading
            if let success = state.value {
                self.loggedIn = success
            }
            self.error = state.error
            self.showAlert = state.error != nil
        }
        .navigationBarTitle("onb_txt_title_sign_up", displayMode: .inline)
    }
}

#if DEBUG
struct RegisterPINView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterPINView(can: "1234")
    }
}
#endif
