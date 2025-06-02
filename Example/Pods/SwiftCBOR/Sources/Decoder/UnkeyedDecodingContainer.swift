import Foundation

extension _CBORDecoder {
    final class UnkeyedContainer {
        var codingPath: [CodingKey]

        var nestedCodingPath: [CodingKey] {
            return self.codingPath + [AnyCodingKey(intValue: self.count ?? 0)]
        }

        var userInfo: [CodingUserInfoKey: Any]

        var data: ArraySlice<UInt8>
        var index: Data.Index

        let options: CodableCBORDecoder._Options

        lazy var count: Int? = {
            do {
                let format = try self.readByte()
                switch format {
                case 0x80...0x97 :
                    return Int(format & 0x1F)
                case 0x98:
                    return Int(try read(UInt8.self))
                case 0x99:
                    return Int(try read(UInt16.self))
                case 0x9a:
                    return Int(try read(UInt32.self))
                case 0x9b:
                    return Int(try read(UInt64.self))
                case 0x9f:
                    // FIXME: This is a very inefficient way of doing this. Really we should be modifying the
                    // nestedContainers code so that if we're working with an array that has a break at the
                    // end it creates the containers as it goes, rather than first calculating the count
                    // (which involves going through all the bytes) and then going back through the data and
                    // decoding each item in the array.
                    let nextIndex = self.data.startIndex.advanced(by: 1)
                    let remainingData = self.data.suffix(from: nextIndex)
                    return try? CBORDecoder(input: remainingData).readUntilBreak().count
                default:
                    return nil
                }
            } catch {
                return nil
            }
        }()

        var currentIndex: Int = 0

        lazy var nestedContainers: [CBORDecodingContainer] = {
            guard let count = self.count else {
                return []
            }

            var nestedContainers: [CBORDecodingContainer] = []

            do {
                for _ in 0..<count {
                    let container = try self.decodeContainer()
                    nestedContainers.append(container)
                }
            } catch {
                fatalError("\(error)") // FIXME
            }

            self.currentIndex = 0

            return nestedContainers
        }()

        init(data: ArraySlice<UInt8>, codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], options: CodableCBORDecoder._Options) {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.data = data
            self.index = self.data.startIndex
            self.options = options
        }

        var isAtEnd: Bool {
            guard let count = self.count else {
                return true
            }

            return currentIndex >= count
        }

        var isEmpty: Bool {
            if let count = self.count, count == 0 {
                return true
            }
            return false
        }

        func checkCanDecodeValue() throws {
            guard !self.isAtEnd else {
                throw DecodingError.dataCorruptedError(in: self, debugDescription: "Unexpected end of data")
            }
        }

    }
}

extension _CBORDecoder.UnkeyedContainer: UnkeyedDecodingContainer {

    func decodeNil() throws -> Bool {
        if self.isEmpty {
            return false
        }
        try checkCanDecodeValue()
        defer { self.currentIndex += 1 }

        switch self.nestedContainers[self.currentIndex] {
        case let singleValueContainer as _CBORDecoder.SingleValueContainer:
            return singleValueContainer.decodeNil()
        case is _CBORDecoder.UnkeyedContainer, is _CBORDecoder.KeyedContainer<AnyCodingKey>:
            return false
        default:
            let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "cannot decode nil for index: \(self.currentIndex)")
            throw DecodingError.typeMismatch(Any?.self, context)
        }
    }

    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        try checkCanDecodeValue()
        defer { self.currentIndex += 1 }

        let container = self.nestedContainers[self.currentIndex]
        let decoder = CodableCBORDecoder()
        decoder.setOptions(self.options)
        let value = try decoder.decode(T.self, from: container.data)

        return value
    }

    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        try checkCanDecodeValue()
        defer { self.currentIndex += 1 }

        let container = self.nestedContainers[self.currentIndex] as! _CBORDecoder.UnkeyedContainer

        return container
    }

    func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        try checkCanDecodeValue()
        defer { self.currentIndex += 1 }

        let anyCodingKeyContainer = self.nestedContainers[self.currentIndex] as! _CBORDecoder.KeyedContainer<AnyCodingKey>

        let container = _CBORDecoder.KeyedContainer<NestedKey>(
            data: anyCodingKeyContainer.data,
            codingPath: anyCodingKeyContainer.codingPath,
            userInfo: anyCodingKeyContainer.userInfo,
            options: anyCodingKeyContainer.options
        )
        return KeyedDecodingContainer(container)
    }

    func superDecoder() throws -> Decoder {
        return _CBORDecoder(data: self.data, options: self.options)
    }
}

