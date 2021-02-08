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

/// The wrapper for Unified Unique Identifier (UUID).
/// The reason for the wrapper is to ensure that it is encoded without dashes.
internal class MeshUUID: Codable {
    /// The underlying UUID.
    let uuid: UUID
    
    /// Returns UUID as String, with dashes.
    var uuidString: String {
        return uuid.uuidString
    }
    
    /// Generates new random Mesh UUID.
    init() {
        self.uuid = UUID()
    }
    
    /// Initializes Mesh UUID with given UUID.
    init(_ uuid: UUID) {
        self.uuid = uuid
    }
    
    // MARK: - Codable
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        if let result = UUID(uuidString: value) {
            uuid = result
            return
        }
        
        if let result = UUID(hex: value) {
            uuid = result
            return
        }
        
        throw DecodingError.dataCorruptedError(in: container,
                                               debugDescription: "Invalid UUID: \(value).")
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(uuid.hex)
    }
}

// MARK: - Operators

extension MeshUUID: Equatable {
    
    public static func == (lhs: MeshUUID, rhs: MeshUUID) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    public static func == (lhs: MeshUUID, rhs: UUID) -> Bool {
        return lhs.uuid == rhs
    }
    
    public static func != (lhs: MeshUUID, rhs: MeshUUID) -> Bool {
        return lhs.uuid != rhs.uuid
    }
    
    public static func != (lhs: MeshUUID, rhs: UUID) -> Bool {
        return lhs.uuid != rhs
    }
    
}
