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

import ASN1Kit
import CardReaderProviderApi
import Foundation
import Security

/// Builder to assemble an instance of `HealthCardCommand` which is holding a `CommandType`
/// and a dictionary responseStatuses [UInt16: ResponseStatus].
/// - Note: This builder is extended by static convenience functions which provide fully configured
/// instances of `HealthCardCommandBuilder` for their respective use cases (e.g. Select, Activate, ...)
///
/// ### Usage Example: ###
///
/// ````
/// let hcc: HealthCardCommand = try HealthCardCommandBuilder.Erase.eraseFileCommand().build()
/// ````
public class HealthCardCommandBuilder {
    // swiftlint:disable identifier_name
    private var cla: UInt8
    private var ins: UInt8
    private var p1: UInt8
    private var p2: UInt8
    private var data: Data?
    private var ne: Int?
    private var responseStatuses: [UInt16: ResponseStatus]

    /// Constructor of this builder containing all parameters.
    public init(cla: UInt8,
                ins: UInt8,
                p1: UInt8,
                p2: UInt8,
                data: Data? = nil,
                ne: Int? = nil,
                responseStatuses: [UInt16: ResponseStatus]) {
        self.cla = cla
        self.ins = ins
        self.p1 = p1
        self.p2 = p2
        self.data = data
        self.ne = ne
        self.responseStatuses = responseStatuses
    }

    // swiftlint:enable identifier_name

    /// Convenience constructor initializing this class with some default values to be overwritten.
    public convenience init() {
        self.init(cla: 0x0, ins: 0x0, p1: 0x0, p2: 0x0, responseStatuses: [:])
    }

    /// Constructs a `HealthCardCommand` from this builder instance.
    /// Returns: `HealthCardCommand`
    public func build() throws -> HealthCardCommand {
        let command = try APDU.Command(cla: cla, ins: ins, p1: p1, p2: p2, data: data, ne: ne)

        return HealthCardCommand(apduCommand: command, responseStatuses: responseStatuses)
    }

    /// Deconstruct(s) a given `HealthCardCommand` back into a builder.
    /// Parameter:
    ///     - healthCardCommand: the `HealthCardCommand` the `HealthCardCommandBuilder` will copy the parameters from
    /// Returns: `HealthCardCommandBuilder` holding the properties of the given `HealthCardCommand`
    public static func builder(from healthCardCommand: HealthCardCommand) -> HealthCardCommandBuilder {
        HealthCardCommandBuilder()
            .set(cla: healthCardCommand.cla)
            .set(ins: healthCardCommand.ins)
            .set(p1: healthCardCommand.p1)
            .set(p2: healthCardCommand.p2)
            .set(data: healthCardCommand.data)
            .set(ne: healthCardCommand.ne)
            .set(responseStatuses: healthCardCommand.responseStatuses)
    }

    /// Returns a `HealthCardCommandBuilder` with *cla* set.
    public func set(cla: UInt8) -> HealthCardCommandBuilder {
        self.cla = cla
        return self
    }

    /// Returns a `HealthCardCommandBuilder` with *ins* set.
    public func set(ins: UInt8) -> HealthCardCommandBuilder {
        self.ins = ins
        return self
    }

    // swiftlint:disable identifier_name
    /// Returns a `HealthCardCommandBuilder` with *p1* set.
    public func set(p1: UInt8) -> HealthCardCommandBuilder {
        self.p1 = p1
        return self
    }

    /// Returns a `HealthCardCommandBuilder` with *p2* set.
    public func set(p2: UInt8) -> HealthCardCommandBuilder {
        self.p2 = p2
        return self
    }

    /// Returns a `HealthCardCommandBuilder` with *data* set.
    public func set(data: Data?) -> HealthCardCommandBuilder {
        self.data = data
        return self
    }

    /// Returns a `HealthCardCommandBuilder` with *data* appended to existing data.
    public func add(data: Data) -> HealthCardCommandBuilder {
        if let oldData = self.data {
            self.data = oldData + data
        } else {
            self.data = data
        }
        return self
    }

    /// Returns a `HealthCardCommandBuilder` with *ne* set.
    public func set(ne: Int?) -> HealthCardCommandBuilder {
        self.ne = ne
        return self
    }

    // swiftlint:enable identifier_name

    /// Returns a `HealthCardCommandBuilder` with *responseStatuses* set.
    public func set(responseStatuses: [UInt16: ResponseStatus]) -> HealthCardCommandBuilder {
        self.responseStatuses = responseStatuses
        return self
    }
}

extension HealthCardCommandBuilder {
    /// Marker for setting the first bit (i.e. **0x80**) when working with `ShortFileIdentifier`
    public static let sfidMarker: UInt8 = 0x80

    public enum InvalidArgument: Swift.Error, Equatable {
        case offsetOutOfBounds(Int, usingShortFileIdentifier: Bool)
        case recordDataSizeOutOfBounds(Data)
        case expectedLengthMustNotBeZero
        case expectedLengthNotAWildcardValue(Int)
        case wrongMACLength(Int)
        case wrongHashLength(Int, expected: Int)
        case wrongSignatureLength(Int, expected: Int)
        case unsupportedKey(SecKey)
        case illegalSize(Int, expected: Int)
        case illegalValue(Int, for: String, expected: Range<Int>)
        case illegalOid(ASN1Kit.ObjectIdentifier)
    }

    static func checkValidity(offset: Int, usingShortFileIdentifier: Bool) throws {
        // gemSpec_COS#N011.500
        let minOffset = 0
        let maxOffset = usingShortFileIdentifier ? 255 : 32767

        if offset < minOffset || offset > maxOffset {
            throw InvalidArgument.offsetOutOfBounds(offset, usingShortFileIdentifier: usingShortFileIdentifier)
        }
    }
}

extension Int {
    func isNot(_ value: Int, else error: Error) throws {
        if self == value {
            throw error
        }
    }
}
