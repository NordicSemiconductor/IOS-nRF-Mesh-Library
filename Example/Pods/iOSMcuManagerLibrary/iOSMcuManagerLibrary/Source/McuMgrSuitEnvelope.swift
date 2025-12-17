//
//  McuMgrSuitEnvelope.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 11/12/23.
//

import Foundation
import SwiftCBOR

// MARK: - McuMgrSuitEnvelope

public struct McuMgrSuitEnvelope {
    
    public let digest: McuMgrSuitDigest
    public let data: Data
    
    /**
     In-Development, therefore, not marked as Public yet.
     */
    let manifest: McuMgrSuitManifest?
    
    // MARK: Init
    
    public init(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let validSize = data.count >= MemoryLayout<UInt8>.size * 2
        guard validSize, data[0] == 0xD8, data[1] == 0x6B,
              let cbor = try CBOR.decode(data.map({ $0 })) else {
            throw McuMgrSuitParseError.invalidDataSize
        }
        
        switch cbor {
        case .tagged(_, let cbor):
            self.digest = try McuMgrSuitDigest(cbor: cbor[0x2])
            self.manifest = try? McuMgrSuitManifest(cbor: cbor[0x3])
        default:
            throw McuMgrSuitParseError.digestMapNotFound
        }
        self.data = data
    }
    
    // MARK: API
    
    public func image() -> ImageManager.Image? {
        // Currently only supported Hash Digest Algorithm is SHA256.
        guard let hash = digest.hash(for: .sha256) else { return nil }
        return ImageManager.Image(image: 0, content: .suitEnvelope, hash: hash, data: data)
    }
    
    public func sizeString() -> String {
        return "\(data.count) bytes"
    }
}

// MARK: - McuMgrSuitDigest

public class McuMgrSuitDigest: CBORMappable {
    
    // MARK: Properties
    
    private var modes: [Mode] = []
    
    // MARK: Init
    
    public required init(cbor: CBOR?) throws {
        try super.init(cbor: cbor)
        switch cbor {
        case .byteString(let byteString):
            let innerCbor = try CBOR.decode(byteString)
            switch innerCbor {
            case .array(let digests):
                for digestCbor in digests {
                    guard case .byteString(let array) = digestCbor else {
                        throw McuMgrSuitParseError.digestArrayNotFound
                    }
                    let arrayCbor = try CBOR.decode(array)
                    switch arrayCbor {
                    case .array(let digest):
                        // -1 is a Fix for CBOR library when parsing negativeInt(s)
                        guard let type = digest[0].value as? Int,
                              let algorithm = Algorithm(rawValue: type - 1) else {
                            throw McuMgrSuitParseError.digestTypeNotFound
                        }
                        guard let value = digest[1].value as? [UInt8] else {
                            throw McuMgrSuitParseError.digestValueNotFound
                        }
                        self.modes.append(Mode(algorithm: algorithm, hash: Data(value)))
                    default:
                        throw McuMgrImageParseError.insufficientData
                    }
                }
            default:
                throw McuMgrSuitParseError.digestArrayNotFound
            }
        default:
            throw McuMgrSuitParseError.unableToParseDigest
        }
    }
    
    // MARK: API
    
    public func hash(for algorithm: Algorithm) -> Data? {
        return modes.first(where: { $0.algorithm == algorithm })?.hash
    }
    
    public func hashString() -> String {
        var result = ""
        for digest in modes {
            let hashString = Data(digest.hash).hexEncodedString(options: .upperCase)
            result += "0x\(hashString)"
            guard digest.hash != modes.last?.hash else { continue }
            result += "\n"
        }
        return result
    }
}

// MARK: - McuMgrSuitDigest.Algorithm

extension McuMgrSuitDigest {
    
    public enum Algorithm: Int, RawRepresentable, CustomStringConvertible {
        /**
         This is the (currently) only supported mode.
         */
        case sha256 = -16
        /**
         Considered OPTIONAL for SUIT Implementation and currently **NOT SUPPORTED**.
         */
        case shake128 = -18
        /**
         Considered OPTIONAL for SUIT Implementation and currently **NOT SUPPORTED**.
         */
        case sha384 = -43
        /**
         Considered OPTIONAL for SUIT Implementation and currently **NOT SUPPORTED**.
         */
        case sha512 = -44
        /**
         Considered OPTIONAL for SUIT Implementation and currently **NOT SUPPORTED**.
         */
        case shake256 = -45
        
        public var description: String {
            switch self {
            case .sha256:
                return "SHA256"
            case .shake128:
                return "SHAKE128"
            case .sha384:
                return "SHA384"
            case .sha512:
                return "SHA512"
            case .shake256:
                return "SHAKE256"
            }
        }
    }
}

// MARK: - McuMgrSuitDigest.Mode

extension McuMgrSuitDigest {
    
    struct Mode {
        let algorithm: Algorithm
        let hash: Data
    }
}

// MARK: - McuMgrSuitParseError

public enum McuMgrSuitParseError: LocalizedError {
    case invalidDataSize
    case digestMapNotFound
    case digestArrayNotFound
    case digestTypeNotFound
    case digestValueNotFound
    case unableToParseDigest
    case supportedAlgorithmNotFound
    
    public var errorDescription: String? {
        switch self {
        case .invalidDataSize:
            return "The Data is not large enough to hold a SUIT Envelope / Digest"
        case .digestMapNotFound:
            return "The CBOR Map containing Digests could not be found or parsed."
        case .digestArrayNotFound:
            return "The CBOR Array containing the Digest could not be found."
        case .digestTypeNotFound:
            return "The Type of Digest value could not be found or parsed."
        case .digestValueNotFound:
            return "The Digest value could not be found or parsed."
        case .unableToParseDigest:
            return "The Digest CBOR Data was found, but could not be parsed or some essential elements were missing."
        case .supportedAlgorithmNotFound:
            return "Currently the only supported Algorithm / Mode is SHA256. All other modes are considered OPTIONAL for a valid SUIT implementation as of this time."
        }
    }
}
