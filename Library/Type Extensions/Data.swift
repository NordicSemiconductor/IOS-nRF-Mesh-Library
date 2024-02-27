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
import CoreBluetooth

extension UInt8 {
    public func mask(bits: Int) -> UInt8 {
        if (bits == 8) {
            return self
        } else {
            return self & ((1 << bits) - 1)
        }
    }
}

public extension Data {

    // Inspired by: https://stackoverflow.com/a/38024025/2115352

    /// Converts the required number of bytes, starting from `offset`
    /// to the value of return type.
    ///
    /// - parameter offset: The offset from where the bytes are to be read.
    /// - returns: The value of type of the return type.
    func read<R: FixedWidthInteger>(fromOffset offset: Int = 0) -> R {
        let length = MemoryLayout<R>.size
        
        #if swift(>=5.0)
        return subdata(in: offset ..< offset + length).withUnsafeBytes { $0.load(as: R.self) }
        #else
        return subdata(in: offset ..< offset + length).withUnsafeBytes { $0.pointee }
        #endif
    }
    
    func readUInt24(fromOffset offset: Int = 0) -> UInt32 {
        return UInt32(self[offset]) | UInt32(self[offset + 1]) << 8 | UInt32(self[offset + 2]) << 16
    }

    /// Read a specific number of bits from an offset in the Data object.
    /// Note that this method does no sanity checks. The Data object must be large enough to read the bits.
    /// 
    /// - parameters:
    ///   - numBits: The number of bits to read.
    ///   - fromOffset: The offset in bits in the Data to read from.
    func readBits(_ numBits: Int, fromOffset offset: Int) -> UInt64 {
        var res: UInt64 = 0

        var bitsLeft = numBits
        var currentOffset = offset % 8
        var currentShift = 0
        var bytePos = offset / 8

        while bitsLeft > 0 {
            let bitsFromFirstOctet = Swift.min(bitsLeft, 8 - currentOffset)

            if (currentOffset == 0) {
                res += UInt64(self[bytePos].mask(bits: bitsFromFirstOctet)) << currentShift
                
                currentShift += 8
                currentOffset = bitsFromFirstOctet % 8
                bytePos += 1
                bitsLeft -= 8
            } else {
                let firstOctet = (self[bytePos] >> currentOffset).mask(bits: bitsFromFirstOctet)
                
                if (bitsLeft > bitsFromFirstOctet) {
                    let bitsFromSecondOctet = Swift.min(8, bitsLeft) - bitsFromFirstOctet
                    let secondOctet = self[bytePos + 1].mask(bits: bitsFromSecondOctet) << (8 - currentOffset)
                    
                    res += UInt64(firstOctet + secondOctet) << currentShift
                    
                    currentShift += 8
                    currentOffset = bitsFromSecondOctet % 8
                    bytePos += 1
                    bitsLeft -= 8
                } else {
                    res += UInt64(firstOctet) << currentShift
                    
                    currentShift += 8
                    currentOffset = (currentOffset + bitsFromFirstOctet) % 8
                    bytePos += 1
                    bitsLeft -= bitsFromFirstOctet
                }
            }
        }
        
        return res
    }
    
    func readBigEndian<R: FixedWidthInteger>(fromOffset offset: Int = 0) -> R {
        let r: R = read(fromOffset: offset)
        return r.bigEndian
    }

    mutating func writeBits(value: UInt8, numBits: Int, atOffset offset: Int) {
        return writeBits(value: UInt64(value), numBits: numBits, atOffset: offset)
    }

    mutating func writeBits(value: UInt16, numBits: Int, atOffset offset: Int) {
        return writeBits(value: UInt64(value), numBits: numBits, atOffset: offset)
    }

    mutating func writeBits(value: UInt32, numBits: Int, atOffset offset: Int) {
        return writeBits(value: UInt64(value), numBits: numBits, atOffset: offset)
    }

    /// Write a specific number of bits from a value into the Data object.
    /// Note that this method does no sanity checks, the Data must be large enough to fit the bits before calling.
    /// - parameters:
    ///   - value: The value to read bits from.
    ///   - numBits: The number of bits to write.
    ///   - atOffset: The offset in bits in the Data object to write to.
    mutating func writeBits(value: UInt64, numBits: Int, atOffset offset: Int) {
        let currentOffset = offset % 8
        var writtenBits = 0
        var bytePos = offset / 8

        while writtenBits < numBits {
            let bitsLeft = numBits - writtenBits
            let octet = UInt8((value >> writtenBits) & ((1 << Swift.min(bitsLeft, 8)) - 1))
            
            if (currentOffset == 0) {
                self[bytePos] = octet

                bytePos += 1
                writtenBits += 8
            } else {
                let bitsToFirstByte = 8 - currentOffset
                self[bytePos] = self[bytePos] | ((octet & ((1 << bitsToFirstByte) - 1)) << currentOffset)

                if (bitsLeft > bitsToFirstByte) {
                    self[bytePos + 1] = octet >> bitsToFirstByte
                }

                bytePos += 1
                writtenBits += 8
            }
        }
    }
}

// Source: http://stackoverflow.com/a/42241894/2115352

public protocol DataConvertible {
    static func + (lhs: Data, rhs: Self) -> Data
    static func += (lhs: inout Data, rhs: Self)
}

extension DataConvertible {
    
    public static func + (lhs: Data, rhs: Self) -> Data {
        var value = rhs
        let data = withUnsafePointer(to: &value) { pointer -> Data in
            return Data(buffer: UnsafeBufferPointer(start: pointer, count: 1))
        }
        return lhs + data
    }
    
    public static func += (lhs: inout Data, rhs: Self) {
        lhs = lhs + rhs
    }
    
}

extension UInt8  : DataConvertible { }
extension UInt16 : DataConvertible { }
extension UInt32 : DataConvertible { }
extension UInt64 : DataConvertible { }
extension Int8   : DataConvertible { }
extension Int16  : DataConvertible { }
extension Int32  : DataConvertible { }
extension Int64  : DataConvertible { }

extension Int    : DataConvertible { }
extension UInt   : DataConvertible { }
extension Float  : DataConvertible { }
extension Double : DataConvertible { }

extension String : DataConvertible {
    
    public static func + (lhs: Data, rhs: String) -> Data {
        guard let data = rhs.data(using: .utf8) else { return lhs }
        return lhs + data
    }
    
}

extension Data : DataConvertible {
    
    public static func + (lhs: Data, rhs: Data) -> Data {
        var data = Data()
        data.append(lhs)
        data.append(rhs)
        
        return data
    }
    
    public static func + (lhs: Data, rhs: Data?) -> Data {
        guard let rhs = rhs else {
            return lhs
        }
        var data = Data()
        data.append(lhs)
        data.append(rhs)
        
        return data
    }
    
}

extension Bool : DataConvertible {
    
    public static func + (lhs: Data, rhs: Bool) -> Data {
        if rhs {
            return lhs + UInt8(0x01)
        } else {
            return lhs + UInt8(0x00)
        }
    }
    
}

extension CBUUID {
    
    convenience init(dataLittleEndian data: Data) {
        self.init(data: Data(data.reversed()))
    }
    
}
