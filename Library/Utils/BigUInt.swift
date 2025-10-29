/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

/// Represents a big decimal integer, up to 32 digits (14 bytes).
public struct BigUInt: Sendable, CustomStringConvertible {
    // Internal representation: little-endian bytes (LSB first).
    private var littleEndianBytes: [UInt8]

    /// Maximum decimal digits supported.
    public static let maxDecimalDigits = 32
    /// Maximum binary bytes used internally for representation.
    public static let maxBytes = 14

    /// Initialize from an ASCII decimal string using only characters '0'..'9'.
    ///
    /// Returns nil for empty string, non-ASCII digits or strings longer than `maxDecimalDigits`.
    public init?(decimalString: String) {
        guard !decimalString.isEmpty else { return nil }
        // Ensure only ASCII digits 0-9
        guard decimalString.utf8.allSatisfy({ $0 >= 48 && $0 <= 57 }) else { return nil }
        if decimalString.count > BigUInt.maxDecimalDigits { return nil }

        // Start from zero
        self.littleEndianBytes = [0]

        for ascii in decimalString.utf8 {
            let digit = Int(ascii - 48)
            // multiply current value by 10
            if !self.multiplyBy10() { return nil }
            // add digit
            if !self.addSmall(UInt8(digit)) { return nil }
        }
        normalize()
    }

    /// Export to big-endian `Data` of specified size (pad with leading zeros).
    ///
    /// Returns nil if the value doesn't fit in `sizeInBytes` bytes or if `sizeInBytes` is less than 1.
    public func toData(sizeInBytes: Int) -> Data? {
        guard sizeInBytes > 0 else { return nil }
        // Build minimal big-endian data
        var trimmed = littleEndianBytes
        while trimmed.count > 1 && trimmed.last == 0 {
            trimmed.removeLast()
        }
        let minimal = Data(trimmed.reversed())
        if minimal.count > sizeInBytes { return nil }
        if minimal.count == sizeInBytes { return minimal }
        let padding = Data(repeating: 0, count: sizeInBytes - minimal.count)
        return padding + minimal
    }

    // MARK: - New public accessors requested by user

    /// Returns the value as `UInt` if it fits, otherwise returns `nil`.
    public func asUInt() -> UInt? {
        var value: UInt = 0
        // Process most significant byte first
        for b in littleEndianBytes.reversed() {
            // Check overflow on left shift by 8
            if value > (UInt.max >> 8) {
                return nil
            }
            value = (value << 8) | UInt(b)
        }
        return value
    }

    /// Returns the decimal representation as ASCII digits (0-9).
    ///
    /// Always returns at least one character: "0" for zero value.
    public func toDecimalString() -> String {
        // Quick path for zero
        if littleEndianBytes.count == 1 && littleEndianBytes[0] == 0 {
            return "0"
        }
        var temp = self
        var digits: [UInt8] = []
        while !(temp.littleEndianBytes.count == 1 && temp.littleEndianBytes[0] == 0) {
            let (quotient, remainder) = temp.dividingBy10()
            digits.append(UInt8(remainder))
            temp = quotient
        }
        // digits collected in reverse order
        let asciiDigits = digits.reversed().map { $0 + 48 }
        return String(bytes: asciiDigits, encoding: .ascii) ?? "0"
    }

    /// Generate a random `BigUInt` from an ASCII decimal string of the given length.
    ///
    /// - parameter length: number of decimal digits to generate (must be between 1 and `maxDecimalDigits`).
    /// - returns: a `BigUInt` constructed from a random decimal string of exactly `length` digits (leading zeros are allowed),
    ///            or nil if length is invalid.
    public static func random(length: Int) -> BigUInt? {
        guard length >= 1 && length <= BigUInt.maxDecimalDigits else { return nil }
        // Generate ASCII digits '0'..'9'. Leading zeros are allowed.
        var bytes = [UInt8]()
        bytes.reserveCapacity(length)
        for _ in 0..<length {
            let digit = UInt8(Int.random(in: 0...9))
            bytes.append(48 + digit)
        }
        // Construct the ASCII string and parse it. The initializer will succeed because
        // we ensured length <= maxDecimalDigits and all characters are ASCII digits.
        guard let s = String(bytes: bytes, encoding: .ascii) else { return nil }
        return BigUInt(decimalString: s)
    }
    
    // MARK: - CustomStringConvertible
    
    public var description: String {
        return toDecimalString()
    }
    
    // MARK: - Private helpers

    private mutating func normalize() {
        while littleEndianBytes.count > 1 && littleEndianBytes.last == 0 {
            littleEndianBytes.removeLast()
        }
    }

    private mutating func multiplyBy10() -> Bool {
        var carry: UInt16 = 0
        for i in 0..<littleEndianBytes.count {
            let product = UInt16(littleEndianBytes[i]) * 10 + carry
            littleEndianBytes[i] = UInt8(product & 0xff)
            carry = product >> 8
        }
        while carry > 0 {
            if littleEndianBytes.count >= BigUInt.maxBytes { return false }
            littleEndianBytes.append(UInt8(carry & 0xff))
            carry >>= 8
        }
        return true
    }

    private mutating func addSmall(_ value: UInt8) -> Bool {
        var carry = UInt16(value)
        var i = 0
        while carry > 0 {
            if i >= littleEndianBytes.count {
                if littleEndianBytes.count >= BigUInt.maxBytes { return false }
                littleEndianBytes.append(0)
            }
            let sum = UInt16(littleEndianBytes[i]) + carry
            littleEndianBytes[i] = UInt8(sum & 0xff)
            carry = sum >> 8
            i += 1
        }
        return true
    }

    /// Non-mutating division by 10 returning (quotient, remainder).
    private func dividingBy10() -> (BigUInt, Int) {
        var resultBytes = Array(repeating: UInt8(0), count: littleEndianBytes.count)
        var remainder: UInt16 = 0
        // Process from most significant byte to least significant
        for idx in (0..<(littleEndianBytes.count)).reversed() {
            let acc = (remainder << 8) | UInt16(littleEndianBytes[idx])
            let q = acc / 10
            remainder = acc % 10
            resultBytes[idx] = UInt8(q & 0xff)
        }
        var q = BigUInt(decimalString: "0")!
        q.littleEndianBytes = resultBytes
        q.normalize()
        return (q, Int(remainder))
    }
}
