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

import Combine
import Foundation
import SwiftUI

struct RegisterCANView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var buttonEnabled: Bool {
        storedCan.count > 5 ? true : false
    }

    @ObservedObject var keyboardHeight = KeyboardHeight()
    @AppStorage("can") var storedCan: String = ""

    var canTextInput: Binding<String> {
        Binding(
            get: { storedCan },
            set: {
                if $0.allSatisfy(Set("0123456789").contains) {
                    storedCan = $0
                } else {
                    storedCan = storedCan
                }
            }
        )
    }

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading) {
                    Text("can_txt_can_intro")
                        .font(.subheadline)
                        .padding(.vertical)
                        .accessibility(identifier: "can_txt_can_intro")

                    VStack(spacing: 20) {
                        TextField("can_edt_can_enter_can", text: self.canTextInput)
                            .keyboardType(.numberPad)
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Colors.grayBorder, lineWidth: 1))
                            .accessibility(identifier: "can_edt_can_enter_can")

                        NavigationLink(destination: ResetRetryCounterView(can: storedCan)) {
                            GTextButton(label: "can_btn_next_reset_pin", enabled: buttonEnabled)
                                .accessibility(identifier: "can_btn_next_reset_pin")
                        }
                        .disabled(!buttonEnabled)

                        NavigationLink(destination: ChangeReferenceDataSetNewPINView(can: storedCan)) {
                            GTextButton(label: "can_btn_next_reset_pin_with_new_pin", enabled: buttonEnabled)
                                .accessibility(identifier: "can_btn_next_reset_pin_with_new_pin")
                        }
                        .disabled(!buttonEnabled)

                        NavigationLink(destination: RegisterPINView(can: storedCan)) {
                            GTextButton(label: "can_btn_next_login_test", enabled: buttonEnabled)
                                .accessibility(identifier: "can_btn_next_login_test")
                        }
                        .disabled(!buttonEnabled)
                    }

                    Text("can_txt_help_title")
                        .font(.subheadline)
                        .padding(.vertical)
                        .accessibility(identifier: "can_txt_help_title")

                    Image(decorative: "find_can")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(15)

                    Text("can_txt_help_explanation")
                        .font(.footnote)
                        .accessibility(identifier: "can_txt_help_explanation")

                    Spacer()
                }
            }
            .padding(.horizontal)
            .background(Color(.secondarySystemBackground).ignoresSafeArea())
            .padding(.bottom, self.keyboardHeight.height)
            .edgesIgnoringSafeArea(.bottom)
            .navigationTitle("can_txt_title")
        }
    }
}

class WrappedObservableObject<T>: ObservableObject {
    @Published var value: T

    init(_ value: T) {
        self.value = value
    }
}

#if DEBUG
struct RegisterCANView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterCANView()
    }
}
#endif
