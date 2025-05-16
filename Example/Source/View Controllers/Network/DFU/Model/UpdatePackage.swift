/*
* Copyright (c) 2025, Nordic Semiconductor
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

import NordicMesh
import iOSMcuManagerLibrary

// Useful links:
// https://docs.nordicsemi.com/bundle/ncs-latest/page/nrf/protocols/bt/bt_mesh/dfu_over_bt_mesh.html
// Source code for DFU Metadata:
// https://github.com/nrfconnect/sdk-zephyr/blob/main/include/zephyr/bluetooth/mesh/dfu_metadata.h
// TODO: When multi-image DFU will be supported, the format will change.
public struct Metadata: Codable {
    
    public struct Version: Codable, CustomStringConvertible {
        let major: UInt8
        let minor: UInt8
        let revision: UInt16
        let build: UInt32
        
        public enum CodingKeys: String, CodingKey {
            case major
            case minor
            case revision
            case build = "build_number"
        }
        
        public var description: String {
            if build > 0 {
                return "\(major).\(minor).\(revision)+\(build)"
            } else {
                return "\(major).\(minor).\(revision)"
            }
        }
    }
    
    public let signVersion: Version
    public let binarySize: Int // 24 bit
    public let coreType: UInt8
    public let compositionDataHash: Int
    public let metadataString: String?
    public let firmwareIdString: String
    
    public var metadata: Data? {
        return metadataString.map { Data(hex: $0) }
    }
    public var firmwareId: FirmwareId? {
        let data = Data(hex: firmwareIdString)
        return FirmwareId(data: data)
    }
    
    public enum CodingKeys: String, CodingKey {
        case signVersion = "sign_version"
        case binarySize = "binary_size"
        case coreType = "core_type"
        case compositionDataHash = "composition_hash"
        case metadataString = "encoded_metadata"
        case firmwareIdString = "firmware_id"
    }
    
    public static func decode(from url: URL) throws -> Metadata {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let metadata = try decoder.decode(Metadata.self, from: data)
        return metadata
    }
}

public struct UpdatePackage {
    /// File name.
    public let name: String
    /// Mesh DFU Metadata of the selected firmware.
    public let metadata: Metadata
    /// MCU Manager Manifest of the selected firmware.
    public let manifest: McuMgrManifest
    /// Firmware images.
    public let images: [ImageManager.Image]
}
