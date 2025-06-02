/*
 * Copyright (c) 2017-2018 Runtime Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

// MARK: - McuMgrImage

public class McuMgrImage {
    
    public static let IMG_HASH_LEN = 32
    
    public let header: McuMgrImageHeader
    public let tlv: McuMgrImageTlv
    public let data: Data
    public let hash: Data
    
    public init(data: Data) throws {
        self.data = data
        let header = try McuMgrImageHeader(data: data)
        self.header = header
        let offset = Int(header.headerSize) + Int(header.imageSize)
        var tlv = try McuMgrImageTlv(data: data, imageHeader: header, at: offset)
        if let info = tlv.tlvInfo, info.isProtected {
            tlv = try McuMgrImageTlv(data: data, imageHeader: header, at: offset + Int(info.total))
        }
        self.tlv = tlv
        if let hash = tlv.hash {
            self.hash = hash
        } else {
            throw McuMgrImageParseError.hashNotFound
        }
    }
}

// MARK: - McuMgrImageHeader

public class McuMgrImageHeader {
    
    public static let IMG_HEADER_LEN = 24
    
    public static let IMG_HEADER_MAGIC: UInt32 = 0x96f3b83d
    public static let IMG_HEADER_MAGIC_V1: UInt32 = 0x96f3b83c
    
    public static let MAGIC_OFFSET = 0
    public static let LOAD_ADDR_OFFSET = 4
    public static let HEADER_SIZE_OFFSET = 8
    public static let IMAGE_SIZE_OFFSET = 12
    public static let FLAGS_OFFSET = 16
    
    public let magic: UInt32
    public let loadAddr: UInt32
    public let headerSize: UInt16
    // __pad1: UInt16
    public let imageSize: UInt32
    public let flags: UInt32
    public let version: McuMgrImageVersion
    // __pad2 UInt16
    
    public init(data: Data) throws {
        magic = data.read(offset: McuMgrImageHeader.MAGIC_OFFSET)
        loadAddr = data.read(offset: McuMgrImageHeader.LOAD_ADDR_OFFSET)
        headerSize = data.read(offset: McuMgrImageHeader.HEADER_SIZE_OFFSET)
        imageSize = data.read(offset: McuMgrImageHeader.IMAGE_SIZE_OFFSET)
        flags = data.read(offset: McuMgrImageHeader.FLAGS_OFFSET)
        version = McuMgrImageVersion(data: data)
        if magic != McuMgrImageHeader.IMG_HEADER_MAGIC && magic != McuMgrImageHeader.IMG_HEADER_MAGIC_V1 {
            throw McuMgrImageParseError.invalidHeaderMagic
        }
    }
    
    public func isLegacy() -> Bool {
        return magic == McuMgrImageHeader.IMG_HEADER_MAGIC_V1
    }
}

// MARK: - McuMgrImageVersion

public class McuMgrImageVersion {
    
    public static let VERSION_OFFSET = 20
    
    public let major: UInt8
    public let minor: UInt8
    public let revision: UInt16
    public let build: UInt32
    
    public init(data: Data, offset: Int = VERSION_OFFSET) {
        major = data[offset]
        minor = data[offset + 1]
        revision = data.read(offset: offset + 2)
        build = data.read(offset: offset + 4)
    }
}

// MARK: - McuMgrImageTlv

/**
 * See [link for more info on the image TLV types](https://github.com/mcu-tools/mcuboot/blob/9331c924ba69a32e142d1bf724443d99405c3323/boot/bootutil/include/bootutil/image.h#L95).
 */
public struct McuMgrImageTlv {
    
    public static let IMG_TLV_SHA256_V1: UInt8 = 0x01
    public static let IMG_TLV_SHA256: UInt8 = 0x10
    /** SHA384 of image hdr and body. */
    public static let IMG_TLV_SHA384 = 0x11
    /** SHA512 of image hdr and body. */
    public static let IMG_TLV_SHA512 = 0x12
    public static let IMG_TLV_RSA2048_PSS: UInt8 = 0x20
    public static let IMG_TLV_ECDSA224: UInt8 = 0x21
    public static let IMG_TLV_ECDSA256: UInt8 = 0x22
    public static let IMG_TLV_RSA3072_PSS: UInt8 = 0x23
    public static let IMG_TLV_ED25519: UInt8 = 0x24
    public static let IMG_TLV_ENC_RSA2048: UInt8 = 0x30
    public static let IMG_TLV_ENC_KW128: UInt8 = 0x31
    public static let IMG_TLV_ENC_EC256: UInt8 = 0x32
    public static let IMG_TLV_DEPENDENCY = 0x40
    
