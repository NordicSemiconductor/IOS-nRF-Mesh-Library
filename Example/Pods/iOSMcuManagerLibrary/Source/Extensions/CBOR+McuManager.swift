/*
 * Copyright (c) 2017-2018 Runtime Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import SwiftCBOR

internal extension CBOR {
    
    private func wrapQuotes(_ string: String) -> String {
        return "\"\(string)\""
    }
    
    var description: String {
        switch self {
        case let .unsignedInt(l): return l.description
        case let .negativeInt(l): return l.description
        case let .byteString(l):  return wrapQuotes(Data(l).base64EncodedString())
        case let .utf8String(l):  return wrapQuotes(l)
        case let .array(l):       return l.description
        case let .map(l):         return l.description.replaceFirst(of: "[", with: "{").replaceLast(of: "]", with: "}")
        case let .tagged(_, l):   return l.description // TODO what to do with tags
        case let .simple(l):      return l.description
        case let .boolean(l):     return l.description
        case .null:               return "null"
        case .undefined:          return "null"
        case let .half(l):        return l.description
        case let .float(l):       return l.description
        case let .double(l):      return l.description
        case .break:              return ""
        case let .date(l):         return l.description
        }
    }
    
    var value : Any? {
        switch self {
        case let .unsignedInt(l): return Int(l)
        case let .negativeInt(l): return Int(l) * -1
        case let .byteString(l):  return l
        case let .utf8String(l):  return l
        case let .array(l):       return l
        case let .map(l):         return l
        case let .tagged(t, l):   return (t, l)
        case let .simple(l):      return l
        case let .boolean(l):     return l
        case .null:               return nil
        case .undefined:          return nil
        case let .half(l):        return l
        case let .float(l):       return l
        case let .double(l):      return l
        case .break:              return nil
        case let .date(l):        return l
        }
    }
    
    static func toObjectMap<V: CBORMappable>(map: [CBOR:CBOR]?) throws -> [String:V]? {
        guard let map = map else {
            return nil
        }
        var objMap = [String:V]()
        for (key, value) in map {
            if case let CBOR.utf8String(keyString) = key {
                let v = try V(cbor: value)
                objMap.updateValue(v, forKey: keyString)
            }
        }
        return objMap
    }
    
    static func toMap<V>(map: [CBOR:CBOR]?) throws -> [String:V]? {
        guard let map = map else {
            return nil
        }
        var objMap = [String:V]()
        for (key, value) in map {
            if case let CBOR.utf8String(keyString) = key {
                if let v = value.value as? V {
                    objMap.updateValue(v, forKey: keyString)
                }
            }
        }
        return objMap
    }
    
    static func toObjectArray<V: CBORMappable>(array: [CBOR]?) throws -> [V]? {
        guard let array = array else {
            return nil
        }
        var objArray = [V]()
        for cbor in array {
            let obj = try V(cbor: cbor)
            objArray.append(obj)
        }
        return objArray
    }
    
    static func toArray<V>(array: [CBOR]?) throws -> [V]? {
        guard let array = array else {
            return nil
        }
        var objArray = [V]()
        for cbor in array {
            if let v = cbor.value as? V {
                objArray.append(v)
            }
        }
        return objArray
    }
}

//*********************************************************************************************
// MARK: CBORMappable
//*********************************************************************************************

open class CBORMappable {
    required public init(cbor: CBOR?) throws {
    }
}
