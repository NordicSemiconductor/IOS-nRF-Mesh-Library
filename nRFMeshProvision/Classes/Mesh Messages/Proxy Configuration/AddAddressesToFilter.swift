//
//  AddAddressesToFilter.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 03/09/2019.
//

import Foundation

public struct AddAddressesToFilter: StaticProxyConfigurationMessage {
    public static var opCode: UInt8 = 0x01
    
    public var parameters: Data? {
        var data = Data()
        addresses.forEach { address in
            data += address.bigEndian
        }
        return data
    }
    
    /// Arrays of addresses to be added to the proxy filter.
    public let addresses: Set<Address>
    
    /// Creates the Add Addresses To Filter message.
    ///
    /// - parameter addresses: The array of addresses to be added
    ///                        to the current filter.
    public init(_ addresses: Set<Address>) {
        self.addresses = addresses
    }
    
    public init?(parameters: Data) {
        guard parameters.count % 2 == 0 else {
            return nil
        }
        var tmp: Set<Address> = []
        for i in stride(from: 0, to: parameters.count, by: 2) {
            let address: Address = parameters.readBigEndian(fromOffset: i)
            tmp.insert(address)
        }
        addresses = tmp
    }
}
