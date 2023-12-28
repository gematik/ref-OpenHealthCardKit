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

import Foundation
import Helper
import NFCCardReaderProvider
import SwiftUI

struct ReadingResultsView: View {
    let readingResults: [ReadingResult]

    var body: some View {
        List {
            ForEach(readingResults) { result in
                cell(for: result)
            }
        }
        .navigationTitle("nfc_btn_reading_results")
        .navigationBarTitleDisplayMode(.inline)
    }

    func cell(for result: ReadingResult) -> some View {
        NavigationLink(destination: { DetailView(result: result) }, label: {
            VStack(alignment: .leading) {
                HStack {
                    Text(result.timestamp, style: .date)
                    Text(result.timestamp, style: .time)
                    Spacer()
                }
                if let value = result.result.value {
                    Text("success: \(value == true ? "true" : "false")")
                }
                if let error = result.result.error {
                    Text("error: \(error.localizedDescription)")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .cornerRadius(15)
        })
    }

    struct DetailView: View {
        let result: ReadingResult
        @State var showShareSheet = false
        var body: some View {
            List {
                Section(header: Text("rdr_txt_sec_title_overview")) {
                    HStack {
                        Text("rdr_txt_date")
                            .font(Font.subheadline)
                        Text(result.timestamp, style: .date)
                        Text(result.timestamp, style: .time)
                        Spacer()
                    }

                    HStack {
                        Text("rdr_txt_result").font(Font.subheadline)
                        if let error = result.result.error {
                            Text(error.localizedDescription)
                        } else if let value = result.result.value {
                            Text("success: \(value == true ? "true" : "false")")
                        }
                    }
                }

                Section(header: Text("rdr_txt_sec_title_commands")) {
                    ForEach(result.commands) { command in
                        VStack(alignment: .leading) {
                            switch command.type {
                            case .send:
                                Text("SEND:").font(Font.subheadline)
                            case .sendSecureChannel:
                                Text("SEND: (decrypted header)").font(Font.subheadline)
                            case .response:
                                Text("RESPONSE:").font(Font.subheadline)
                            case .responseSecureChannel:
                                Text("RESPONSE: (decrypted)").font(Font.subheadline)
                            default:
                                EmptyView()
                            }

                            Text(command.message)
                                .font(command.type == .description ? Font
                                    .headline : .system(.body, design: .monospaced))
                                .contextMenu(ContextMenu {
                                    Button("rdr_btn_copy") {
                                        UIPasteboard.general.string = command.message
                                    }
                                })
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ActivityViewController(itemsToShare: [result.formattedDescription()])
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(
                        action: { showShareSheet = true },
                        label: { Image(systemName: "square.and.arrow.up") }
                    )
                }
            }
            .navigationTitle("rdr_txt_detail_title")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ReadingResultsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                ReadingResultsView(
                    readingResults: [
                        ReadingResult(result: ViewState.value(true), commands: []),
                        ReadingResult(
                            result: .error(NFCLoginController.Error.invalidCanOrPinFormat),
                            commands: [
                                Command(message: "Establish secure connection", type: .description),
                                Command(message: "00A4040CD2760001448000|ne:-1]", type: .send),
                                Command(message: "9000", type: .response),
                                Command(message: "Verify PIN", type: .description),
                            ]
                        ),
                    ]
                )
                .preferredColorScheme(.dark)
            }

            ReadingResultsView.DetailView(
                result: ReadingResult(
                    result: .error(NFCLoginController.Error.invalidCanOrPinFormat),
                    commands: [
                        Command(message: "Establish secure connection", type: .description),
                        Command(message: "00A4040CD2760001448000|ne:-1]", type: .send),
                        Command(message: "9000", type: .response),
                        Command(message: "Verify PIN", type: .description),
                    ]
                )
            )
            .preferredColorScheme(.dark)
        }
    }
}
