#if canImport(Foundation)
import Foundation
#endif

let isBigEndian = Int(bigEndian: 42) == 42

/// Takes a value breaks it into bytes. assumes necessity to reverse for endianness if needed
/// This function has only been tested with UInt_s, Floats and Doubles
/// T must be a simple type. It cannot be a collection type.
func rawBytes<T>(of x: T) -> [UInt8] {
    var mutable = x // create mutable copy for `withUnsafeBytes`
    let bigEndianResult = withUnsafeBytes(of: &mutable) { Array($0) }
    return isBigEndian ? bigEndianResult : bigEndianResult.reversed()
}

/// Defines basic CBOR.encode API.
/// Defines more fine-grained functions of form CBOR.encode*(_ x)
/// for all CBOR types except Float16
extension CBOR {
    public static func encode<T: CBOREncodable>(_ value: T, options: CBOROptions = CBOROptions()) -> [UInt8] {
        return value.encode(options: options)
    }

    /// Encodes an array as either a CBOR array type or a CBOR bytestring type, depending on `asByteString`.
    /// NOTE: when `asByteString` is true and T = UInt8, the array is interpreted in network byte order
    /// Arrays with values of all other types will have their bytes reversed if the system is little endian.
    public static func encode<T: CBOREncodable>(_ array: [T], asByteString: Bool = false, options: CBOROptions = CBOROptions()) -> [UInt8] {
        if asByteString {
            let length = array.count
            var res = length.encode()
            res[0] = res[0] | 0b010_00000
            let itemSize = MemoryLayout<T>.size
            let bytelength = length * itemSize
            res.reserveCapacity(res.count + bytelength)

            let noReversalNeeded = isBigEndian || T.self == UInt8.self

            array.withUnsafeBytes { bufferPtr in
                guard let ptr = bufferPtr.baseAddress?.bindMemory(to: UInt8.self, capacity: bytelength) else {
                    fatalError("Invalid pointer")
                }
                var j = 0
                for i in 0..<bytelength {
                    j = noReversalNeeded ? i : bytelength - 1 - i
                    res.append((ptr + j).pointee)
                }
            }
            return res
        } else {
            return encodeArray(array, options: options)
        }
    }

    public static func encode<A: CBOREncodable, B: CBOREncodable>(_ dict: [A: B], options: CBOROptions = CBOROptions()) -> [UInt8] {
        return encodeMap(dict, options: options)
    }

    // MARK: - major 0: unsigned integer

    public static func encodeUInt8(_ x: UInt8) -> [UInt8] {
        if (x < 24) { return [x] }
        else { return [0x18, x] }
    }

    public static func encodeUInt16(_ x: UInt16) -> [UInt8] {
        return [0x19] + rawBytes(of: x)
    }

    public static func encodeUInt32(_ x: UInt32) -> [UInt8] {
        return [0x1a] + rawBytes(of: x)
    }

    public static func encodeUInt64(_ x: UInt64) -> [UInt8] {
        return [0x1b] + rawBytes(of: x)
    }

    internal static func encodeVarUInt(_ x: UInt64) -> [UInt8] {
        switch x {
        case let x where x <= UInt8.max: return CBOR.encodeUInt8(UInt8(x))
        case let x where x <= UInt16.max: return CBOR.encodeUInt16(UInt16(x))
        case let x where x <= UInt32.max: return CBOR.encodeUInt32(UInt32(x))
        default: return CBOR.encodeUInt64(x)
        }
    }

    // MARK: - major 1: negative integer

    public static func encodeNegativeInt(_ x: Int64) -> [UInt8] {
        assert(x < 0)
        var res = encodeVarUInt(~UInt64(bitPattern: x))
        res[0] = res[0] | 0b001_00000
        return res
    }

    // MARK: - major 2: bytestring

    public static func encodeByteString(_ bs: [UInt8], options: CBOROptions = CBOROptions()) -> [UInt8] {
        var res = bs.count.encode(options: options)
        res[0] = res[0] | 0b010_00000
        res.append(contentsOf: bs)
        return res
    }

    #if canImport(Foundation)
    public static func encodeData(_ data: Data, options: CBOROptions = CBOROptions()) -> [UInt8] {
        return encodeByteString([UInt8](data), options: options)
    }
    #endif

    // MARK: - major 3: UTF8 string

