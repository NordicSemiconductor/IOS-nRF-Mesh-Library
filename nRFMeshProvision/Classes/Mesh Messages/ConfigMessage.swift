//
//  ConfigMessage.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 09/06/2019.
//

import Foundation

public protocol ConfigMessage: MeshMessage {
    // Empty
}

public protocol ConfigAppKeyMessage: ConfigMessage {
    /// The Network Key Index.
    var networkKeyIndex: KeyIndex { get }
    /// Application Key Index.
    var applicationKeyIndex: KeyIndex { get }
}

internal extension ConfigAppKeyMessage {
    
    /// Encodes Network Key Index and Application Key Index in 3 bytes
    /// using Little Endian. The bound Network Key is used.
    ///
    /// - returns: Key Indexes encoded in 2 bytes.
    func encodeNetKeyAndAppKeyIndex() -> Data {
        let netKeyIndexAndAppKeyIndex: UInt32 = UInt32(networkKeyIndex) << 12 | UInt32(applicationKeyIndex)
        return (Data() + netKeyIndexAndAppKeyIndex.littleEndian).dropLast()
    }
    
    /// Decodes the Network Key Index and Application Key Index from
    /// 3 bytes at given offset.
    ///
    /// There are no any checks whether the data at the given offset
    /// are valid, or even if the offset is not outside of the data range.
    ///
    /// - parameter data: The data from where the indexes should be read.
    /// - parameter offset: The offset from where to read the indexes.
    /// - returns: Decoded Key Indexes.
    static func decodeNetKeyAndAppKeyIndex(from data: Data, at offset: Int) -> (networkKeyIndex: KeyIndex, applicationKeyIndex: KeyIndex) {
        let networkKeyIndex: KeyIndex = UInt16(data[offset + 2]) << 4 | UInt16(data[offset + 1] >> 4)
        let applicationKeyIndex: KeyIndex = UInt16(data[offset + 1] & 0x0F) << 8 | UInt16(data[offset])
        return (networkKeyIndex, applicationKeyIndex)
    }
    
}
