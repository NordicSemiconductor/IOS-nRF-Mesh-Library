import Foundation

extension _CBORDecoder {
    final class SingleValueContainer {
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        var data: ArraySlice<UInt8>
        var index: Data.Index
        let options: CodableCBORDecoder._Options

        init(data: ArraySlice<UInt8>, codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], options: CodableCBORDecoder._Options) {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.data = data
            self.index = self.data.startIndex
            self.options = options
        }

        func checkCanDecode<T>(_ type: T.Type, format: UInt8) throws {
            guard self.index <= self.data.endIndex else {
                throw DecodingError.dataCorruptedError(in: self, debugDescription: "Unexpected end of data")
            }

            guard self.data[self.index] == format else {
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(format)")
                throw DecodingError.typeMismatch(type, context)
            }
        }

    }
}

extension _CBORDecoder.SingleValueContainer: SingleValueDecodingContainer {
    func decodeNil() -> Bool {
        guard let cbor = try? CBOR.decode(self.data.map { $0 }) else {
            return false
        }
        switch cbor {
        case .null: return true
        default: return false
        }
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        guard let cbor = try? CBOR.decode(self.data.map { $0 }) else {
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.dataCorrupted(context)
        }
        switch cbor {
        case .boolean(let bool): return bool
        default:
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.typeMismatch(Bool.self, context)
        }
    }

    func decode(_ type: String.Type) throws -> String {
        guard let cbor = try? CBOR.decode(self.data.map { $0 }) else {
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.dataCorrupted(context)
        }
        switch cbor {
        case .utf8String(let str): return str
        default:
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.typeMismatch(String.self, context)
        }
    }

    func decode(_ type: Double.Type) throws -> Double {
        guard let cbor = try? CBOR.decode(self.data.map { $0 }) else {
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.dataCorrupted(context)
        }
        switch cbor {
        case .double(let dbl): return dbl
        case .float(let flt): return Double(flt)
        case .half(let flt): return Double(flt)
        default:
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.typeMismatch(Double.self, context)
        }
    }

    func decode(_ type: Float.Type) throws -> Float {
        guard let cbor = try? CBOR.decode(self.data.map { $0 }) else {
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.dataCorrupted(context)
        }
        switch cbor {
        case .float(let flt): return flt
        case .half(let flt): return Float(flt)
        default:
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.typeMismatch(Float.self, context)
        }
    }

    func decode(_ type: Int.Type) throws -> Int {
        guard let cbor = try? CBOR.decode(self.data.map { $0 }) else {
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.dataCorrupted(context)
        }
        switch cbor {
        case .unsignedInt(let u64): return Int(u64)
        case .negativeInt(let u64): return -1 - Int(u64)
        default:
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.typeMismatch(Int.self, context)
        }
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        guard let cbor = try? CBOR.decode(self.data.map { $0 }) else {
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.dataCorrupted(context)
        }
        switch cbor {
        case .unsignedInt(let u64): return Int8(u64)
        case .negativeInt(let u64): return -1 - Int8(u64)
        default:
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.typeMismatch(Int8.self, context)
        }
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        guard let cbor = try? CBOR.decode(self.data.map { $0 }) else {
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.dataCorrupted(context)
        }
        switch cbor {
        case .unsignedInt(let u64): return Int16(u64)
        case .negativeInt(let u64): return -1 - Int16(u64)
        default:
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.typeMismatch(Int16.self, context)
        }
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        guard let cbor = try? CBOR.decode(self.data.map { $0 }) else {
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.dataCorrupted(context)
        }
        switch cbor {
        case .unsignedInt(let u64): return Int32(u64)
        case .negativeInt(let u64): return -1 - Int32(u64)
        default:
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.typeMismatch(Int32.self, context)
        }
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        guard let cbor = try? CBOR.decode(self.data.map { $0 }) else {
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.dataCorrupted(context)
        }
        switch cbor {
        case .unsignedInt(let u64): return Int64(u64)
        case .negativeInt(let u64): return -1 - Int64(u64)
        default:
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.typeMismatch(Int64.self, context)
        }
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        guard let cbor = try? CBOR.decode(self.data.map { $0 }) else {
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.dataCorrupted(context)
        }
        switch cbor {
        case .unsignedInt(let u64): return UInt(u64)
        default:
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.typeMismatch(UInt.self, context)
        }
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        guard let cbor = try? CBOR.decode(self.data.map { $0 }) else {
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.dataCorrupted(context)
        }
        switch cbor {
        case .unsignedInt(let u64): return UInt8(u64)
        default:
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.typeMismatch(UInt8.self, context)
        }
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        guard let cbor = try? CBOR.decode(self.data.map { $0 }) else {
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.dataCorrupted(context)
        }
        switch cbor {
        case .unsignedInt(let u64): return UInt16(u64)
        default:
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.typeMismatch(UInt16.self, context)
        }
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        guard let cbor = try? CBOR.decode(self.data.map { $0 }) else {
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.dataCorrupted(context)
        }
        switch cbor {
        case .unsignedInt(let u64): return UInt32(u64)
        default:
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.typeMismatch(UInt32.self, context)
        }
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        guard let cbor = try? CBOR.decode(self.data.map { $0 }) else {
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.dataCorrupted(context)
        }
        switch cbor {
        case .unsignedInt(let u64): return u64
        default:
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "Invalid format: \(self.data)")
            throw DecodingError.typeMismatch(UInt64.self, context)
        }
    }

    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        let decoder = _CBORDecoder(data: self.data, options: self.options)
        let value = try T(from: decoder)
        if let nextIndex = decoder.container?.index {
            self.index = nextIndex
        }

        return value
    }
}

extension _CBORDecoder.SingleValueContainer: CBORDecodingContainer {}
