//
//  McuMgrBleTransportConfguration.swift
//  McuManager
//

import CoreBluetooth

// MARK: - McuMgrBleTransport.Configuration

public extension McuMgrBleTransport {
    
    /**
     Allows for customization of Service and Characteristic `CBUUID`s to target.
     */
    protocol Configuration {
        /// The SMP service UUID.
        var serviceUUID: CBUUID { get }
        
        /// The SMP characteristic UUID.
        var characteristicUUUID: CBUUID { get }
    }
}

// MARK: - DefaultTransportConfiguration

/**
 Default UUID configuration for `McuMgrBleTransport`.
 */
public struct DefaultTransportConfiguration: McuMgrBleTransport.Configuration {
    public init() {}
    
    public let serviceUUID: CBUUID = CBUUID(string: "8D53DC1D-1DB7-4CD3-868B-8A527460AA84")
    public let characteristicUUUID: CBUUID = CBUUID(string: "DA2E7828-FBCE-4E01-AE9E-261174997C48")
}

