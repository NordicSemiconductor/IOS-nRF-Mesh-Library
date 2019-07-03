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
    /// - parameter pdu:  The Lower Transport PDU to be sent.
    /// - parameter type: The PDU type.
    /// - parameter ttl:  The initial TTL (Time To Live) value of the message.
    /// - parameter multipleTimes: Should the message be resent with the same sequence
    ///                            number after a random delay, default `false`.
    func send(lowerTransportPdu pdu: LowerTransportPdu, ofType type: PduType,
              withTtl ttl: UInt8, multipleTimes: Bool = false) throws {
        // Get the current sequence number for local Provisioner's source address.
        let sequence = UInt32(defaults.integer(forKey: pdu.source.hex))
        // As the sequnce number was just used, it has to be incremented.
        defaults.set(sequence + 1, forKey: pdu.source.hex)
        
        let networkPdu = NetworkPdu(encode: pdu, withSequence: sequence, andTtl: ttl)
        try networkManager.transmitter?.send(networkPdu.pdu, ofType: type)
        
        if multipleTimes {
            _ = Timer.scheduledTimer(withTimeInterval: TimeInterval.random(in: 0.050...0.300), repeats: false) { timer in
                try? self.networkManager.transmitter?.send(networkPdu.pdu, ofType: type)
                timer.invalidate()
            }
        }
    }
}