    public static func encodeString(_ str: String, options: CBOROptions = CBOROptions()) -> [UInt8] {
        let utf8array = Array(str.utf8)
        var res = utf8array.count.encode(options: options)
        res[0] = res[0] | 0b011_00000
        res.append(contentsOf: utf8array)
        return res
    }

    // MARK: - major 4: array of data items

    public static func encodeArray<T: CBOREncodable>(_ arr: [T], options: CBOROptions = CBOROptions()) -> [UInt8] {
        var res = arr.count.encode(options: options)
        res[0] = res[0] | 0b100_00000
        res.append(contentsOf: arr.flatMap{ return $0.encode(options: options) })
        return res
    }

    // MARK: - major 5: a map of pairs of data items

    public static func encodeMap<A: CBOREncodable, B: CBOREncodable>(_ map: [A: B], options: CBOROptions = CBOROptions()) -> [UInt8] {
        if options.forbidNonStringMapKeys {
            try! ensureStringKey(A.self)
        }
        var res: [UInt8] = []
        res.reserveCapacity(1 + map.count * (MemoryLayout<A>.size + MemoryLayout<B>.size + 2))
        res = map.count.encode(options: options)
        res[0] = res[0] | 0b101_00000
        for (k, v) in map {
            res.append(contentsOf: k.encode(options: options))
            res.append(contentsOf: v.encode(options: options))
        }
        return res
    }

    public static func encodeMap<A: CBOREncodable>(_ map: [A: Any?], options: CBOROptions = CBOROptions()) throws -> [UInt8] {
        if options.forbidNonStringMapKeys {
            try ensureStringKey(A.self)
        }
        var res: [UInt8] = []
        res = map.count.encode(options: options)
        res[0] = res[0] | 0b101_00000
        try CBOR.encodeMap(map, into: &res, options: options)
        return res
    }

    // MARK: - major 6: tagged values

    public static func encodeTagged<T: CBOREncodable>(tag: Tag, value: T, options: CBOROptions = CBOROptions()) -> [UInt8] {
        var res = encodeVarUInt(tag.rawValue)
        res[0] = res[0] | 0b110_00000
        res.append(contentsOf: value.encode(options: options))
        return res
    }

    // MARK: - major 7: floats, simple values, the 'break' stop code

    public static func encodeSimpleValue(_ x: UInt8) -> [UInt8] {
        if x < 24 {
            return [0b111_00000 | x]
        } else {
            return [0xf8, x]
        }
    }

    public static func encodeNull() -> [UInt8] {
        return [0xf6]
    }

    public static func encodeUndefined() -> [UInt8] {
        return [0xf7]
    }

    public static func encodeBreak() -> [UInt8] {
        return [0xff]
    }

    public static func encodeFloat(_ x: Float) -> [UInt8] {
        return [0xfa] + rawBytes(of: x)
    }

    public static func encodeDouble(_ x: Double) -> [UInt8] {
        return [0xfb] + rawBytes(of: x)
    }

    public static func encodeBool(_ x: Bool) -> [UInt8] {
        return x ? [0xf5] : [0xf4]
    }

    // MARK: - Indefinite length items

    /// Returns a CBOR value indicating the opening of an indefinite-length data item.
    /// The user is responsible for creating and sending subsequent valid CBOR.
    /// In particular, the user must end the stream with the CBOR.break byte, which
    /// can be returned with `encodeStreamEnd()`.
    ///
    /// The stream API is limited right now, but will get better when Swift allows
    /// one to generically constrain the elements of generic Iterators, in which case
    /// streaming implementation is trivial
    public static func encodeArrayStreamStart() -> [UInt8] {
        return [0x9f]
    }

    public static func encodeMapStreamStart() -> [UInt8] {
        return [0xbf]
    }

    public static func encodeStringStreamStart() -> [UInt8] {
        return [0x7f]
    }

    public static func encodeByteStringStreamStart() -> [UInt8] {
        return [0x5f]
    }

    /// This is the same as a CBOR "break" value
    public static func encodeStreamEnd() -> [UInt8] {
        return [0xff]
    }

    // TODO: unify definite and indefinite code
    public static func encodeArrayChunk<T: CBOREncodable>(_ chunk: [T], options: CBOROptions = CBOROptions()) -> [UInt8] {
        var res: [UInt8] = []
        res.reserveCapacity(chunk.count * MemoryLayout<T>.size)
        res.append(contentsOf: chunk.flatMap{ return $0.encode(options: options) })
        return res
    }

