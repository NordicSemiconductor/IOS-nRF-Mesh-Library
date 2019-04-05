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
            self.address = address
            self.virtualLabel = nil
        } else if let virtualLabel = UUID(hex: hex) {
            self.virtualLabel = virtualLabel
            
            // Calculate the 16-bit virtual address based on the 128-bit label.
            let helper = OpenSSLHelper()
            guard let data = helper.calculateSalt(Data(hex: hex)) else {
                return nil
            }
            self.address = UInt16(data: data)
        } else {
            return nil
        }
    }
}

public extension MeshAddress {
    
    /// Returns true if the Subscriber is an Virtual Address
    /// identified by a virtual label.
    var isVirtual: Bool {
        return virtualLabel != nil
    }
}
