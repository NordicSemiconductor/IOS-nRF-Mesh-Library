/*
* Copyright (c) 2017-2018 Runtime Inc.
*
* SPDX-License-Identifier: Apache-2.0
*/

import SwiftCBOR
#if canImport(Foundation)
import Foundation
#endif

extension CBOR: @retroactive CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .unsignedInt(let value): return "\(value)"
        case .negativeInt(let value): return "\(value)"
        case .byteString(let bytes):
            if bytes.isEmpty {
                return "0 bytes"
            }
            return "0x\(bytes.map { String(format: "%02X", $0) }.joined())"
        case .utf8String(let value): return "\"\(value)\""
        case .array(let array):
            return "[" + array
                .map { $0.debugDescription }
                .joined(separator: ", ") + "]"
        case .map(let map):
            return "{" + map
                .map { key, value in
                    // This will print the "rc" in human readable format.
                    if case .utf8String(let k) = key, k == "rc",
                       case .unsignedInt(let v) = value,
                       let status = McuMgrReturnCode(rawValue: v) {
                        return "\(key) : \(status)"
                    }
                    return "\(key.debugDescription) : \(value.debugDescription)"
                }
                .joined(separator: ", ") + "}"
        case .tagged(let tag, let cbor):
            return "\(tag): \(cbor)"
        case .simple(let value): return "\(value)"
        case .boolean(let value): return "\(value)"
        case .null: return "null"
        case .undefined: return "undefined"
        case .half(let value): return "\(value)"
        case .float(let value): return "\(value)"
        case .double(let value): return "\(value)"
        case .`break`: return "break"
        #if canImport(Foundation)
        case .date(let value): return "\(value)"
        #endif
        }
    }
    
}

extension Dictionary where Key == CBOR, Value == CBOR {
    
    // This overridden description takes care of printing the "rc" (Return Code)
    // in human readable format. All other values are printed as normal.
    public var description: String {
        return "{" +
            map { key, value in
                if case .utf8String(let k) = key, k == "rc",
                   case .unsignedInt(let v) = value,
                   let status = McuMgrReturnCode(rawValue: v) {
                    return "\(key) : \(status)"
                }
                return "\(key.description) : \(value.description)"
            }
            .joined(separator: ", ")
            + "}"
    }
    
}

extension CBOR.Tag: @retroactive CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch rawValue {
        case CBOR.Tag.standardDateTimeString.rawValue:
            return "Standard Date Time String"
        case CBOR.Tag.epochBasedDateTime.rawValue:
            return "Epoch Based Date Time"
        case CBOR.Tag.positiveBignum.rawValue:
            return "Positive Big Number"
        case CBOR.Tag.negativeBignum.rawValue:
            return "Negative Big Number"
        case CBOR.Tag.decimalFraction.rawValue:
            return "Decimal Fraction"
        case CBOR.Tag.bigfloat.rawValue:
            return "Big Float"
        case CBOR.Tag.expectedConversionToBase64URLEncoding.rawValue:
            return "Expected Conversion oo Base64 URL Encoding"
        case CBOR.Tag.expectedConversionToBase64Encoding.rawValue:
            return "Expected Conversion to Base64 Encoding"
        case CBOR.Tag.expectedConversionToBase16Encoding.rawValue:
            return "Expected Conversion to Base16 Encoding"
        case CBOR.Tag.encodedCBORDataItem.rawValue:
            return "Encoded CBOR Data Item"
        case CBOR.Tag.uri.rawValue:
            return "URI"
        case CBOR.Tag.base64Url.rawValue:
            return "Base64 URL"
        case CBOR.Tag.base64.rawValue:
            return "Base64"
        case CBOR.Tag.regularExpression.rawValue:
            return "Regular Expression"
        case CBOR.Tag.mimeMessage.rawValue:
            return "MIME Message"
        case CBOR.Tag.uuid.rawValue:
            return "UUID"
        case CBOR.Tag.selfDescribeCBOR.rawValue:
            return "Self Describe CBOR"
        default:
            return "tag(\(rawValue))"
        }
    }
    
}
