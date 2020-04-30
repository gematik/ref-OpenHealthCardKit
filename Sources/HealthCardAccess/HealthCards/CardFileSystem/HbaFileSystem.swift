//
//  Copyright (c) 2020 gematik GmbH
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//     http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

/// Card File system layout for HBA smart-cards
public struct HbaFileSystem {
    // To-do

    private init() {}

    /// Elementary File identifier
    public struct EF { //swiftlint:disable:this type_name
        private init() {}

        /// MF/EF.ATR: Transparent Elementary File - Answer to reset
        public static let atr = ElementaryFile(fid: "2F01", sfid: "1D")
        /// MF/EF.CardAccess
        public static let cardAccess = ElementaryFile(fid: "011C", sfid: "1C")
        /// MF/EF.DIR: Linear variable Elementary File - list application templates
        public static let dir = ElementaryFile(fid: "2F00", sfid: "1E")
        /// MF/EF.GDO: Transparent Elementary File
        public static let gdo = ElementaryFile(fid: "2F02", sfid: "02")
        /// MF/EF.VERSION2
        public static let version2 = ElementaryFile(fid: "2F11", sfid: "11")
    }

    /// Dedicated File Identifier
    public struct DF { //swiftlint:disable:this type_name
        private init() {}

        /// MF (root)
        public static let MF = DedicatedFile(aid: "D27600014601", fid: "3F00")//swiftlint:disable:this identifier_name
        /// MF/DF.HPA
        public static let HPA = DedicatedFile(aid: "D27600014602")
        /// MF/DF.QES
        public static let QES = DedicatedFile(aid: "D27600006601")
        /// MF/DF.ESIGN
        public static let ESIGN = DedicatedFile(aid: "A000000167455349474E")
        /// MF/DF.CIA.QES
        public static let CIAQES = DedicatedFile(aid: "'E828BD080FD27600006601")
        /// MF/DF.CIA.ESIGN
        public static let CIAESIGN = DedicatedFile(aid: "'E828BD080FA000000167455349474E")
        /// MF/DF.AUTO
        public static let AUTO = DedicatedFile(aid: "D27600014603")
    }
}
