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

import CardReaderProviderApi
import CardSimulationLoader
import Foundation

public class SimulatorCardReaderProvider: NSObject, CardReaderProviderType {
    public static let name = "cardsim"

    public static let descriptor: ProviderDescriptorType = ProviderDescriptor(
        SimulatorCardReaderProvider.name,
        "(c) Gematik 2019",
        "TCP channel Card Reader Provider for the G2-Kartensimulator.",
        "G2-Kartensimulator CRP",
        "CardSimulationCardReaderProvider.SimulatorCardTerminalControllerProvider"
    )

    public class func provideCardReaderController() -> CardReaderControllerObjcWrapper {
        let controller = SimulatorCardReaderController(manager: SimulationManager.shared)
        return CardReaderControllerObjcWrapper(controller)
    }
}
