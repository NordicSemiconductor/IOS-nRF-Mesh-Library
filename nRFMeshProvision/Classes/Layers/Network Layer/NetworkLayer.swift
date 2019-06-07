//
//  NetworkLayer.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 27/05/2019.
//

import Foundation

internal class NetworkLayer {
    let networkManager: NetworkManager
    let meshNetwork: MeshNetwork
    let networkMessageCache: NSCache<NSData, NSNull>
    let defaults: UserDefaults
    
    init(_ networkManager: NetworkManager) {
        self.networkManager = networkManager
        self.meshNetwork = networkManager.meshNetwork!
        self.defaults = UserDefaults(suiteName: meshNetwork.uuid.uuidString)!
        self.networkMessageCache = NSCache()
    }
    
    /// This method handles the received PDU of given type and
    /// passes it to Upper Transport Layer.
    ///
    /// - parameter pdu:  The data received.
    /// - parameter type: The PDU type.
    func handle(incomingPdu pdu: Data, ofType type: PduType) {
        guard let meshNetwork = networkManager.meshNetwork else {
            return
        }
        
        if case .provisioningPdu = type {
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
    
    /// This method tries to send the Lower Transport Message of given type to the
    /// given destination address. If the local Provisioner does not exist, or
    /// does not have Unicast Address assigned, this method does nothing.
    ///
    /// If the `transporter` throws an error during sending, this error will be ignored.
    ///
    /// - parameter pdu:         The Lower Transport PDU to be sent.
    /// - parameter type:        The PDU type.
    /// - parameter ttl:         The initial TTL (Time To Leave) value of the message.
    /// - parameter networkKey:  The Network Key to be used to encrypt the message on
    ///                          on Network Layer.
    func handle(outgoingPdu pdu: LowerTransportPdu, ofType type: PduType,
                usingNetworkKey networkKey: NetworkKey, withTtl ttl: UInt8) {
        guard let source = meshNetwork.localProvisioner?.unicastAddress else {
            return
        }
        
        // Get the next sequence number for current Provisioner's source address.
        let sequence = UInt32(defaults.integer(forKey: source.hex))
        defaults.set(sequence + 1, forKey: source.hex)
        
        let networkPdu = NetworkPdu(encode: pdu, sentFrom: source,
                                    usingNetworkKey: networkKey, withSequence: sequence,
                                    andTtl: ttl)
        try? networkManager.transmitter?.send(networkPdu.pdu, ofType: type)
    }
}
