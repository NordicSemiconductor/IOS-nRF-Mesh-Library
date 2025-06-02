import Foundation

extension _CBORDecoder {
    final class KeyedContainer<Key: CodingKey> {

        // This is non-nil once nestedContainers() has been called once, and if the data is valid
        var _nestedContainers: [AnyCodingKey: CBORDecodingContainer]? = nil

        // This is non-nil once count() has been called once, and if the data is valid
        var _count: Int?

        var data: ArraySlice<UInt8>
        var index: Data.Index
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        let options: CodableCBORDecoder._Options

        init(data: ArraySlice<UInt8>, codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], options: CodableCBORDecoder._Options) {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.data = data
            self.index = self.data.startIndex
            self.options = options
        }

        func checkCanDecodeValue(forKey key: Key) throws {
            guard self.contains(key) else {
                let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "key not found: \(key)")
                throw DecodingError.keyNotFound(key, context)
            }
        }

        func nestedContainers() throws -> [AnyCodingKey: CBORDecodingContainer] {
            if let nestedContainers = self._nestedContainers {
                return nestedContainers
            }

            guard let count = try count() else {
                return [:]
            }

            var nestedContainers: [AnyCodingKey: CBORDecodingContainer] = [:]

            let unkeyedContainer = UnkeyedContainer(data: self.data.suffix(from: self.index), codingPath: self.codingPath, userInfo: self.userInfo, options: self.options)
            unkeyedContainer.count = count * 2

            var iterator = unkeyedContainer.nestedContainers.makeIterator()

            for _ in 0..<count {
                guard let keyContainer = iterator.next() as? _CBORDecoder.SingleValueContainer,
                    let container = iterator.next() else {
                        fatalError() // FIXME
                }

                let keyVal: AnyCodingKey
                if self.options.useStringKeys {
                    let stringKey = try! keyContainer.decode(String.self)
                    keyVal = AnyCodingKey(stringValue: stringKey)
                } else {
                    keyVal = try! keyContainer.decode(AnyCodingKey.self)
                }
                nestedContainers[keyVal] = container
            }

            self.index = unkeyedContainer.index
            self._nestedContainers = nestedContainers
            return nestedContainers
        }

        func count() throws -> Int? {
            if let count = self._count {
                return count
            }

            let count: Int?

            let format = try self.readByte()
            switch format {
            case 0xa0...0xb7: count = Int(format & 0x1F)
            case 0xb8: count = Int(try read(UInt8.self))
            case 0xb9: count = Int(try read(UInt16.self))
            case 0xba: count = Int(try read(UInt32.self))
            case 0xbb: count = Int(try read(UInt64.self))
            case 0xbf:
                // FIXME: This is a very inefficient way of doing this. Really we should be modifying the
                // nestedContainers code so that if we're working with a map that has a break at the end
                // it creates the containers as it goes, rather than first calculating the count (which
                // involves going through all the bytes) and then going back through the data and decoding
                // each key-value pair in the map.
                let nextIndex = self.data.startIndex.advanced(by: 1)
                let remainingData = self.data.suffix(from: nextIndex)
                count = try? CBORDecoder(input: remainingData.map { $0 }).readPairsUntilBreak().keys.count
            default:
                let context = DecodingError.Context(
                    codingPath: self.codingPath,
                    debugDescription: "Unable to get count of elements in dictionary"
                )
                throw DecodingError.typeMismatch(Int.self, context)
            }

            self._count = count
            return count
        }
    }
}

extension _CBORDecoder.KeyedContainer: KeyedDecodingContainerProtocol {
    var allKeys: [Key] {
        if let containers = try? self.nestedContainers() {
            return containers.keys.map { $0.key() }
        }
        return []
    }

    func contains(_ key: Key) -> Bool {
        if let containers = try? self.nestedContainers() {
            return containers.keys.contains(anyCodingKeyForKey(key))
        }
        return false
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        let container = try self.nestedContainers()[anyCodingKeyForKey(key)]
        switch container {
        case is _CBORDecoder.SingleValueContainer:
            return (container as! _CBORDecoder.SingleValueContainer).decodeNil()
        case is _CBORDecoder.UnkeyedContainer:
            return try (container as! _CBORDecoder.UnkeyedContainer).decodeNil()
        case is _CBORDecoder.KeyedContainer<AnyCodingKey>:
            return try (container as! _CBORDecoder.KeyedContainer<AnyCodingKey>).decodeNil(forKey: anyCodingKeyForKey(key))
        case nil:
            return false
        default:
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "cannot decode nil for key: \(key)")
            throw DecodingError.typeMismatch(Any?.self, context)
        }
    }

    func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        try checkCanDecodeValue(forKey: key)

        let container = try self.nestedContainers()[anyCodingKeyForKey(key)]!
        let decoder = CodableCBORDecoder()
        decoder.setOptions(self.options)
        return try decoder.decode(T.self, from: container.data)
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        try checkCanDecodeValue(forKey: key)

        guard let unkeyedContainer = try self.nestedContainers()[anyCodingKeyForKey(key)] as? _CBORDecoder.UnkeyedContainer else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "cannot decode nested container for key: \(key)")
        }

        return unkeyedContainer
    }

    func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        try checkCanDecodeValue(forKey: key)

        guard let anyCodingKeyedContainer = try self.nestedContainers()[anyCodingKeyForKey(key)] as? _CBORDecoder.KeyedContainer<AnyCodingKey> else {
            throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "cannot decode nested container for key: \(key)")
        }
        let container = _CBORDecoder.KeyedContainer<NestedKey>(
            data: anyCodingKeyedContainer.data,
            codingPath: anyCodingKeyedContainer.codingPath,
            userInfo: anyCodingKeyedContainer.userInfo,
            options: anyCodingKeyedContainer.options
        )
        return KeyedDecodingContainer(container)
    }

    func superDecoder() throws -> Decoder {
        return _CBORDecoder(data: self.data, options: self.options)
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        let decoder = _CBORDecoder(data: self.data, options: self.options)
        decoder.codingPath = [key]

        return decoder
    }

    fileprivate func anyCodingKeyForKey(_ key: Key) -> AnyCodingKey {
        return AnyCodingKey(key, useStringKey: self.options.useStringKeys)
    }
}

extension _CBORDecoder.KeyedContainer: CBORDecodingContainer {}
