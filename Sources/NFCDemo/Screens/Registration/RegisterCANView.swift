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

struct RegisterCANView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var can = WrappedObservableObject("")
    @State var buttonEnabled = false
    @ObservedObject var keyboardHeight = KeyboardHeight()

    var canTextInput: Binding<String> {
        Binding(get: { self.can.value }, set: {
            if $0.isDigitsOnly {
                self.can.value = $0
            } else {
                self.can.value = self.can.value
            }
        })
    }

    var body: some View {
        ZStack {
            BackgroundView()
            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading) {
                        Text("onb_txt_sign_up_can_intro")
                            .font(.system(size: 15))
                            .foregroundColor(Colors.lightText)
                            .padding(.vertical)
                            .accessibility(identifier: "onb_txt_sign_up_can_intro")

                        VStack {
                            TextField("onb_edt_sign_up_can_enter_can", text: self.canTextInput)
                                .foregroundColor(.black)
                                .keyboardType(.numberPad)
                                .padding()
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Colors.grayBorder, lineWidth: 1))
                                .padding(20)
                                .accessibility(identifier: "onb_edt_sign_up_can_enter_can")
                            NavigationLink(destination: RegisterPINView(can: self.can.value)) {
                                GTextButton(label: "onb_btn_next", enabled: self.buttonEnabled)
                                    .padding(.horizontal, 30)
                                    .accessibility(identifier: "onb_btn_next")
                            }
                            .disabled(!self.buttonEnabled)
                            .padding(.bottom, 20)
                        }
                        .background(LinearGradient(
                            gradient: Gradient(colors: [Color.white, Colors.secondary]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .cornerRadius(15)
                        .padding(.bottom)

                        Text("onb_txt_sign_up_can_help")
                            .font(.system(size: 15))
                            .foregroundColor(Colors.lightText)
                            .padding(.vertical)
                            .accessibility(identifier: "onb_txt_sign_up_can_help")

                        Image(decorative: "find_can")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(15)

                        Text("onb_txt_sign_up_can_help_explanation")
                            .font(.system(size: 15))
                            .lineSpacing(1.7)
                            .foregroundColor(Colors.lightText)
                            .accessibility(identifier: "onb_txt_sign_up_can_help_explanation")

                        Spacer()
                    }.padding()
                }
                .frame(minWidth: geometry.size.width, minHeight: geometry.size.height, maxHeight: .infinity)
            }
            .padding(.bottom, self.keyboardHeight.height)
            .edgesIgnoringSafeArea(.bottom)
        }
        .onReceive(self.can.$value) { number in
            // Enable/disable next button based on can input
            self.buttonEnabled = number.count > 5
        }
        .navigationBarTitle("onb_txt_title_sign_up", displayMode: .inline)
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
