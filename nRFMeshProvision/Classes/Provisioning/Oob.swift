/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation
import CoreBluetooth

/// Information that points to Out-Of-Band (OOB) information
/// needed for provisioning.
public struct OobInformation: OptionSet {
    public let rawValue: UInt16
    
    public static let other          = OobInformation(rawValue: 1 << 0)
    public static let electronicURI  = OobInformation(rawValue: 1 << 1)
    public static let qrCode         = OobInformation(rawValue: 1 << 2)
    public static let barCode        = OobInformation(rawValue: 1 << 3)
    public static let nfc            = OobInformation(rawValue: 1 << 4)
    public static let number         = OobInformation(rawValue: 1 << 5)
    public static let string         = OobInformation(rawValue: 1 << 6)
    // Bits 7-10 are reserved for future use.
    public static let onBox          = OobInformation(rawValue: 1 << 11)
    public static let insideBox      = OobInformation(rawValue: 1 << 12)
    public static let onPieceOfPaper = OobInformation(rawValue: 1 << 13)
    public static let insideManual   = OobInformation(rawValue: 1 << 14)
    public static let onDevice       = OobInformation(rawValue: 1 << 15)
    
    /// Creates the object from the raw data.
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    
    /// Creates the object from the advertisement data.
    ///
    /// - parameter advertisementData: Received advertisement data.
    public init?(advertisementData: [String : Any]) {
        guard let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID : Data],
              let data = serviceData[MeshProvisioningService.uuid] else {
                return nil
        }
        guard data.count == 18 || data.count == 22 else {
            return nil
        }
        
        rawValue = data.read(fromOffset: 16)
    }
    
}

/// The authentication method chosen for provisioning.
public enum AuthenticationMethod {
    /// No OOB authentication is used.
    case noOob
    /// Static OOB authentication is used.
    case staticOob
    /// Output OOB authentication is used.
    /// Size must be in range 1...8.
    case outputOob(action: OutputAction, size: UInt8)
    /// Input OOB authentication is used.
    /// Size must be in range 1...8.
    case inputOob(action: InputAction, size: UInt8)
}

/// The output action will be displayed on the device.
/// For example, the device may use its LED to blink number of times.
/// The number of blinks will then have to be entered to the
/// Provisioner Manager.
public enum OutputAction: UInt8 {
    case blink              = 0
    case beep               = 1
    case vibrate            = 2
    case outputNumeric      = 3
    case outputAlphanumeric = 4
}

/// The user will have to enter the input action on the device.
/// For example, if the device supports ``InputAction/push``, user will be asked to
/// press a button on the device required number of times.
public enum InputAction: UInt8 {
    case push               = 0
    case twist              = 1
    case inputNumeric       = 2
    case inputAlphanumeric  = 3
}

/// This object should generate a random alphanumeric or a random number of given sizes.
///
/// The value generator is used in Provisioning with an Input Action used as OOB.
///
/// The default implementation provides random values. It should only be overriden
/// if you need to know the values in advance, for example for testing.
open class InputActionValueGenerator {
    /// This method should generate a random alphanumeric capitalize string of given size.
    ///
    /// For example, for `size` equal to 3 the output can be "3Z8".
    ///
    /// - parameter size: Required length of the returned String.
    /// - returns: The random alphanumeric String.
    func randomAlphanumeric(size: UInt8) -> String {
        return String.random(length: size)
    }
    
    /// This method should generate a random integer of at most given length.
    ///
    /// For example, for the `size` equal to 2 the maximum returned value is 99.
    ///
    /// - parameter size: The maximum supported length of the integer.
    /// - returns: A random integer of maximum given length.
    func randomInt(size: UInt8) -> UInt {
        return UInt.random(length: size)
    }
}

/// A set of supported Out-Of-Band types.
public struct OobType: OptionSet {
    public let rawValue: UInt8
    
    /// Static OOB Information is available.
    public static let staticOobInformationAvailable = OobType(rawValue: 1 << 0)
    /// Only OOB authenticated provisioning supported.
    ///
    /// - since: Mesh Protocol 1.1.
    public static let onlyOobAuthenticatedProvisioningSupported = OobType(rawValue: 1 << 1)
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
}

