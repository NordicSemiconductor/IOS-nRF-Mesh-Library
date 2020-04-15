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

internal class NetworkLayer {
    private let networkManager: NetworkManager
    private let meshNetwork: MeshNetwork
    private let networkMessageCache: NSCache<NSData, NSNull>
    private let defaults: UserDefaults
    
    private var logger: LoggerDelegate? {
        return networkManager.manager.logger
    }
    
    /// The Network Key from the received Secure Network Beacon that contained
    /// information about the Primary Network Key, if such was received,
    /// or from the most recently received beacon otherwise.
    ///
    /// Secure Network Beacons are sent each time a Proxy Client connects
    /// to a Proxy Server, one for each Network Key known to this server Node.
    ///
    /// This property is used for the Proxy Configuration messages, as they must be
    /// encrypted with a Network Key known to the connected Proxy Node. To make the
    /// implementation simpler (as it is not known to which Node the Proxy Client
    /// is connected to), instead of trying all Network Keys, the messages are
    /// encrypted with only the primary or the last received key. The primary, as
    /// it is unlikely that the primary key will be removed from a Node, or last
    /// received, as there is the highest chance of success, as this one was added
    /// most recently.
    ///
    /// - important: Each time a new Network Key is added to the Proxy Node,
    ///              it sends the Secure Network Beacon to the connected Proxy Client.
    ///              However, as there is no beacon sent when a key is removed, the
    ///              stored Network Key may be invalid. Therefore, it may be, that the
    ///              key with this index is no longer stored on the connected Node
    ///              and the Proxy Configuration messages will not work.
    private var proxyNetworkKey: NetworkKey?
    
    init(_ networkManager: NetworkManager) {
        self.networkManager = networkManager
        self.meshNetwork = networkManager.meshNetwork!
        self.defaults = UserDefaults(suiteName: meshNetwork.uuid.uuidString)!
        self.networkMessageCache = NSCache()
    }
    
    /// This method handles the received PDU of given type and
    /// passes it to Upper Transport Layer.
    ///
    /// - parameters:
    ///   - pdu:  The data received.
    ///   - type: The PDU type.
    func handle(incomingPdu pdu: Data, ofType type: PduType) {
        guard let meshNetwork = networkManager.meshNetwork else {
            return
        }
        
        if case .provisioningPdu = type {
            // Provisioning is handled using ProvisioningManager.
            return
        }
        
        // Secure Network Beacons can repeat whenever the device connects to a new Proxy.
        if type != .meshBeacon {
            // Ensure the PDU has not been handled already.
            guard networkMessageCache.object(forKey: pdu as NSData) == nil else {
                // PDU has already been handled.
                logger?.d(.network, "PDU already handled")
                return
            }
            networkMessageCache.setObject(NSNull(), forKey: pdu as NSData)
        }
        
        // Try decoding the PDU.
        switch type {
        case .networkPdu:
            guard let networkPdu = NetworkPdu.decode(pdu, ofType: type, for: meshNetwork) else {
                logger?.w(.network, "Failed to decrypt PDU")
                return
            }
            logger?.i(.network, "\(networkPdu) received")
            networkManager.lowerTransportLayer.handle(networkPdu: networkPdu)
            
        case .meshBeacon:
            if let beaconPdu = SecureNetworkBeacon.decode(pdu, for: meshNetwork) {
                logger?.i(.network, "\(beaconPdu) receieved (decrypted using key: \(beaconPdu.networkKey))")
                handle(secureNetworkBeacon: beaconPdu)
                return
            }
            if let beaconPdu = UnprovisionedDeviceBeacon.decode(pdu, for: meshNetwork) {
                logger?.i(.network, "\(beaconPdu) receieved")
                handle(unprovisionedDeviceBeacon: beaconPdu)
                return
            }
            logger?.w(.network, "Failed to decrypt Mesh Beacon PDU")
            // else: Invalid or unsupported beacon type.
            
        case .proxyConfiguration:
            guard let proxyPdu = NetworkPdu.decode(pdu, ofType: type, for: meshNetwork) else {
                logger?.w(.network, "Failed to decrypt proxy PDU")
                return
            }
            logger?.i(.network, "\(proxyPdu) received")
            handle(proxyConfigurationPdu: proxyPdu)
            
        default:
            return
        }
        
    }
    
