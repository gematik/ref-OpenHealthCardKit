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

struct ReadPersonalDataView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var can: String = ""
    @State var showStartNFCView = false

    @StateObject var readPersonalDataState = NFCReadPersonalDataViewModel()

    @State var state: ViewState<PersonalData, Error> = .idle

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Section(header: HeaderView()) {
                VStack(spacing: 20) {
                    if let personalData = readPersonalDataState.state.value {
                        LabeledContent("pd_lbl_name", value: personalData.name)
                            .accessibilityIdentifier("pd_lbl_name")
                        LabeledContent("pd_lbl_first_name", value: personalData.firstName)
                            .accessibilityIdentifier("pd_lbl_first_name")
                        LabeledContent("pd_lbl_address", value: personalData.address)
                            .accessibilityIdentifier("pd_lbl_address")
                        LabeledContent("pd_lbl_insurance_number", value: personalData.insuranceNumber)
                            .accessibilityIdentifier("pd_lbl_insurance_number")
                    }

                    Button {
                        showStartNFCView = true
                    } label: {
                        GTextButton(label: "pd_btn_next")
                            .accessibilityIdentifier("pd_btn_next")
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal)
        .background(Color(.secondarySystemBackground).ignoresSafeArea())
        .edgesIgnoringSafeArea(.bottom)
        .navigationTitle("pd_txt_title")
        .fullScreenCover(
            isPresented: $showStartNFCView,
            onDismiss: {
                showStartNFCView = false
            },
            content: {
                NavigationView {
                    StartNFCView(can: can, puk: "", oldPin: "", pin: "", useCase: .readPersonalData)
                        .environment(readPersonalDataState)
                }
            }
        )
    }

    struct HeaderView: View {
        var body: some View {
            HStack {
                Text("pd_txt_intro")
                    .font(.subheadline)
                    .accessibilityIdentifier("pd_txt_intro")
                Spacer()
            }.padding(.vertical)
        }
    }
}

#if DEBUG
struct ReadPersonalDataView_Previews: PreviewProvider {
    static var previews: some View {
        ReadPersonalDataView(
            can: "1234"
        )
    }
}
#endif