/// A set of supported Output Out-of-band actions.
public struct OutputOobActions: OptionSet {
    public let rawValue: UInt16
    
    public static let blink              = OutputOobActions(rawValue: 1 << 0)
    public static let beep               = OutputOobActions(rawValue: 1 << 1)
    public static let vibrate            = OutputOobActions(rawValue: 1 << 2)
    public static let outputNumeric      = OutputOobActions(rawValue: 1 << 3)
    public static let outputAlphanumeric = OutputOobActions(rawValue: 1 << 4)
    
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    
}

/// A set of supported Input Out-of-band actions.
public struct InputOobActions: OptionSet {
    public let rawValue: UInt16
    
    public static let push              = InputOobActions(rawValue: 1 << 0)
    public static let twist             = InputOobActions(rawValue: 1 << 1)
    public static let inputNumeric      = InputOobActions(rawValue: 1 << 2)
    public static let inputAlphanumeric = InputOobActions(rawValue: 1 << 3)
    
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    
}

// MARK: - Custom String Convertible

extension OobInformation: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        if rawValue == 0 {
            return "Unknown"
        }
        return [
            (.other,          "Other"),
            (.electronicURI,  "Electronic URI"),
            (.qrCode,         "QR Code"),
            (.barCode,        "Bar Code"),
            (.nfc,            "NFC"),
            (.number,         "Number"),
            (.string,         "String"),
            (.onBox,          "On Box"),
            (.insideBox,      "Inside Box"),
            (.onPieceOfPaper, "On Piece Of Paper"),
            (.insideManual,   "Inside Manual"),
            (.onDevice,       "On Device")
            ]
            .compactMap { (option, name) in contains(option) ? name : nil }
            .joined(separator: ", ")
    }
    
}

extension AuthenticationMethod: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .noOob: return "No OOB"
        case .staticOob: return "Static OOB"
        case let .outputOob(action: action, size: size): return "Output Action: \(action) (size: \(size))"
        case let .inputOob(action: action, size: size): return "Input Action: \(action) (size: \(size))"
        }
    }
    
}

extension OutputAction: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .blink: return "Blink"
        case .beep:  return "Beep"
        case .vibrate: return "Vibrate"
        case .outputNumeric: return "Output Numeric"
        case .outputAlphanumeric: return "Output Alphanumeric"
        }
    }
    
}

extension InputAction: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .push: return "Push"
        case .twist:  return "Twist"
        case .inputNumeric: return "Input Numeric"
        case .inputAlphanumeric: return "Input Alphanumeric"
        }
    }
    
}

extension OobType: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        if rawValue == 0 {
            return "None"
        }
        return [
            (.staticOobInformationAvailable, "Static OOB Information Available"),
            (.onlyOobAuthenticatedProvisioningSupported, "Only OOB Authenticated Provisioning Supported")
            ]
            .compactMap { option, name in contains(option) ? name : nil }
            .joined(separator: ", ")
    }
    
}

extension OutputOobActions: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        if rawValue == 0 {
            return "None"
        }
        return [
            (.blink, "Blink"),
            (.beep, "Beep"),
            (.vibrate, "Vibrate"),
            (.outputNumeric, "Output Numeric"),
            (.outputAlphanumeric, "Output Alphanumeric")
            ]
            .compactMap { (option, name) in contains(option) ? name : nil }
            .joined(separator: ", ")
    }
    
}

extension InputOobActions: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        if rawValue == 0 {
            return "None"
        }
        return [
            (.push, "Push"),
            (.twist, "Twist"),
            (.inputNumeric, "Input Numeric"),
            (.inputAlphanumeric, "Input Alphanumeric")
            ]
            .compactMap { (option, name) in contains(option) ? name : nil }
            .joined(separator: ", ")
    }
    
}

private extension String {
    
    /// Generates a random string of numerics and capital English letters
    /// with given length.
    static func random(length: UInt8) -> String {
        let letters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
    
}

private extension UInt {
    
    /// Generates a random integer with at most `length` digits.
    static func random(length digits: UInt8) -> UInt {
        let upperbound = UInt(pow(10.0, Double(digits)))
        return UInt.random(in: 1..<upperbound)
    }

}