    /// This method tries to send the Lower Transport Message of given type to the
    /// given destination address. If the local Provisioner does not exist, or
    /// does not have Unicast Address assigned, this method does nothing.
    ///
    /// - parameters:
    ///   - pdu:  The Lower Transport PDU to be sent.
    ///   - type: The PDU type.
    ///   - ttl:  The initial TTL (Time To Live) value of the message.
    /// - throws: This method may throw when the `transmitter` is not set, or has
    ///           failed to send the PDU.
    func send(lowerTransportPdu pdu: LowerTransportPdu, ofType type: PduType,
              withTtl ttl: UInt8) throws {
        guard let transmitter = networkManager.transmitter else {
            throw BearerError.bearerClosed
        }
        // Get the current sequence number for local Provisioner's source address.
        let sequence = UInt32(defaults.integer(forKey: "S\(pdu.source.hex)"))
        // As the sequnce number was just used, it has to be incremented.
        defaults.set(sequence + 1, forKey: "S\(pdu.source.hex)")
        
        let networkPdu = NetworkPdu(encode: pdu, ofType: type, withSequence: sequence, andTtl: ttl)
        logger?.i(.network, "Sending \(networkPdu) encrypted using \(networkPdu.networkKey)")
        // Loopback interface.
        if shouldLoopback(networkPdu) {
            handle(incomingPdu: networkPdu.pdu, ofType: type)
            
            if isLocalUnicastAddress(networkPdu.destination) {
                // No need to send messages targeting local Unicast Addresses.
                return
            }
            // If the message was sent locally, don't report Bearer closer error.
            try? transmitter.send(networkPdu.pdu, ofType: type)
        } else {
            try transmitter.send(networkPdu.pdu, ofType: type)
        }
        
        // Unless a GATT Bearer is used, the Network PDUs should be sent multiple times
        // if Network Transmit has been set for the local Provisioner's Node.
        if case .networkPdu = type, !(transmitter is GattBearer),
            let networkTransmit = meshNetwork.localProvisioner?.node?.networkTransmit,
            networkTransmit.count > 1 {
            var count = networkTransmit.count
            BackgroundTimer.scheduledTimer(withTimeInterval: networkTransmit.timeInterval, repeats: true) { timer in
                try? self.networkManager.transmitter?.send(networkPdu.pdu, ofType: type)
                count -= 1
                if count == 0 {
                    timer.invalidate()
                }
            }
        }
    }
    
    /// This method tries to send the Proxy Configuration Message.
    ///
    /// The Proxy Filter object will be informed about the success or a failure.
    ///
    /// - parameter message: The Proxy Confifuration message to be sent.
    func send(proxyConfigurationMessage message: ProxyConfigurationMessage) {
        guard let networkKey = proxyNetworkKey else {
            // The Proxy Network Key is unknown.
            networkManager.manager.proxyFilter?
                .managerFailedToDeliverMessage(message, error: BearerError.bearerClosed)
            return
        }
        
        // If the Provisioner does not have a Unicast Address, just use a fake one
        // to configure the Proxy Server. This allows sniffing the network without
        // an option to send messages.
        let source = meshNetwork.localProvisioner?.node?.unicastAddress ?? Address.maxUnicastAddress
        logger?.i(.proxy, "Sending \(message) from: \(source.hex) to: 0000")
        let pdu = ControlMessage(fromProxyConfigurationMessage: message,
                                 sentFrom: source, usingNetworkKey: networkKey,
                                 andIvIndex: meshNetwork.ivIndex)
        logger?.i(.network, "Sending \(pdu)")
        do {
            try send(lowerTransportPdu: pdu, ofType: .proxyConfiguration, withTtl: 0)
            networkManager.manager.proxyFilter?.managerDidDeliverMessage(message)
        } catch {
            networkManager.manager.proxyFilter?.managerFailedToDeliverMessage(message, error: error)
        }
    }
}

private extension NetworkLayer {
    
    /// This method handles the Unprovisioned Device beacon.
    ///
    /// The curernt implementation does nothing, as remote provisioning is
    /// currently not supported.
    ///
    /// - parameter unprovisionedDeviceBeacon: The Unprovisioned Device beacon received.
    func handle(unprovisionedDeviceBeacon: UnprovisionedDeviceBeacon) {
        // TODO: Handle Unprovisioned Device beacon.
    }
    
