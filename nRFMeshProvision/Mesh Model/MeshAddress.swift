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

/// The mesh address.
///
/// An address in Mesh may be of type:
/// * Unassigned Address
/// * Unicast Address
/// * Group Address
/// * Virtual Label - a 16-byte UUID
public struct MeshAddress {
    /// 16-bit address.
    public let address: Address
    /// Virtual label UUID.
    public let virtualLabel: UUID?
    
    public init?(hex: String) {
        if let address = Address(hex: hex) {
            self.init(address)
        } else if let virtualLabel = UUID(uuidString: hex) {
            self.init(virtualLabel)
        } else if let virtualLabel = UUID(hex: hex) {
            self.init(virtualLabel)
        } else {
            return nil
        }
    }
    
    /// Creates a Mesh Address. For virtual addresses use the other init instead.
    ///
    /// To get a next available Group Address for the local Provisioner, use
    /// ``MeshNetwork/nextAvailableGroupAddress()``.
    ///
    /// This method will be used for Virtual Address if the Virtual Label is not known,
    /// for example ``ConfigModelPublicationStatus`` message is received.
    ///
    /// - parameter address: The Group Address assigned to the Group.
    ///                      Group addresses are in range 0xC000..0xFEFF.
    public init(_ address: Address) {
        self.address = address
        self.virtualLabel = nil
    }
    
    /// Creates a Mesh Address based on the Virtual Label.
    ///
    /// - parameter virtualLabel: The UUID associated with the Group.
    public init(_ virtualLabel: UUID) {
        self.virtualLabel = virtualLabel
        self.address = Crypto.calculateVirtualAddress(from: virtualLabel)
    }
}

internal extension MeshAddress {
    
    var hex: String {
        if let virtualLabel = virtualLabel {
            return virtualLabel.hex
        }
        return address.hex
    }
    
}

extension MeshAddress: Equatable {
    
    public static func == (lhs: MeshAddress, rhs: MeshAddress) -> Bool {
        return lhs.address == rhs.address
    }
    
    public static func != (lhs: MeshAddress, rhs: MeshAddress) -> Bool {
        return lhs.address != rhs.address
    }
    
}

extension MeshAddress: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(address)
    }
    
}

extension MeshAddress: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        if let virtualLabel = virtualLabel {
            return virtualLabel.uuidString
        }
        return "0x\(address.hex)"
    }
    
}
