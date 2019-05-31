//
//  NetworkLayer.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 27/05/2019.
//

import Foundation

internal class NetworkLayer {
    let networkManager: NetworkManager
    let networkMessageCache: NSCache<NSData, NSNull>
    
    init(_ networkManager: NetworkManager) {
        self.networkMessageCache = NSCache()
        self.networkManager = networkManager
    }
    
    /// This method handles the received PDU of given type.
    ///
    /// - parameter pdu:  The data received.
    /// - parameter type: The PDU type.
    func handle(incomingPdu pdu: Data, ofType type: PduType) {
        guard let meshNetwork = networkManager.meshNetwork else {
            return
        }
        
        if case .provisioningPdu = type {} else {
            // Provisioning is handled using ProvisioningManager.
            return
        }
        
        // Ensure the PDU has not been handled already.
        guard networkMessageCache.object(forKey: pdu as NSData) == nil else {
            // PDU has already been handled.
            return
        }
        networkMessageCache.setObject(NSNull(), forKey: pdu as NSData)
        
        // Try decoding the PDU.
        switch type {
        case .networkPdu:
            guard let networkPdu = NetworkPdu.decode(pdu, for: meshNetwork) else {
                return
            }
            networkManager.lowerTransportLayer.handle(networkPdu: networkPdu)
        case .meshBeacon:
            if let beaconPdu = SecureNetworkBeacon.decode(pdu, for: meshNetwork) {
                networkManager.lowerTransportLayer.handle(secureNetworkBeacon: beaconPdu)
                return
            }
            if let beaconPdu = UnprovisionedDeviceBeacon.decode(pdu, for: meshNetwork) {
                networkManager.lowerTransportLayer.handle(unprovisionedDeviceBeacon: beaconPdu)
                return
            }
            // Invalid or unsupported beacon type.
        default:
            // Proxy configuration not supported yet.
            return
        }
        
    }
    
}