    public static func encodeMapChunk<A: CBOREncodable, B: CBOREncodable>(_ map: [A: B], options: CBOROptions = CBOROptions()) -> [UInt8] {
        if options.forbidNonStringMapKeys {
            try! ensureStringKey(A.self)
        }
        var res: [UInt8] = []
        let count = map.count
        res.reserveCapacity(count * MemoryLayout<A>.size + count * MemoryLayout<B>.size)
        for (k, v) in map {
            res.append(contentsOf: k.encode(options: options))
            res.append(contentsOf: v.encode(options: options))
        }
        return res
    }

    #if canImport(Foundation)
    public static func encodeDate(_ date: Date, options: CBOROptions = CBOROptions()) -> [UInt8] {
        let timeInterval = date.timeIntervalSince1970
        let (integral, fractional) = modf(timeInterval)

        let seconds = Int64(integral)
        let nanoseconds = Int32(fractional * Double(NSEC_PER_SEC))

        switch options.dateStrategy {
        case .annotatedMap:
            var dateCBOR: CBOR
            if seconds < 0 && nanoseconds == 0 {
                dateCBOR = CBOR.negativeInt(UInt64(-Double(timeInterval + 1)))
            } else if seconds > UInt32.max {
                dateCBOR = CBOR.double(timeInterval)
            } else if nanoseconds != 0 {
                dateCBOR = CBOR.double(timeInterval)
            } else {
                dateCBOR = CBOR.unsignedInt(UInt64(seconds))
            }

            let map: [String: CBOREncodable] = [
                AnnotatedMapDateStrategy.typeKey: AnnotatedMapDateStrategy.typeValue,
                AnnotatedMapDateStrategy.valueKey: dateCBOR
            ]
            return try! CBOR.encodeMap(map, options: options)
        case .taggedAsEpochTimestamp:
            var res: [UInt8] = [0b110_00001] // Epoch timestamp tag is 1
            if seconds < 0 && nanoseconds == 0 {
                res.append(contentsOf: CBOR.encodeNegativeInt(Int64(timeInterval)))
            } else if seconds > UInt32.max {
                res.append(contentsOf: CBOR.encodeDouble(timeInterval))
            } else if nanoseconds != 0 {
                res.append(contentsOf: CBOR.encodeDouble(timeInterval))
            } else {
                res.append(contentsOf: CBOR.encode(Int(seconds), options: options))
            }

            return res
        }
    }
    #endif

    public static func encodeAny(_ any: Any?, options: CBOROptions = CBOROptions()) throws -> [UInt8] {
        switch any {
        case is Int:
            return (any as! Int).encode()
        case is Int8:
            return (any as! Int8).encode()
        case is Int16:
            return (any as! Int16).encode()
        case is Int32:
            return (any as! Int32).encode()
        case is Int64:
            return (any as! Int64).encode()
        case is UInt:
            return (any as! UInt).encode()
        case is UInt8:
            return (any as! UInt8).encode()
        case is UInt16:
            return (any as! UInt16).encode()
        case is UInt32:
            return (any as! UInt32).encode()
        case is UInt64:
            return (any as! UInt64).encode()
        case is String:
            return (any as! String).encode(options: options)
        case is Float:
            return (any as! Float).encode()
        case is Double:
            return (any as! Double).encode()
        case is Bool:
            return (any as! Bool).encode()
        #if canImport(Foundation)
        case is Data:
            return CBOR.encodeByteString((any as! Data).map { $0 }, options: options)
        case is Date:
            return CBOR.encodeDate((any as! Date), options: options)
        case is NSNull:
            return CBOR.encodeNull()
        #endif
        case is [Any?]:
            let anyArr = any as! [Any?]
            var res = anyArr.count.encode(options: options)
            res[0] = res[0] | 0b100_00000
            let encodedInners = try anyArr.reduce(into: []) { acc, next in
                acc.append(contentsOf: try encodeAny(next, options: options))
            }
            res.append(contentsOf: encodedInners)
            return res
        case is [String: Any?]:
            let anyMap = any as! [String: Any?]
            var res: [UInt8] = anyMap.count.encode(options: options)
            res[0] = res[0] | 0b101_00000
            try CBOR.encodeMap(anyMap, into: &res, options: options)
            return res
        case is Void:
            return CBOR.encodeUndefined()
        case nil:
            return CBOR.encodeNull()
        default:
            if let encodable = any as? CBOREncodable {
                return encodable.encode(options: options)
            } else if let encodable = any as? Codable {
                let encoder = CodableCBOREncoder()
                encoder.setOptions(options.toCodableEncoderOptions())
                return try [UInt8](encoder.encode(encodable))
            }
            throw CBOREncoderError.invalidType
        }
    }

