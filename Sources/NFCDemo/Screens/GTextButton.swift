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

import SwiftUI

struct GTextButton: View {
    var label: LocalizedStringKey
    var font: Font = .system(size: 16)
    var enabled = true

    @ViewBuilder
    var body: some View {
        if enabled {
            Text(label)
                .fontWeight(.semibold)
                .font(self.font)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 22)
                .padding(10)
                .foregroundColor(Color.white)
                .background(Colors.buttonGreen)
                .cornerRadius(20)
        } else {
            Text(label)
                .fontWeight(.semibold)
                .font(self.font)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 22)
                .padding(10)
                .foregroundColor(Colors.buttonGreen)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Colors.buttonGreen, lineWidth: 2)
                )
        }
    }
}

#if DEBUG
struct GTextButton_Previews: PreviewProvider {
    static var previews: some View {
        GTextButton(label: "G Text Button")
    }
}
#endif
