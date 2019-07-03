//
//  MeshAddress.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 27/03/2019.
//

import Foundation

public struct MeshAddress {
    /// 16-bit address.
    public let address: Address
    /// Virtual label UUID.
    public let virtualLabel: UUID?
    
    internal init?(hex: String) {
        if let address = Address(hex: hex) {
            self.init(address)
        } else if let virtualLabel = UUID(hex: hex) {
            self.init(virtualLabel)
        } else {
            return nil
        }
    }
    
    /// Creates a Mesh Address. For virtual addresses use
    /// `init(_ virtualAddress:UUID)` instead.
    public init?(_ address: Address) {
        guard address.isUnicast || address.isGroup else {
            return nil
        }
        self.address = address
        self.virtualLabel = nil
    }
    
    /// Creates a Mesh Address based on the virtual label.
    public init(_ virtualLabel: UUID) {
        self.virtualLabel = virtualLabel
        
        // Calculate the 16-bit virtual address based on the 128-bit label.
        let helper = OpenSSLHelper()
        let salt = helper.calculateSalt("vtad".data(using: .ascii)!)!
        let hash = helper.calculateCMAC(Data(hex: virtualLabel.hex), andKey: salt)!
        var address = UInt16(data: hash.dropFirst(14)).bigEndian
        address |= 0x8000
        address &= 0xBFFF
        self.address = address
    }
}

public extension MeshAddress {
    
    /// Returns `true` if the destination is a Virtual Address
    /// identified by a virtual label, `false` otherwise.
    var isVirtual: Bool {
        return virtualLabel != nil
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
