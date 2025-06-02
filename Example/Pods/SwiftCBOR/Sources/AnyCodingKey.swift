struct AnyCodingKey: CodingKey, Equatable {
    var stringValue: String {
        get { self._stringValue ?? "_do_not_use_this_string_value_use_the_int_value_instead_" }
    }

    var _stringValue: String?
    var intValue: Int?

    init(stringValue: String) {
        self._stringValue = stringValue
        self.intValue = nil
    }

    init(intValue: Int) {
        self.intValue = intValue
        self._stringValue = nil
    }

    init<Key: CodingKey>(_ base: Key, useStringKey: Bool = false) {
        if !useStringKey, let intValue = base.intValue {
            self.init(intValue: intValue)
        } else {
            self.init(stringValue: base.stringValue)
        }
    }

    func key<K: CodingKey>() -> K {
        if let intValue = self.intValue {
            return K(intValue: intValue)!
        } else if let stringValue = self._stringValue {
            return K(stringValue: stringValue)!
        } else {
            fatalError("AnyCodingKey created without a string or int value")
        }
    }
}

extension AnyCodingKey: Hashable {
    public func hash(into hasher: inout Hasher) {
        self.intValue?.hash(into: &hasher) ?? self._stringValue?.hash(into: &hasher)
    }
}

extension AnyCodingKey: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intValue = self.intValue {
            try container.encode(intValue)
        } else if let stringValue = self._stringValue {
            try container.encode(stringValue)
        } else {
            fatalError("AnyCodingKey created without a string or int value")
        }
    }
}

extension AnyCodingKey: Decodable {
    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer()
        if let intValue = try? value.decode(Int.self) {
            self._stringValue = nil
            self.intValue = intValue
        } else {
            self._stringValue = try! value.decode(String.self)
            self.intValue = nil
        }
    }
}
