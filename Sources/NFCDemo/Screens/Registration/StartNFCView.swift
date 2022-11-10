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

struct StartNFCView: View {
    let can: String
    let puk: String
    let oldPin: String
    let pin: String
    let useCase: UseCase
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @StateObject var loginState = NFCLoginViewModel()
    @StateObject var resetRetryCounterState = NFCResetRetryCounterViewModel()
    @StateObject var changeReferenceDataState = NFCChangeReferenceDataViewModel()
    @State var error: Swift.Error?
    @State private var showAlert = false
    @State var loading = false
    @State var loggedIn = false
    @State var checkBrainpoolAlgorithm = false

    var readingResults: [ReadingResult] {
        (loginState.results + resetRetryCounterState.results + changeReferenceDataState.results)
            .sorted { $0.timestamp > $1.timestamp }
    }

    static let height: CGFloat = {
        // Compensate display scaling (Settings -> Display & Brightness -> Display -> Standard vs. Zoomed
        180 * UIScreen.main.scale / UIScreen.main.nativeScale
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Use overlay to also fill safe area but specify fixed height

            VStack {}
                .frame(width: nil, height: Self.height, alignment: .top)
                .overlay(
                    HStack {
                        Image("OnScreenEgk")
                            .scaledToFill()
                            .frame(width: nil, height: Self.height, alignment: .bottom)
                    }
                )

            Line()
                .stroke(style: StrokeStyle(lineWidth: 2,
                                           lineCap: CoreGraphics.CGLineCap.round,
                                           lineJoin: CoreGraphics.CGLineJoin.round,
                                           miterLimit: 2,
                                           dash: [8, 8],
                                           dashPhase: 0))
                .foregroundColor(Color(.opaqueSeparator))
                .frame(width: nil, height: 2, alignment: .center)

            Text("nfc_txt_placement")
                .font(.subheadline.bold())
                .foregroundColor(Color(.secondaryLabel))
                .padding(8)
                .padding(.bottom, 16)

            Text("nfc_txt_placement_hint")
                .font(.headline.bold())
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding()
                .fixedSize(horizontal: false, vertical: true)

            #if DEBUG
            if useCase == .login {
                Toggle("Check for brainpool algorithm", isOn: $checkBrainpoolAlgorithm).padding()
            }
            #endif
            Spacer(minLength: 0)

            NavigationLink(
                "nfc_btn_reading_results",
                destination: ReadingResultsView(readingResults: readingResults)
            )
            .padding()
            .disabled(readingResults.isEmpty)

            Divider()

            Button {
                switch useCase {
                case .login: loginState.login(can: can, pin: pin, checkBrainpoolAlgorithm: checkBrainpoolAlgorithm)
                case .resetRetryCounter: resetRetryCounterState.resetRetryCounter(can: can, puk: puk)
                case .resetRetryCounterWithNewPin: resetRetryCounterState
                    .resetRetryCounterWithNewPin(can: can, puk: puk, newPin: pin)
                case .changeReferenceDataSetNewPin: changeReferenceDataState
                    .changeReferenceDataSetNewPin(can: can, oldPin: oldPin, newPin: pin)
                }

            } label: {
                Label {
                    Text("nfc_btn_start_nfc")
                        .fontWeight(.semibold)
                } icon: {
                    if loading {
                        ProgressView().progressViewStyle(CircularProgressViewStyle())
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 22)
                .padding(10)
                .foregroundColor(Color.white)
                .background(Colors.buttonGreen)
                .cornerRadius(20)
                .padding(.horizontal)
            }
            .disabled(self.loading)
            .padding(.vertical)

            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Label(title: { Text("nfc_btn_cancel").foregroundColor(Color.secondary) }, icon: {})
            })
                .padding(.bottom)
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("alert_error_title"),
                message: Text(error?.localizedDescription ?? "alert_error_message_unknown"),
                dismissButton: .default(Text("alert_btn_ok")) {
                    self.loginState.dismissError()
                }
            )
        }
        .onReceive(loginState.$state) { state in
            self.loading = state.isLoading
            if let success = state.value {
                self.loggedIn = success
            }
            self.error = state.error
            self.showAlert = state.error != nil
        }
    }

    struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: rect.height * 0.5))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.5))
            return path
        }
    }

    enum UseCase {
        case login
        case resetRetryCounter
        case resetRetryCounterWithNewPin // do not use this for solely setting a new PIN value
        case changeReferenceDataSetNewPin
    }
}

#if DEBUG
struct StartNFCView_Previews: PreviewProvider {
    static var previews: some View {
        StartNFCView(
            can: "123456",
            puk: "",
            oldPin: "123456",
            pin: "123456",
            useCase: .login
        )
    }
}
#endif
