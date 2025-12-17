/*
 * Copyright (c) 2017-2018 Runtime Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import CommonCrypto

public extension Data {
    
    // MARK: - Convert data to and from types
    
    init<T>(from value: T) {
        var value = value
        self = withUnsafePointer(to: &value) { (pointer) -> Data in
            Data(buffer: UnsafeBufferPointer(start: pointer, count: 1))
        }
    }
    
    func read<T: FixedWidthInteger>(offset: Int = 0) -> T {
        let length = MemoryLayout<T>.size
        
        #if swift(>=5.0)
        return subdata(in: offset ..< offset + length).withUnsafeBytes { $0.load(as: T.self) }
        #else
        return subdata(in: offset ..< offset + length).withUnsafeBytes { $0.pointee }
        #endif
    }
    
    func readBigEndian<R: FixedWidthInteger>(offset: Int = 0) -> R {
        let r: R = read(offset: offset)
        return r.bigEndian
    }
    
    // MARK: - Hex Encoding
    
    struct HexEncodingOptions: OptionSet {
        public static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
        public static let byteSpacing = HexEncodingOptions(rawValue: 1 << 1)
        public static let prepend0x = HexEncodingOptions(rawValue: 1 << 2)
        public static let twoByteSpacing = HexEncodingOptions(rawValue: 1 << 3)
        public static let reverseEndianness = HexEncodingOptions(rawValue: 1 << 4)
        
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        guard !isEmpty else { return "0 bytes" }
        
        var format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        if options.contains(.byteSpacing) {
            format.append(" ")
        }

        var bytes = self
        if options.contains(.reverseEndianness) {
            bytes.reverse()
        }
        var body: String = options.contains(.prepend0x) ? "0x" : ""
        switch options {
        case .byteSpacing:
            body.reserveCapacity(
                options.contains(.prepend0x) ? 1 : 0 + bytes.count * 3
            )
        default:
            body.reserveCapacity(
                options.contains(.prepend0x) ? 1 : 0 + bytes.count * 2
            )
        }
        
        autoreleasepool {
            body.append(contentsOf: bytes.map {
                String(format: format, $0)
            }.joined())
        }
        
        if options.contains(.twoByteSpacing) {
            autoreleasepool {
                body = body.inserting(separator: " ", every: 4)
            }
        }

        return body
    }
    
    // MARK: - Fragmentation
    
    func fragment(size: Int) -> [Data] {
        return stride(from: 0, to: self.count, by: size).map {
            Data(self[$0..<Swift.min($0 + size, self.count)])
        }
    }
    
    // MARK: - SHA 256
    
    func sha256() -> [UInt8] {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(count), &hash)
        }
        return hash
    }
}

