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

import Foundation

/// Card File system layout for EGK smart-cards
public struct EgkFileSystem {
    private init() {}

    /// Elementary File identifier
    public struct EF { // swiftlint:disable:this type_name
        private init() {}

        /// MF/EF.ATR: Transparent Elementary File - Answer to reset
        public static let atr = ElementaryFile(fid: "2F01", sfid: "1D")
        /// MF/EF.CardAccess
        public static let cardAccess = ElementaryFile(fid: "011C", sfid: "1C")
        /// MF/EF.C.CA_eGK.CS.E256
        public static let cCaEgkCsE256 = ElementaryFile(fid: "2F07", sfid: "07")
        /// MF/EF.C.eGK.AUT_CVC.E256
        public static let cEgkAutCVCE256 = ElementaryFile(fid: "2F06", sfid: "06")
        /// MF/EF.DIR: Linear variable Elementary File - list application templates
        public static let dir = ElementaryFile(fid: "2F00", sfid: "1E")
        /// MF/EF.GDO: Transparent Elementary File
        public static let gdo = ElementaryFile(fid: "2F02", sfid: "02")
        /// MF/EF.VERSION
        public static let version = ElementaryFile(fid: "2F10", sfid: "10")
        /// MF/EF.VERSION2
        public static let version2 = ElementaryFile(fid: "2F11", sfid: "11")
        /// MF/DF.NFD.EF.NFD
        public static let nfd = ElementaryFile(fid: "D010", sfid: "10")
        /// MF/DF.HCA.EF.Einwilligung
        public static let hcaEinwilligung = ElementaryFile(fid: "D005", sfid: "05")
        /// MF/DF.HCA.EF.GVD
        public static let hcaGVD = ElementaryFile(fid: "D003", sfid: "03")
        /// MF/DF.HCA.EF.Logging
        public static let hcaLogging = ElementaryFile(fid: "D006", sfid: "06")
        /// MF/DF.HCA.EF.PD
        public static let hcaPD = ElementaryFile(fid: "D001", sfid: "01")
        /// MF/DF.HCA.EF.Prüfungsnachweis
        public static let hcaPruefungsnachweis = ElementaryFile(fid: "D01C", sfid: "1C")
        /// MF/DF.HCA.EF.Standalone
        public static let hcaStandalone = ElementaryFile(fid: "DA0A", sfid: "0A")
        /// MF/DF.HCA.EF.StatusVD
        public static let hcaStatusVD = ElementaryFile(fid: "D00C", sfid: "0C")
        /// MF/DF.HCA.EF.TTN
        public static let hcaTTN = ElementaryFile(fid: "D00F", sfid: "0F")
        /// MF/DF.HCA.EF.VD
        public static let hcaVD = ElementaryFile(fid: "D002", sfid: "02")
        /// MF/DF.HCA.EF.Verweis
        public static let hcaVerweis = ElementaryFile(fid: "D009", sfid: "09")
        /// MF/DF.ESIGN.EF.C.CH.AUT.R2048
        public static let esignCChAutR2048 = ElementaryFile(fid: "C500", sfid: "01")
        /// MF/DF.ESIGN.EF.C.CH.AUT.E256
        public static let esignCChAutE256 = ElementaryFile(fid: "C504", sfid: "04")
        /// MF/DF.ESIGN.EF.AUTN
        public static let esignCChAutnR2048 = ElementaryFile(fid: "C509", sfid: "09")
        /// MF/DF.ESIGN.EF.ENC
        public static let esignCChEncR2048 = ElementaryFile(fid: "C200", sfid: "02")
        /// MF/DF.ESIGN.EF.ENCV
        public static let esignCChEncvR2048 = ElementaryFile(fid: "C50A", sfid: "0A")
    }

    /// Dedicated File Identifier
    public struct DF { // swiftlint:disable:this type_name
        private init() {}

        /// MF (root)
        public static let MF = DedicatedFile(aid: "D2760001448000", // swiftlint:disable:this identifier_name
                                             fid: "3F00")
        /// MF/DF.HCA
        public static let HCA = DedicatedFile(aid: "D27699999192")
        /// MF/DF.ESIGN
        public static let ESIGN = DedicatedFile(aid: "A000000167455349474E")
        /// MF/DF.QES
        public static let QES = DedicatedFile(aid: "D27600006601")
        /// MF/DF.NFD
        public static let NFD = DedicatedFile(aid: "D27600014407")
        /// MF/DF.DPE
        public static let DPE = DedicatedFile(aid: "D27600014408")
        /// MF/DF.GDD
        public static let GDD = DedicatedFile(aid: "D2760001440A")
        /// MF/DF.OSE
        public static let OSE = DedicatedFile(aid: "D2760001440B")
        /// MF/DF.AMTS
        public static let AMTS = DedicatedFile(aid: "D2760001440C")
    }

    /// Pin
    public enum Pin: Password {
        /// PIN CH
        case pinCH
        /// MR.PIN.HOME
        case mrpinHome
        /// MR.PIN.NFD
        case mrpinNFD
        /// MR.PIN.NFD.READ
        case mrpinNFDREAD
        /// MR.PIN.DPE
        case mrpinDPE
        /// MR.PIN.DPEREAD
        case mrpinDPEREAD
        /// MR.PIN.GDD
        case mprinGDD
        /// MR.PIN.OSE
        case mrpinOSE
        /// MR.PIN.AMTS
        case mrpinAMTS
        /// MR.PIN.AMTSREP
        case pinAMTSREP
        /// MR.PIN.QES
        case pinQES

        public var rawValue: Password {
            switch self {
            case .pinCH: return "01"
            case .mrpinHome: return "02"
            case .mrpinNFD: return "03"
            case .mrpinNFDREAD: return "07"
            case .mrpinDPE: return "04"
            case .mrpinDPEREAD: return "08"
            case .mprinGDD: return "05"
            case .mrpinOSE: return "09"
            case .mrpinAMTS: return "0C"
            case .pinAMTSREP: return "0D"
            case .pinQES: return "01"
            }
        }
    }
}
