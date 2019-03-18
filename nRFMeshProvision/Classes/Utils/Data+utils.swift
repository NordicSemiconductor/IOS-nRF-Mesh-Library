//
//  Data+utils.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 22/12/2017.
//

import Foundation

public extension Data {
    //Hex string to Data representation
    //Inspired by https://stackoverflow.com/questions/26501276/converting-hex-string-to-nsdata-in-swift
    public init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hexString.index(hexString.startIndex, offsetBy: i*2)
            let k = hexString.index(j, offsetBy: 2)
            let bytes = hexString[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
    
    public init(fromInteger anInteger: UInt16) {
        self = Data([UInt8((anInteger & 0xFF00) >> 8), UInt8(anInteger & 0x00FF)])
    }
    
    public init(fromInt32 anInteger: UInt32) {
        self = Data([UInt8((anInteger & 0xFF000000) >> 24), UInt8((anInteger & 0x00FF0000) >> 16), UInt8((anInteger & 0x0000FF00) >> 8), UInt8(anInteger & 0x000000FF)])
    }

    public func hexString() -> String {
        return self.reduce("") { string, byte in
            string + String(format: "%02X", byte)
        }
   }

    func leftPad(length: Int) -> Data {
        guard length > self.count else {
            return self
        }
   
        let paddedData = NSMutableData(capacity: length)!
        paddedData.resetBytes(in: NSRange(location:0, length: length))
        let dataOffset = length - self.count
        let bytes = self.withUnsafeBytes { (aByte) -> UnsafeRawPointer in
            return UnsafeRawPointer(aByte)
        }
        paddedData.replaceBytes(in: NSRange(location: dataOffset, length: self.count), withBytes: bytes)
        return paddedData as Data
    }
    
    var uint16: UInt16 {
        return withUnsafeBytes { $0.pointee }
    }
    
    var uint16BigEndian: UInt16 {
        return UInt16(bigEndian: withUnsafeBytes { $0.pointee })
    }
    
    var int16: Int16 {
        return withUnsafeBytes { $0.pointee }
    }
    
    var int16BigEndian: Int16 {
        return Int16(bigEndian: withUnsafeBytes { $0.pointee })
    }
    
    var int32: Int32 {
        return withUnsafeBytes { $0.pointee }
    }
    
    var int32BigEndian: Int32 {
        return Int32(bigEndian: withUnsafeBytes { $0.pointee })
    }
}
