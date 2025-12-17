//
//  McuMgrManifest.swift
//  nRF Connect Device Manager
//
//  Created by Dinesh Harjani on 18/1/22.
//  Copyright © 2022 Nordic Semiconductor ASA. All rights reserved.
//

import Foundation

// MARK: - McuMgrManifest

public struct McuMgrManifest: Codable {
    
    // MARK: Public Properties
    
    public let formatVersion: Int
    public let time: Int
    public let files: [File]
    public let name: String?
    
    enum CodingKeys: String, CodingKey {
        case formatVersion = "format-version"
        case time, files, name
    }
    
    static let LoadAddressRegEx: NSRegularExpression! =
        try? NSRegularExpression(pattern: #"\"load_address\":0x[0-9a-z]+,"#, options: [.caseInsensitive])
    
    // MARK: Init
    
    public init(from url: URL) throws {
        guard let data = try? Data(contentsOf: url),
              let stringData = String(data: data, encoding: .utf8) else {
                  throw Error.unableToRead
        }
        
        let stringWithoutSpaces = String(stringData.filter { !" \n\t\r".contains($0) })
        let modString = Self.LoadAddressRegEx.stringByReplacingMatches(in: stringWithoutSpaces, options: [], range: NSRange(stringWithoutSpaces.startIndex..<stringWithoutSpaces.endIndex, in: stringWithoutSpaces), withTemplate: " ")
        guard let cleanData = modString.data(using: .utf8) else {
            throw Error.unableToParseJSON
        }
        do {
            self = try JSONDecoder().decode(McuMgrManifest.self, from: cleanData)
        } catch {
            throw Error.unableToDecodeJSON
        }
    }
    
    // MARK: API
    
    public func envelopeFile() -> File? {
        files.first(where: { $0.content == .suitEnvelope })
    }
}

// MARK: - McuMgrManifest.File

extension McuMgrManifest {
    
    public struct File: Codable {
        
        // MARK: Public Properties
        
        public let size: Int
        public let file: String
        public let modTime: Int
        public let mcuBootVersion: String?
        /**
         If not present when parsing a Manifest from .json, slot 1 (Secondary)
         is assumed as the binary's target.
         */
        public let slot: Int
        public let type: String
        public let content: ContentType
        public let board: String
        public let soc: String
        public let loadAddress: Int
        public let bootloader: BootloaderInfoResponse.Bootloader
        
        public var image: Int {
            _image ?? _imageIndex ?? _partition ?? 0
        }
        
        /**
         Returns true if the MCUBoot Version in the Manifest specifically lists 'XIP' Support,
         and **NOT** if specific `slot` information is included. Even though that would also be
         an acceptable manner to detect Direct XIP Support.
         */
        public var supportsDirectXIP: Bool {
            _mcuBootXipVersion != nil
        }
        
        // MARK: Private
        
        private let _partition: Int?
        private let _image: Int?
        private let _imageIndex: Int?
        private let _mcuBootXipVersion: String?
        
        // MARK: JSON Encoding
        
        // swiftlint:disable nesting
        enum CodingKeys: String, CodingKey {
            case size, file, slot
            case modTime = "modtime"
            case mcuBootVersion = "version_MCUBOOT"
            case type, board, soc
            case loadAddress = "load_address"
            case _partition = "partition"
            case _image = "image"
            case _imageIndex = "image_index"
            case _mcuBootXipVersion = "version_MCUBOOT+XIP"
        }
        
        // MARK: Init
        
        public init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            size = try values.decode(Int.self, forKey: .size)
            file = try values.decode(String.self, forKey: .file)
            modTime = try values.decode(Int.self, forKey: .modTime)
            type = try values.decode(String.self, forKey: .type)
            board = try values.decode(String.self, forKey: .board)
            soc = try values.decode(String.self, forKey: .soc)
            content = ContentType(rawValue: type) ?? .unknown
            
            let slotString = try? values.decode(String.self, forKey: .slot)
            slot = Int(slotString ?? "") ?? 1
            
            let version = try? values.decode(String.self, forKey: .mcuBootVersion)
            _mcuBootXipVersion = try? values.decode(String.self, forKey: ._mcuBootXipVersion)
            // We don't know which one will be present. Examples we've seen suggest if it's not
            // Direct XIP, then the standard 'mcuBoot_version' will be there. But we can't discard
            // both being present. In which case, 'XIP' is more feature-complete.
            mcuBootVersion = _mcuBootXipVersion ?? version
            if content == .suitEnvelope {
                bootloader = .suit
            } else if mcuBootVersion != nil {
                bootloader = .mcuboot
            } else {
                bootloader = .unknown
            }
            
            let loadAddressString: String? = try? values.decode(String.self, forKey: .loadAddress)
            let loadAddressInt: Int
            if let loadAddressString {
                loadAddressInt = Int(loadAddressString) ?? .zero
            } else {
                loadAddressInt = (try? values.decode(Int.self, forKey: .loadAddress)) ?? .zero
            }
            
            // Load Address is an MCUBoot Manifest "requirement".
            // For SUIT it's not set, but we keep it at zero for backwards compatibility.
            loadAddress = bootloader == .mcuboot ? loadAddressInt : .zero
            
            if let partitionString = try? values.decode(String.self, forKey: ._partition) {
                _partition = Int(partitionString)
            } else {
                _partition = nil
            }
            _image = try? values.decode(Int.self, forKey: ._image)
            let imageIndexString = try? values.decode(String.self, forKey: ._imageIndex)
            guard let imageIndexString else {
                _imageIndex = nil
                return
            }
            
            guard let imageIndex = Int(imageIndexString) else {
                throw DecodingError.dataCorruptedError(forKey: ._imageIndex, in: values,
                                                       debugDescription: "`imageIndex` could not be parsed from String to Int.")
            }
            _imageIndex = imageIndex
        }
    }
}

// MARK: - ContentType

public extension McuMgrManifest.File {
    
    enum ContentType: String, RawRepresentable, Codable, CustomStringConvertible {
        case unknown
        case suitCache = "cache"
        case suitEnvelope = "suit-envelope"
        case bin
        case application
        case mcuboot
        
        public var description: String {
            switch self {
            case .unknown:
                return "Unknown"
            case .suitCache:
                return "SUIT Cache"
            case .suitEnvelope:
                return "SUIT Envelope"
            case .bin:
                return "Binary"
            case .application:
                return "Application"
            case .mcuboot:
                return "MCUboot (Bootloader)"
            }
        }
    }
}

// MARK: - McuMgrManifest.Error

extension McuMgrManifest {
    
    enum Error: Swift.Error, LocalizedError {
        case unableToRead, unableToParseJSON, unableToDecodeJSON
        
        var errorDescription: String? {
            switch self {
            case .unableToRead:
                return "Unable to Read Manifest JSON File."
            case .unableToParseJSON:
                return "Unable to Parse Manifest JSON File."
            case .unableToDecodeJSON:
                return "Unable to Decode Manifest JSON File."
            }
        }
    }
}