extension _CBORDecoder.UnkeyedContainer {
    func decodeContainer() throws -> CBORDecodingContainer {
        try checkCanDecodeValue()
        defer { self.currentIndex += 1 }

        let startIndex = self.index

        let length: Int
        let format = try self.readByte()

        switch format {
        // Integers
        case 0x00...0x1b, 0x20...0x3b:
            length = try getLengthOfItem(format: format, startIndex: startIndex)
        // Byte strings
        case 0x40...0x5b:
            length = try getLengthOfItem(format: format, startIndex: startIndex)
        // Terminated by break
        case 0x5f:
            // TODO: Is this ever going to get hit?
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Handling byte strings with break bytes is not supported yet")
        // UTF8 strings
        case 0x60...0x7b:
            length = try getLengthOfItem(format: format, startIndex: startIndex)
        // Terminated by break
        case 0x7f:
            // FIXME
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Handling UTF8 strings with break bytes is not supported yet")
        // Arrays
        case 0x80...0x9f:
            let container = _CBORDecoder.UnkeyedContainer(data: self.data.suffix(from: startIndex), codingPath: self.nestedCodingPath, userInfo: self.userInfo, options: self.options)
            _ = container.nestedContainers

            self.index = container.index
            // Ensure that we're moving the index along for indefinite arrays so
            // that we don't try and decode the break byte (0xff)
            if format == 0x9f {
                if self.data.suffix(from: self.index).count > 0 {
                    self.index = self.index.advanced(by: 1)
                }
            }
            return container
        // Maps
        case 0xa0...0xbf:
            let container = _CBORDecoder.KeyedContainer<AnyCodingKey>(data: self.data.suffix(from: startIndex), codingPath: self.nestedCodingPath, userInfo: self.userInfo, options: self.options)
            let _ = try container.nestedContainers() // FIXME

            self.index = container.index
            // Ensure that we're moving the index along for indefinite arrays so
            // that we don't try and decode the break byte (0xff)
            if format == 0xbf {
                if self.data.suffix(from: self.index).count > 0 {
                    self.index = self.index.advanced(by: 1)
                }
            }
            return container
        case 0xc0:
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Handling text-based date/time is not supported yet")
        // Tagged value (epoch-baed date/time)
        case 0xc1:
            length = try getLengthOfItem(format: try self.peekByte(), startIndex: startIndex.advanced(by: 1)) + 1
        case 0xc2...0xdb:
            // FIXME
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Handling tags (other than epoch-based date/time) is not supported yet")
        case 0xe0...0xfb, 0xff:
            length = try getLengthOfItem(format: format, startIndex: startIndex.advanced(by: 1))
        default:
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Invalid format: \(format)")
        }

        let range: Range<Data.Index> = startIndex..<self.index.advanced(by: length)
        self.index = range.upperBound

        let container = _CBORDecoder.SingleValueContainer(data: self.data[range.startIndex..<(range.endIndex)], codingPath: self.codingPath, userInfo: self.userInfo, options: self.options)

        return container
    }

    func getLengthOfItem(format: UInt8, startIndex: Data.Index) throws -> Int {
        switch format {
        // Integers
        // Small positive and negative integers
        case 0x00...0x17, 0x20...0x37:
            return 0
        // UInt8 in following byte
        case 0x18, 0x38:
            return 1
        // UInt16 in following bytes
        case 0x19, 0x39:
            return 2
        // UInt32 in following bytes
        case 0x1a, 0x3a:
            return 4
        // UInt64 in following bytes
        case 0x1b, 0x3b:
            return 8
        // Byte strings
        case 0x40...0x57:
            return try CBORDecoder(input: [0]).readLength(format, base: 0x40)
        case 0x58:
            let remainingData = self.data.suffix(from: startIndex.advanced(by: 1))
            return try CBORDecoder(input: remainingData).readLength(format, base: 0x40) + 1
        case 0x59:
            let remainingData = self.data.suffix(from: startIndex.advanced(by: 1))
            return try CBORDecoder(input: remainingData).readLength(format, base: 0x40) + 2
        case 0x5a:
            let remainingData = self.data.suffix(from: startIndex.advanced(by: 1))
            return try CBORDecoder(input: remainingData).readLength(format, base: 0x40) + 4
        case 0x5b:
            let remainingData = self.data.suffix(from: startIndex.advanced(by: 1))
            return try CBORDecoder(input: remainingData).readLength(format, base: 0x40) + 8
        // UTF8 strings
        case 0x60...0x77:
            return try CBORDecoder(input: [0]).readLength(format, base: 0x60)
        case 0x78:
            let remainingData = self.data.suffix(from: startIndex.advanced(by: 1))
            return try CBORDecoder(input: remainingData).readLength(format, base: 0x60) + 1
        case 0x79:
            let remainingData = self.data.suffix(from: startIndex.advanced(by: 1))
            return try CBORDecoder(input: remainingData).readLength(format, base: 0x60) + 2
        case 0x7a:
            let remainingData = self.data.suffix(from: startIndex.advanced(by: 1))
            return try CBORDecoder(input: remainingData).readLength(format, base: 0x60) + 4
        case 0x7b:
            let remainingData = self.data.suffix(from: startIndex.advanced(by: 1))
            return try CBORDecoder(input: remainingData).readLength(format, base: 0x60) + 8
        case 0xe0...0xf3:
            return 0
        case 0xf4, 0xf5, 0xf6, 0xf7, 0xf8:
            return 0
        case 0xf9:
            return 2
        case 0xfa:
            return 4
        case 0xfb:
            return 8
        case 0xff:
            return 0
        default:
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "Invalid format for getting length of item: \(format)")
        }

    }
}

extension _CBORDecoder.UnkeyedContainer: CBORDecodingContainer {}