    public static let IMG_TLV_UNPROTECTED_INFO_MAGIC: UInt16 = 0x6907
    public static let IMG_TLV_PROTECTED_INFO_MAGIC: UInt16 = 0x6908
    
    public var tlvInfo: McuMgrImageTlvInfo?
    public var trailerTlvEntries: [McuMgrImageTlvTrailerEntry]
    public var hash: Data?
    
    public init(data: Data, imageHeader: McuMgrImageHeader, at offset: Int) throws {
        var localOffset = offset
        var end = data.count
        
        // Parse the tlv info header (Not included in legacy version).
        if !imageHeader.isLegacy() {
            let tlvInfo = try McuMgrImageTlvInfo(data: data, offset: localOffset)
            localOffset += MemoryLayout<McuMgrImageTlvInfo>.size
            end = localOffset + Int(tlvInfo.total)
            self.tlvInfo = tlvInfo
        }
        
        // Parse each tlv entry.
        trailerTlvEntries = [McuMgrImageTlvTrailerEntry]()
        var hashEntry: McuMgrImageTlvTrailerEntry?
        while localOffset + McuMgrImageTlvTrailerEntry.MIN_SIZE < end {
            let tlvEntry = try McuMgrImageTlvTrailerEntry(data: data, offset: localOffset)
            trailerTlvEntries.append(tlvEntry)
            
            if tlvEntry.type == McuMgrImageTlv.IMG_TLV_SHA384
                || tlvEntry.type == McuMgrImageTlv.IMG_TLV_SHA512 {
                hashEntry = tlvEntry
            }
            
            if imageHeader.isLegacy() && tlvEntry.type == McuMgrImageTlv.IMG_TLV_SHA256_V1 ||
                !imageHeader.isLegacy() && tlvEntry.type == McuMgrImageTlv.IMG_TLV_SHA256 {
                hashEntry = tlvEntry
            }
            
            // Increment offset.
            localOffset += tlvEntry.size
        }
        
        hash = hashEntry?.value
    }
}

// MARK: - McuMgrImageTlvInfo

/// Represents the header which starts immediately after the image data and
/// precedes the image trailer TLV.
public struct McuMgrImageTlvInfo {
    
    public let magic: UInt16
    public let total: UInt16
    
    public init(data: Data, offset: Int) throws {
        magic = data.read(offset: offset)
        total = data.read(offset: offset + MemoryLayout<UInt16>.size)
        if magic != McuMgrImageTlv.IMG_TLV_UNPROTECTED_INFO_MAGIC
            && magic != McuMgrImageTlv.IMG_TLV_PROTECTED_INFO_MAGIC {
            throw McuMgrImageParseError.invalidTlvInfoMagic
        }
    }
    
    public var isProtected: Bool {
        magic == McuMgrImageTlv.IMG_TLV_PROTECTED_INFO_MAGIC
    }
}

// MARK: - McuMgrImageTlvTrailerEntry

/// Represents an entry in the image TLV trailer.
public class McuMgrImageTlvTrailerEntry {
    
    /// The minimum size of the TLV entry (length = 0).
    public static let MIN_SIZE = 4
    
    public let type: UInt8
    public let length: UInt16
    public let value: Data
    
    /// Size of the entire TLV entry in bytes.
    public let size: Int
    
    public init(data: Data, offset: Int) throws {
        guard offset + McuMgrImageTlvTrailerEntry.MIN_SIZE < data.count else {
            throw McuMgrImageParseError.insufficientData
        }
        
        var offset = offset
        type = data[offset]
        // Advance 1 byte for read
        offset += MemoryLayout<UInt8>.size
        // Advance 1 byte for padding (MIN_SIZE = 4)
        offset += MemoryLayout<UInt8>.size
        length = data.read(offset: offset)
        offset += MemoryLayout<UInt16>.size
        value = data[Int(offset)..<Int(offset + Int(length))]
        size = McuMgrImageTlvTrailerEntry.MIN_SIZE + Int(length)
    }
}

// MARK: - McuMgrImageParseError

public enum McuMgrImageParseError: Error {
    case invalidHeaderMagic
    case invalidTlvInfoMagic
    case insufficientData
    case hashNotFound
}

// MARK: - McuMgrImageParseError

extension McuMgrImageParseError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .invalidHeaderMagic:
            return "Invalid Header Magic Number. Are You Trying to DFU an Image That Has Not Been Properly Signed?"
        case .invalidTlvInfoMagic:
            return "Invalid TLV Info Magic Number. Are You Trying to DFU an Image That Has Not Been Properly Signed Again?"
        case .insufficientData:
            return "Insufficient Data."
        case .hashNotFound:
            return "Hash Not Found."
        }
    }
}