    internal static func cborFromAny(_ any: Any?, options: CBOROptions = CBOROptions()) throws -> CBOR {
        switch any {
        case is Int:
            return cborFromInt64(Int64(any as! Int))
        case is Int8:
            return cborFromInt64(Int64(any as! Int8))
        case is Int16:
            return cborFromInt64(Int64(any as! Int16))
        case is Int32:
            return cborFromInt64(Int64(any as! Int32))
        case is Int64:
            return cborFromInt64(any as! Int64)
        case is UInt:
            return CBOR.unsignedInt(UInt64(any as! UInt))
        case is UInt8:
            return CBOR.unsignedInt(UInt64(any as! UInt8))
        case is UInt16:
            return CBOR.unsignedInt(UInt64(any as! UInt16))
        case is UInt32:
            return CBOR.unsignedInt(UInt64(any as! UInt32))
        case is UInt64:
            return CBOR.unsignedInt(any as! UInt64)
        case is String:
            return CBOR.utf8String(any as! String)
        case is Float:
            return CBOR.float(any as! Float)
        case is Double:
            return CBOR.double(any as! Double)
        case is Bool:
            return CBOR.boolean(any as! Bool)
        #if canImport(Foundation)
        case is Data:
            return CBOR.byteString((any as! Data).map { $0 })
        case is Date:
            return CBOR.date(any as! Date)
        case is NSNull:
            return CBOR.null
        #endif
        case is [Any?]:
            let anyArr = any as! [Any?]
            return try CBOR.array(anyArr.map { try cborFromAny($0) })
        case is [String: Any?]:
            let anyMap = any as! [String: Any?]
            return try CBOR.map(Dictionary(
                uniqueKeysWithValues: anyMap.map { try (cborFromAny($0.key), cborFromAny($0.value)) }
            ))
        case is Void:
            return CBOR.undefined
        case nil:
            return CBOR.null
        default:
            if let encodable = any as? CBOREncodable {
                return encodable.toCBOR(options: options)
            } else if let encodable = any as? Codable {
                // This is very much a slow path - we fully encode and then
                // decode the value to get it as a `CBOR`
                let encoder = CodableCBOREncoder()
                encoder.setOptions(options.toCodableEncoderOptions())
                let encoded = try [UInt8](encoder.encode(encodable))
                guard let decoded = try CBOR.decode(encoded) else {
                    throw CBOREncoderError.invalidType
                }
                return decoded
            }
            throw CBOREncoderError.invalidType
        }
    }

    private static func cborFromInt64(_ i: Int64) -> CBOR {
        if i < 0 {
            return CBOR.negativeInt(~UInt64(bitPattern: i))
        } else {
            return CBOR.unsignedInt(UInt64(i))
        }
    }

    private static func encodeMap<A: CBOREncodable>(_ map: [A: Any?], into res: inout [UInt8], options: CBOROptions = CBOROptions()) throws {
        if options.forbidNonStringMapKeys {
            try ensureStringKey(A.self)
        }
        let sortedKeysWithEncodedKeys = map.keys.map {
            (encoded: $0.encode(options: options), key: $0)
        }.sorted(by: {
            $0.encoded.lexicographicallyPrecedes($1.encoded)
        })

        try sortedKeysWithEncodedKeys.forEach { keyTuple in
            res.append(contentsOf: keyTuple.encoded)
            let encodedVal = try encodeAny(map[keyTuple.key]!, options: options)
            res.append(contentsOf: encodedVal)
        }
    }
}

public enum CBOREncoderError: Error {
    case invalidType
    case nonStringKeyInMap
}

func ensureStringKey<T>(_ keyType: T.Type) throws where T: CBOREncodable {
    guard T.self is SwiftCBORStringKey.Type else {
        throw CBOREncoderError.nonStringKeyInMap
    }
}
