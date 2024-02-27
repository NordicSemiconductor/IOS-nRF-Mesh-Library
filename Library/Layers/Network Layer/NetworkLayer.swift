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
    private weak var networkManager: NetworkManager?
    private let meshNetwork: MeshNetwork
    private let networkMessageCache: NSCache<NSData, NSNull>
    private let defaults: UserDefaults
    
    private let mutex = DispatchQueue(label: "NetworkLayerMutex")
    
    private var logger: LoggerDelegate? {
        return networkManager?.logger
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
        self.meshNetwork = networkManager.meshNetwork
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
        guard let networkManager = networkManager else { return }
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
            if let networkPdu = NetworkPduDecoder.decode(pdu, ofType: type, for: meshNetwork) {
                logger?.i(.network, "\(networkPdu) received")
                networkManager.lowerTransportLayer.handle(networkPdu: networkPdu)
                return
            }
            logger?.w(.network, "Failed to decrypt PDU")
            
        case .meshBeacon:
            if let beaconPdu = NetworkBeaconDecoder.decode(pdu, for: meshNetwork) {
                logger?.i(.network, "\(beaconPdu) received (authenticated using key: \(beaconPdu.networkKey))")
                handle(networkBeacon: beaconPdu)
                return
            }
            if let beaconPdu = UnprovisionedDeviceBeaconDecoder.decode(pdu) {
                logger?.i(.network, "\(beaconPdu) received")
                handle(unprovisionedDeviceBeacon: beaconPdu)
                return
            }
            logger?.w(.network, "Failed to decrypt mesh beacon PDU")
            
        case .proxyConfiguration:
            if let proxyPdu = NetworkPduDecoder.decode(pdu, ofType: type, for: meshNetwork) {
                logger?.i(.network, "\(proxyPdu) received")
                handle(proxyConfigurationPdu: proxyPdu)
                return
            }
            logger?.w(.network, "Failed to decrypt proxy PDU")
            
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
    /// - throws: This method may throw when the ``MeshNetworkManager/transmitter``
    ///           is not set, or has failed to send the PDU.
    func send(lowerTransportPdu pdu: LowerTransportPdu, ofType type: PduType,
              withTtl ttl: UInt8) throws {
        guard let networkManager = networkManager,
              let transmitter = networkManager.transmitter else {
            throw BearerError.bearerClosed
        }
        
        let sequence: UInt32 = (pdu as? AccessMessage)?.sequence ?? nextSequenceNumber(for: pdu.source)
        let networkPdu = NetworkPdu(encode: pdu, ofType: type, withSequence: sequence, andTtl: ttl)
        logger?.i(.network, "Sending \(networkPdu) encrypted using \(networkPdu.networkKey)")
        // Loopback interface.
        if shouldLoopback(networkPdu) {
            handle(incomingPdu: networkPdu.pdu, ofType: type)
            // Messages sent with TTL = 1 will only be sent locally.
            guard ttl != 1 else { return }
            if isLocalUnicastAddress(networkPdu.destination) {
                // No need to send messages targeting local Unicast Addresses.
                return
            }
            // If the message was sent locally, don't report Bearer closer error.
            try? transmitter.send(networkPdu.pdu, ofType: type)
        } else {
            // Messages sent with TTL = 1 may only be sent locally.
            guard ttl != 1 else { return }
            do {
                try transmitter.send(networkPdu.pdu, ofType: type)
            } catch {
                if case BearerError.bearerClosed = error {
                    proxyNetworkKey = nil
                }
                throw error
            }
        }
        
        // Unless a GATT Bearer is used, the Network PDUs should be sent multiple times
        // if Network Transmit has been set for the local Provisioner's Node.
        if case .networkPdu = type, !(transmitter is GattBearer),
            let networkTransmit = meshNetwork.localProvisioner?.node?.networkTransmit,
            networkTransmit.count > 1 {
            var count = networkTransmit.count
            BackgroundTimer.scheduledTimer(withTimeInterval: networkTransmit.timeInterval,
                                           repeats: true) { [weak self] timer in
                guard let self = self,
                      let networkManager = self.networkManager else {
                    timer.invalidate()
                    return
                }
                try? networkManager.transmitter?.send(networkPdu.pdu, ofType: type)
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
    /// - parameter message: The Proxy Configuration message to be sent.
    func send(proxyConfigurationMessage message: ProxyConfigurationMessage) {
        guard let networkManager = networkManager else { return }
        guard let networkKey = proxyNetworkKey else {
            // The Proxy Network Key is unknown.
            networkManager.proxy?
                .managerFailedToDeliverMessage(message, error: BearerError.bearerClosed)
            return
        }
        
        // If the Provisioner does not have a Unicast Address, just use a fake one
        // to configure the Proxy Server. This allows sniffing the network without
        // an option to send messages.
        let source = meshNetwork.localProvisioner?.node?.primaryUnicastAddress ?? Address.maxUnicastAddress
        logger?.i(.proxy, "Sending \(message) from: \(source.hex) to: 0000")
        let pdu = ControlMessage(fromProxyConfigurationMessage: message,
                                 sentFrom: source, usingNetworkKey: networkKey,
                                 andIvIndex: meshNetwork.ivIndex)
        logger?.i(.network, "Sending \(pdu)")
        do {
            try send(lowerTransportPdu: pdu, ofType: .proxyConfiguration, withTtl: pdu.ttl)
            networkManager.proxy?.managerDidDeliverMessage(message)
        } catch {
            if case BearerError.bearerClosed = error {
                proxyNetworkKey = nil
            }
            networkManager.proxy?.managerFailedToDeliverMessage(message, error: error)
        }
    }
    
    /// This method returns the next outgoing Sequence number for the given
    /// local source Address.
    ///
    /// - parameter source: The source Element's Unicast Address.
    /// - returns: The Sequence number a message can be sent with.
    func nextSequenceNumber(for source: Address) -> UInt32 {
        return mutex.sync {
            defaults.nextSequenceNumber(for: source)
        }
    }
}

private extension NetworkLayer {
    
    /// This method handles the Unprovisioned Device beacon.
    ///
    /// The current implementation does nothing, as remote provisioning is
    /// currently not supported.
    ///
    /// - parameter unprovisionedDeviceBeacon: The Unprovisioned Device beacon received.
    func handle(unprovisionedDeviceBeacon: UnprovisionedDeviceBeacon) {
        // TODO: Handle Unprovisioned Device beacon.
    }
    
    /// This method handles PDUs containing network state.
    ///
    /// As of Mesh Protocol 1.1 these are the Secure Network beacons and Private beacons.
    ///
    /// It will set the IV Index and IV Update Active flag and change the Key Refresh Phase based on the
    /// information specified in the beacon.
    ///
    /// - parameter networkBeacon: The Secure Network or Private beacon received.
    func handle(networkBeacon: NetworkBeaconPdu) {
        guard let networkManager = networkManager else { return }
        /// The Network Key the beacon was authenticated with.
        let networkKey = networkBeacon.networkKey
        // As of now, the library does not retransmit beacons.
        // If this node is a member of the primary subnet and the received beacon for a secondary subnet,
        // it shall disregard it.
        if let _ = meshNetwork.networkKeys.primaryKey, networkKey.isSecondary {
            logger?.w(.network, "Discarding beacon for secondary network (key index: \(networkKey.index))")
            
            // If we've connected to a Proxy Node that doesn't know the Primary Network
            // we should still notify the user about a new Proxy.
            if proxyNetworkKey == nil {
                updateProxyFilter(usingNetworkKey: networkKey)
            }
            return
        }
        
        // Get the last IV Index.
        //
        // Note: Before version 2.2.2 the last IV Index was not stored.
        //       Instead IV Index was set to 0.
        let map = defaults.object(forKey: IvIndex.indexKey) as? [String : Any]
        /// The last used IV Index for this mesh network.
        let lastIVIndex = IvIndex.fromMap(map) ?? IvIndex()
        /// The date of the last change of IV Index or IV Update Flag.
        let lastTransitionDate = defaults.object(forKey: IvIndex.timestampKey) as? Date
        /// A flag whether the IV has recently been updated using IV Recovery procedure.
        /// The at-least-96h requirement for the duration of the current state will not apply.
        /// The node shall not execute more than one IV Index Recovery within a period of 192 hours.
        let isIvRecoveryActive = defaults.bool(forKey: IvIndex.ivRecoveryKey)
        /// The test mode disables the 96h rule, leaving all other behavior unchanged.
        let isIvTestModeActive = networkManager.networkParameters.ivUpdateTestMode
        // Ensure, that the received beacon can overwrite current IV Index.
        let flag = networkManager.networkParameters.allowIvIndexRecoveryOver42
        if networkBeacon.canOverwrite(ivIndex: lastIVIndex,
                                            updatedAt: lastTransitionDate,
                                            withIvRecovery: isIvRecoveryActive,
                                            testMode: isIvTestModeActive,
                                            andUnlimitedIvRecoveryAllowed: flag) {
            // Update the IV Index based on the information from the beacon.
            meshNetwork.ivIndex = networkBeacon.ivIndex
            
            if meshNetwork.ivIndex > lastIVIndex {
                logger?.i(.network, "Applying \(meshNetwork.ivIndex)")
            }
            // If the IV Index used for transmitting messages effectively increased,
            // the Node shall reset the sequence number to 0x000000.
            //
            // Note: This library keeps separate sequence numbers for each Element of the
            //       local provisioner (source Unicast Address). All of them need to be reset.
            if let localNode = meshNetwork.localProvisioner?.node,
               meshNetwork.ivIndex.transmitIndex > lastIVIndex.transmitIndex {
                logger?.i(.network, "Resetting local sequence numbers to 0")
                defaults.resetSequenceNumbers(of: localNode)
            }
            
            // Store the last IV Index.
            defaults.set(meshNetwork.ivIndex.asMap, forKey: IvIndex.indexKey)
            if lastIVIndex != meshNetwork.ivIndex {
                defaults.set(Date(), forKey: IvIndex.timestampKey)
                
                let ivRecovery = meshNetwork.ivIndex.index > lastIVIndex.index + 1 &&
                                 networkBeacon.ivIndex.updateActive == false
                defaults.set(ivRecovery, forKey: IvIndex.ivRecoveryKey)
            }
            
            // If the Key Refresh Procedure is in progress, and the new Network Key
            // has already been set, the key refresh flag indicates switching to Phase 2.
            if case .keyDistribution = networkKey.phase,
               networkBeacon.validForKeyRefreshProcedure &&
               networkBeacon.keyRefreshFlag == true {
                networkKey.phase = .usingNewKeys
            }
            // If the Key Refresh Procedure is in Phase 2, and the key refresh flag is
            // set to false.
            if case .usingNewKeys = networkKey.phase,
               networkBeacon.validForKeyRefreshProcedure &&
               networkBeacon.keyRefreshFlag == false {
                // Revoke the old Network Key...
                networkKey.oldKey = nil // This will set the phase to .normalOperation.
                // ...and old Application Keys bound to it.
                meshNetwork.applicationKeys.boundTo(networkKey)
                    .forEach { $0.oldKey = nil }
            }
        } else if networkBeacon.ivIndex != lastIVIndex.previous {
            var numberOfHoursSinceDate = "unknown time"
            if let date = lastTransitionDate {
                numberOfHoursSinceDate = "\(Int(-date.timeIntervalSinceNow / 3600))h"
            }
            logger?.w(.network, "Discarding beacon (\(networkBeacon.ivIndex), "
                              + "last \(lastIVIndex), changed: \(numberOfHoursSinceDate) ago, "
                              + "test mode: \(networkManager.networkParameters.ivUpdateTestMode))")
            return
        } // else,
        // the beacon was sent by a Node with a previous IV Index,
        // that has not yet transitioned to the one local Node has. Such IV Index
        // is still valid, at least for some time.
        
        updateProxyFilter(usingNetworkKey: networkKey)
    }
    
    /// Updates the information about the Network Key known to the current Proxy Server.
    ///
    /// The Network Key is required to send Proxy Configuration Messages that can be
    /// decoded by the connected Proxy.
    ///
    /// For new Proxy connections this method also initiates the Proxy Filter with
    /// preset ``ProxyFilter/initialState``.
    ///
    /// - parameter networkKey: The Network Key known to the connected Proxy.
    func updateProxyFilter(usingNetworkKey networkKey: NetworkKey) {
        let justConnected = proxyNetworkKey == nil
        
        // Keep the primary Network Key or the most recently received one from the connected
        // Proxy Server. This is to make sure (almost) that the Proxy Configuration messages
        // are sent encrypted with a key known to this Node.
        proxyNetworkKey = networkKey
        
        if justConnected {
            networkManager?.proxy?.newProxyDidConnect()
        }
    }
    
    /// Handles the received Proxy Configuration PDU.
    ///
    /// This method parses the payload and instantiates a message class.
    /// The message is passed to the ``ProxyFilter`` for processing.
    ///
    /// - parameter proxyPdu: The received Proxy Configuration PDU.
    func handle(proxyConfigurationPdu proxyPdu: NetworkPdu) {
        guard let networkManager = networkManager else { return }
        let payload = proxyPdu.transportPdu
        guard payload.count > 1 else {
            return
        }
        
        guard let controlMessage = ControlMessage(fromNetworkPdu: proxyPdu) else {
            logger?.w(.network, "Failed to decrypt proxy PDU")
            return
        }
        logger?.i(.network, "\(controlMessage) received (decrypted using key: \(controlMessage.networkKey))")
        
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
            // Look for the proxy Node.
            let proxyNode = meshNetwork.node(withAddress: proxyPdu.source)
            networkManager.proxy?.handle(message, sentFrom: proxyNode)
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
        return meshNetwork.localProvisioner?.node?.contains(elementWithAddress: address) ?? false
    }
    
    /// Returns whether the PDU should loop back for local processing.
    ///
    /// - parameter networkPdu: The PDU to check.
    func shouldLoopback(_ networkPdu: NetworkPdu) -> Bool {
        let address = networkPdu.destination
        return address.isGroup || address.isVirtual || isLocalUnicastAddress(address)
    }
    
}