    /// This method handles the Secure Network beacon.
    /// It will set the proper IV Index and IV Update Active flag for the Network Key
    /// that matches Network ID and change the Key Refresh Phase based on the
    /// key refresh flag specified in the beacon.
    ///
    /// - parameter secureNetworkBeacon: The Secure Network beacon received.
    func handle(secureNetworkBeacon: SecureNetworkBeacon) {
        /// The Network Key the Secure Network Beacon was encrypted with.
        let networkKey = secureNetworkBeacon.networkKey
        // The IV Index in the beacon must be greater or equal to the current one.
        guard secureNetworkBeacon.ivIndex >= meshNetwork.ivIndex.index else {
            logger?.w(.network, "Discarding beacon (ivIndex: \(secureNetworkBeacon.ivIndex), expected >= \(meshNetwork.ivIndex.index))")
            return
        }
        // If this node is a member of a primary subnet and receives a Secure Network
        // beacon on a secondary subnet, it will disregard it. The library does not
        // retransmit Secure Network Beacon.
        if let _ = meshNetwork.networkKeys.first(where: { $0.isPrimary }), networkKey.isSecondary {
            logger?.w(.network, "Discarding beacon for secondary network (key index: \(networkKey.index))")
            return
        }
        // Get the last IV Index.
        // Note: Before version 2.3 the last IV Index was not stored.
        let map = defaults.object(forKey: "IVIndex") as? [String : Any] ?? meshNetwork.ivIndex.asMap
        let lastIVIndex = IvIndex.fromMap(map)
        // Update the IV Index based on the information from the Secure Network Beacon.
        meshNetwork.ivIndex = IvIndex(index: secureNetworkBeacon.ivIndex,
                                      updateActive: secureNetworkBeacon.ivUpdateActive)
        // If IV Index state transitions from IV Update Active to Normal Operation,
        // the Node shall reset the sequence number to 0x000000.
        if let lastIVIndex = lastIVIndex,
           lastIVIndex.updateActive && !secureNetworkBeacon.ivUpdateActive {
            meshNetwork.localProvisioner?.node?.elements.forEach { element in
                defaults.set(0, forKey: "S\(element.unicastAddress.hex)")
            }
        }
        // Store the last IV Index.
        defaults.set(meshNetwork.ivIndex.asMap, forKey: "IVIndex")
        
        // If the Key Refresh Procedure is in progress, and the new Network Key
        // has already been set, the key refresh flag indicates switching to phase 2.
        if case .distributingKeys = networkKey.phase, secureNetworkBeacon.keyRefreshFlag {
            networkKey.phase = .finalizing
        }
        // If the Key Refresh Procedure is in phase 2, and the key refresh flag is
        // set to false.
        if case .finalizing = networkKey.phase, !secureNetworkBeacon.keyRefreshFlag {
            networkKey.oldKey = nil // This will set the phase to .normalOperation.
        }
        
        updateProxyFilter(usingNetworkKey: networkKey)
    }
    
    /// Updates the information about the Network Key known to the current Proxy Server.
    /// The Network Key is required to send Proxy Configuration Messages that can be
    /// decoded by the connected Proxy.
    ///
    /// If the method detects that the Proxy has just been connected, or was reconnected,
    /// it will initiate the Proxy Filter with local Provisioner's Unicast Address and
    /// the `Address.allNodes` group address.
    ///
    /// - parameter networkKey: The Network Key known to the connected Proxy.
    func updateProxyFilter(usingNetworkKey networkKey: NetworkKey) {
        let justConnected = proxyNetworkKey == nil
        let reconnected = networkKey == proxyNetworkKey
        
        // Keep the primary Network Key or the most recently received one from the connected
        // Proxy Server. This is to make sure (almost) that the Proxy Configuration messages
        // are sent encrypted with a key known to this Node.
        if justConnected || networkKey.isPrimary || proxyNetworkKey?.isPrimary == false {
            proxyNetworkKey = networkKey
        }
        
        if justConnected || reconnected {
            networkManager.manager.proxyFilter?.newProxyDidConnect()
        }
    }
    
    /// Handles the received Proxy Configuration PDU.
    ///
    /// This method parses the payload and instantiates a message class.
    /// The message is passed to the `ProxyFilter` for processing.
    ///
    /// - parameter proxyPdu: The received Proxy Configuration PDU.
    func handle(proxyConfigurationPdu proxyPdu: NetworkPdu) {
        let payload = proxyPdu.transportPdu
        guard payload.count > 1 else {
            return
        }
        
        guard let controlMessage = ControlMessage(fromNetworkPdu: proxyPdu) else {
            logger?.w(.network, "Failed to decrypt proxy PDU")
            return
        }
        logger?.i(.network, "\(controlMessage) receieved (decrypted using key: \(controlMessage.networkKey))")
        
        var MessageType: ProxyConfigurationMessage.Type?
        
        switch controlMessage.opCode {
        case FilterStatus.opCode:
            MessageType = FilterStatus.self
        default:
            MessageType = nil
        }
        
        if let MessageType = MessageType,
           let message = MessageType.init(parameters: controlMessage.upperTransportPdu) {
            logger?.i(.proxy, "\(message) received from: \(proxyPdu.source.hex) to: \(proxyPdu.destination.hex)")
            networkManager.manager.proxyFilter?.handle(message)
        } else {
            logger?.w(.proxy, "Unsupported proxy configuration message (opcode: \(controlMessage.opCode))")
        }
    }
    
}

private extension NetworkLayer {
    
    /// Returns whether the given Address is an address of a local Element.
    ///
    /// - parameter address: The Address to check.
    /// - returns: `True` if the address is a Unicast Address and belongs to
    ///            one of the local Node's elements; `false` otherwise.
    func isLocalUnicastAddress(_ address: Address) -> Bool {
        return meshNetwork.localProvisioner?.node?.hasAllocatedAddress(address) ?? false
    }
    
    /// Returns whether the PDU should loop back for local processing.
    ///
    /// - parameter networkPdu: The PDU to check.
    func shouldLoopback(_ networkPdu: NetworkPdu) -> Bool {
        let address = networkPdu.destination
        return address.isGroup || address.isVirtual || isLocalUnicastAddress(address)
    }
    
}
