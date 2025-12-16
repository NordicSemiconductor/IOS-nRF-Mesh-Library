import Foundation

extension _CBOREncoder {
    final class SingleValueContainer {
        private var storage: Data = Data()

        fileprivate var canEncodeNewValue = true
        fileprivate func checkCanEncode(value: Any?) throws {
            guard self.canEncodeNewValue else {
                let context = EncodingError.Context(codingPath: self.codingPath, debugDescription: "Attempt to encode value through single value container when previously value already encoded.")
                throw EncodingError.invalidValue(value as Any, context)
            }
        }

        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]

        let options: CodableCBOREncoder._Options

        init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], options: CodableCBOREncoder._Options) {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.options = options
        }
    }
}

extension _CBOREncoder.SingleValueContainer: SingleValueEncodingContainer {
    func encodeNil() throws {
        try checkCanEncode(value: nil)
        defer { self.canEncodeNewValue = false }

        self.storage.append(contentsOf: CBOR.encodeNull())
    }

    func encode(_ value: Bool) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        self.storage.append(contentsOf: CBOR.encodeBool(value))
    }

    func encode(_ value: String) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        self.storage.append(contentsOf: CBOR.encodeString(value, options: self.options.toCBOROptions()))
    }

    func encode(_ value: Double) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        self.storage.append(contentsOf: CBOR.encodeDouble(value))
    }

    func encode(_ value: Float) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        self.storage.append(contentsOf: CBOR.encodeFloat(value))
    }

    func encode(_ value: Int) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        self.storage.append(contentsOf: CBOR.encode(value))
    }

    func encode(_ value: Int8) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        self.storage.append(contentsOf: CBOR.encode(Int(value)))
    }

    func encode(_ value: Int16) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        self.storage.append(contentsOf: CBOR.encode(Int(value)))
    }

    func encode(_ value: Int32) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        self.storage.append(contentsOf: CBOR.encode(Int(value)))
    }

    func encode(_ value: Int64) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        self.storage.append(contentsOf: CBOR.encode(Int(value)))
    }

    func encode(_ value: UInt) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        self.storage.append(contentsOf: CBOR.encode(value))
    }

    func encode(_ value: UInt8) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        self.storage.append(contentsOf: CBOR.encode(value))
    }

    func encode(_ value: UInt16) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        self.storage.append(contentsOf: CBOR.encode(value))
    }

    func encode(_ value: UInt32) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        self.storage.append(contentsOf: CBOR.encode(value))
    }

    func encode(_ value: UInt64) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        self.storage.append(contentsOf: CBOR.encode(value))
    }

    func encodeDate(_ value: Date) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        self.storage.append(contentsOf: CBOR.encodeDate(value, options: self.options.toCBOROptions()))
    }

    func encodeData(_ value: Data) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        self.storage.append(contentsOf: CBOR.encodeData(value, options: self.options.toCBOROptions()))
    }

    func encode<T: Encodable>(_ value: T) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        switch value {
        case let data as Data:
            try self.encodeData(data)
        case let date as Date:
            try self.encodeDate(date)
        default:
            let encoder = _CBOREncoder(options: self.options)
            try value.encode(to: encoder)
            self.storage.append(encoder.data)
        }
    }
}

extension _CBOREncoder.SingleValueContainer: CBOREncodingContainer {
    var data: Data {
        return storage
    }
}
