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

/// SimulationRunner state cases.
public enum SimulationProcessMode {
    /// Freshly created SimulationRunner that has not been used at all
    case notStarted
    /// Launched the process and is processing the initialization
    case initializing
    /// Process is successfully initialized and accessible through port number
    /// - Parameter onTCPPort: accessible through port number
    case running(onTCPPort: Int32)
    /// Process has been launched and terminated
    /// - Parameter terminationStatus: the process' termination status code
    case terminated(terminationStatus: Int32)
}

extension SimulationProcessMode: Equatable {
    // swiftlint:disable operator_whitespace
    public static func ==(lhs: SimulationProcessMode, rhs: SimulationProcessMode) -> Bool {
        switch lhs {
        case let .running(onTCPPort): return rhs.tlvPort == onTCPPort
        case .notStarted: return rhs.isNotRunning
        case .initializing: return rhs.isInitializing
        case let .terminated(terminationStatus): return rhs.terminationStatus == terminationStatus
        }
    }

    // swiftlint:enable operator_whitespace
}

extension SimulationProcessMode {
    /// true when `.terminated`
    public var isTerminated: Bool {
        if case .terminated = self {
            return true
        }
        return false
    }

    /// true when `.notStarted`
    public var isNotRunning: Bool {
        if case .notStarted = self {
            return true
        }
        return false
    }

    /// true when `.running`
    public var isRunning: Bool {
        if case .running = self {
            return true
        }
        return false
    }

    /// true when `.initializing`
    public var isInitializing: Bool {
        if case .initializing = self {
            return true
        }
        return false
    }

    /// when running the port number is returned else nil
    public var tlvPort: Int32? {
        switch self {
        case let .running(onTCPPort): return onTCPPort
        default: return nil
        }
    }

    /// when terminated the termination status code else nil
    public var terminationStatus: Int32? {
        switch self {
        case let .terminated(terminationStatus): return terminationStatus
        default: return nil
        }
    }
}

extension SimulationProcessMode: CustomDebugStringConvertible {
    /// Debug info
    public var debugDescription: String {
        description
    }
}

extension SimulationProcessMode: CustomStringConvertible {
    /// String-value
    public var description: String {
        switch self {
        case .notStarted: return "Not Started"
        case .initializing: return "Initializing"
        case let .running(port): return "Running on TCP: [\(port)]"
        case let .terminated(terminationStatus): return "Terminated (exit: [\(terminationStatus))]"
        }
    }
}
