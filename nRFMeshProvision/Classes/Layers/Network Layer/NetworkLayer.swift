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
            guard let networkPdu = NetworkPdu.decode(pdu, ofType: type, for: meshNetwork) else {
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
            // else: Invalid or unsupported beacon type.
            
        case .proxyConfiguration:
            guard let proxyPdu = NetworkPdu.decode(pdu, ofType: type, for: meshNetwork) else {
                return
            }
            networkManager.lowerTransportLayer.handle(proxyConfigurationPdu: proxyPdu)
            
        default:
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
    /// - throws: This method may throw when the `transmitter` is not set, or has
    ///           failed to send the PDU.
    func send(lowerTransportPdu pdu: LowerTransportPdu, ofType type: PduType,
              withTtl ttl: UInt8) throws {
        guard let transmitter = networkManager.transmitter else {
            throw BearerError.bearerClosed
        }
        // Get the current sequence number for local Provisioner's source address.
        let sequence = UInt32(defaults.integer(forKey: pdu.source.hex))
        // As the sequnce number was just used, it has to be incremented.
        defaults.set(sequence + 1, forKey: pdu.source.hex)
        
        let networkPdu = NetworkPdu(encode: pdu, ofType: type, withSequence: sequence, andTtl: ttl)
        try transmitter.send(networkPdu.pdu, ofType: type)
        
        // Unless a GATT Bearer is used, the Network PDUs should be sent multiple times
        // if Network Transmit has been set for the local Provisioner's Node.
        if case .networkPdu = type, !(transmitter is GattBearer),
            let networkTransmit = meshNetwork.localProvisioner?.node?.networkTransmit,
            networkTransmit.count > 1 {
            var count = networkTransmit.count
            _ = Timer.scheduledTimer(withTimeInterval: TimeInterval(networkTransmit.interval), repeats: true) { timer in
                try? self.networkManager.transmitter?.send(networkPdu.pdu, ofType: type)
                count -= 1
                if count == 0 {
                    timer.invalidate()
                }
            }
        }
    }
}
