//
//  Oob.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 07/05/2019.
//

import Foundation

/// Information that points to out-of-band (OOB) information
/// needed for provisioning.
public struct OobInformation: OptionSet {
    public let rawValue: UInt16
    
    public static let other          = OobInformation(rawValue: 1 << 0)
    public static let electornicURI  = OobInformation(rawValue: 1 << 1)
    public static let qrCode         = OobInformation(rawValue: 1 << 2)
    public static let barCode        = OobInformation(rawValue: 1 << 3)
    public static let nfc            = OobInformation(rawValue: 1 << 4)
    public static let number         = OobInformation(rawValue: 1 << 5)
    public static let string         = OobInformation(rawValue: 1 << 6)
    public static let onBox          = OobInformation(rawValue: 1 << 11)
    public static let insideBox      = OobInformation(rawValue: 1 << 12)
    public static let onPieceOfPaper = OobInformation(rawValue: 1 << 13)
    public static let insideManual   = OobInformation(rawValue: 1 << 14)
    public static let onDevice       = OobInformation(rawValue: 1 << 15)
    
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    
}

public enum AuthenticationMethod {
    /// No OOB authentication is used.
    case noOob
    /// Static OOB authentication is used.
    case staticOob(key: Data)
    /// Output OOB authentication is used.
    case outputOob(action: OutputAction, size: UInt8)
    /// Input OOB authentication is used.
    case inputOob(action: InputAction, size: UInt8)
    
    var value: UInt8 {
        switch self {
        case .noOob:                         return 0
        case .staticOob(key: _):             return 1
        case .outputOob(action: _, size: _): return 2
        case .inputOob(action: _, size: _):  return 3
        }
    }
}

public enum OutputAction: UInt8 {
    case blink              = 0
    case beep               = 1
    case vibrate            = 2
    case outputNumeric      = 3
    case outputAlphanumeric = 4
}

public enum InputAction: UInt8 {
    case push              = 0
    case twist             = 1
    case inputNumeric      = 2
    case inputAlphanumeric = 3
}

public struct StaticOobType: OptionSet {
    public let rawValue: UInt8
    
    /// Static OOB Information is available.
    public static let staticOobInformationAvailable = StaticOobType(rawValue: 1 << 0)
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    public var count: Int {
        return rawValue.nonzeroBitCount
    }
    
}

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
    
    public var count: Int {
        return rawValue.nonzeroBitCount
    }
    
}

public struct InputOobActions: OptionSet {
    public let rawValue: UInt16
    
    public static let push              = InputOobActions(rawValue: 1 << 0)
    public static let twist             = InputOobActions(rawValue: 1 << 1)
    public static let inputNumeric      = InputOobActions(rawValue: 1 << 2)
    public static let inputAlphanumeric = InputOobActions(rawValue: 1 << 3)
    
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    
    public var count: Int {
        return rawValue.nonzeroBitCount
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
            (.electornicURI,  "Electornic URI"),
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

extension StaticOobType: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        if rawValue == 0 {
            return "None"
        }
        return [(.staticOobInformationAvailable, "Static OOB Information Available")]
            .compactMap { (option, name) in contains(option) ? name : nil }
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
