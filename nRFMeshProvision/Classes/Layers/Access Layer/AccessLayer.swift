//
//  AccessLayer.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 29/05/2019.
//

import Foundation

/// The transaction object is used for Transaction Messages,
/// for example `GenericLevelSet`.
private struct Transaction {
    /// Last used Transaction Identifier.
    private var lastTid = UInt8.random(in: UInt8.min...UInt8.max)
    /// The timestamp of the last transaction message sent.
    private var timestamp: Date = Date()
    
    /// Returns the last used TID.
    mutating func currentTid() -> UInt8 {
        timestamp = Date()
        return lastTid
    }
    
    /// Returns the next TID.
    mutating func nextTid() -> UInt8 {
        if lastTid < 255 {
            lastTid = lastTid + 1
        } else {
            lastTid = 0
        }
        timestamp = Date()
        return lastTid
    }
    
    /// Whether the transaction can be continued.
    var isActive: Bool {
        // A transaction may last up to 6 seconds.
        return timestamp.timeIntervalSinceNow > -6.0
    }
}

private class AcknowledgmentContext {
    let request: AcknowledgedMeshMessage
    let source: Address
    var timeoutTimer: BackgroundTimer?
    var retryTimer: BackgroundTimer?
    
    init(for request: AcknowledgedMeshMessage, sentFrom source: Address,
         repeatAfter delay: TimeInterval, repeatBlock: @escaping () -> Void,
         timeout: TimeInterval, timeoutBlock: @escaping () -> Void) {
        self.request = request
        self.source = source
        self.timeoutTimer = BackgroundTimer.scheduledTimer(withTimeInterval: timeout, repeats: false) { _ in
            self.invalidate()
            timeoutBlock()
        }
        initializeRetryTimer(withDelay: delay, callback: repeatBlock)
    }
    
    /// Invalidates the timers.
    func invalidate() {
        print("Invalidating context")
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        retryTimer?.invalidate()
        retryTimer = nil
    }
    
    private func initializeRetryTimer(withDelay delay: TimeInterval,
                                      callback: @escaping () -> Void) {
        retryTimer?.invalidate()
        retryTimer = BackgroundTimer.scheduledTimer(withTimeInterval: delay, repeats: false) { timer in
            callback()
            self.initializeRetryTimer(withDelay: timer.interval * 2, callback: callback)
        }
    }
}

internal class AccessLayer {
    private let networkManager: NetworkManager
    private let meshNetwork: MeshNetwork
    
    private var logger: LoggerDelegate? {
        return networkManager.manager.logger
    }
    
    /// A map of current transactions.
    ///
    /// The key is a value combined from the source and destination addresses.
    private var transactions: [UInt32 : Transaction]
    /// This array contains information about the expected acknowledgments
    /// for acknowledged mesh messages that have been sent, and for which
    /// the response has not been received yet.
    private var reliableMessageContexts: [AcknowledgmentContext]
    
    init(_ networkManager: NetworkManager) {
        self.networkManager = networkManager
        self.meshNetwork = networkManager.meshNetwork!
        self.transactions = [:]
        self.reliableMessageContexts = []
    }
    
    deinit {
        transactions.removeAll()
        reliableMessageContexts.forEach { ack in
            ack.invalidate()
        }
        reliableMessageContexts.removeAll()
    }
    
    /// This method handles the Upper Transport PDU and reads the Opcode.
    /// If the Opcode is supported, a message object is created and sent
    /// to the delegate. Otherwise, a generic MeshMessage object is created
    /// for the app to handle.
    ///
    /// - parameter upperTransportPdu: The decoded Upper Transport PDU.
    /// - parameter keySet: The keySet that the message was encrypted with.
    func handle(upperTransportPdu: UpperTransportPdu, sentWith keySet: KeySet) {
        guard let accessPdu = AccessPdu(fromUpperTransportPdu: upperTransportPdu) else {
            return
        }
        
        // If a response to a sent request has been received, cancel the context.
        if upperTransportPdu.destination.isUnicast,
           let index = reliableMessageContexts.firstIndex(where: {
                    $0.source == upperTransportPdu.destination &&
                    $0.request.responseOpCode == accessPdu.opCode
           }) {
            reliableMessageContexts.remove(at: index).invalidate()
            logger?.i(.access, "Response \(accessPdu) receieved (decrypted using key: \(keySet))")
        } else {
            logger?.i(.access, "\(accessPdu) receieved (decrypted using key: \(keySet))")
        }
        handle(accessPdu: accessPdu, sentWith: keySet)
    }
    
    /// Sends the MeshMessage to the destination. The message is encrypted
    /// using given Application Key and a Network Key bound to it.
    ///
    /// Before sending, this method updates the transaction identifier (TID)
    /// for message extending `TransactionMessage`.
    ///
    /// - parameter message:        The Mesh Message to send.
    /// - parameter element:        The source Element.
    /// - parameter destination:    The destination Address. This can be any
    ///                             valid mesh Address.
    /// - parameter applicationKey: The Application Key to sign the message with.
    func send(_ message: MeshMessage,
              from element: Element, to destination: MeshAddress,
              using applicationKey: ApplicationKey) {
        // Should the TID be updated?
        var m = message
        if var tranactionMessage = message as? TransactionMessage, tranactionMessage.tid == nil {
            // Ensure there is a transaction for our destination.
            let k = key(for: element, and: destination)
            transactions[k] = transactions[k] ?? Transaction()
            // Should the last transaction be continued?
            if tranactionMessage.continueTransaction, transactions[k]!.isActive {
                tranactionMessage.tid = transactions[k]!.currentTid()
            } else {
                // If not, start a new transaction by setting a new TID value.
                tranactionMessage.tid = transactions[k]!.nextTid()
            }
            m = tranactionMessage
        }
        
        logger?.i(.model, "Sending \(m) from: \(element), to: \(destination.hex)")
        let pdu = AccessPdu(fromMeshMessage: m, sentFrom: element, to: destination)
        let keySet = AccessKeySet(applicationKey: applicationKey)
        logger?.i(.access, "Sending \(pdu)")
        
        // Set timers for the acknowledged messages.
        if let _ = message as? AcknowledgedMeshMessage {
            createReliableContext(for: pdu, sentFrom: element, using: keySet)
        }
        
        networkManager.upperTransportLayer.send(pdu, using: keySet)
    }
    
    /// Sends the ConfigMessage to the destination. The message is encrypted
    /// using the Device Key which belongs to the target Node, and first
    /// Network Key known to this Node.
    ///
    /// - parameter message:     The Mesh Config Message to send.
    /// - parameter destination: The destination address. This must be a Unicast Address.
    func send(_ message: ConfigMessage, to destination: Address) {
        guard let element = meshNetwork.localProvisioner?.node?.elements.first,
              let node = meshNetwork.node(withAddress: destination),
              var networkKey = node.networkKeys.first else {
            return
        }
        // ConfigNetKeyDelete must not be signed using the key that is being deleted.
        if let netKeyDelete = message as? ConfigNetKeyDelete,
           netKeyDelete.networkKeyIndex == networkKey.index {
            networkKey = node.networkKeys.last!
        }
        
        if networkManager.foundationLayer.handle(configMessage: message, to: destination) {
            logger?.i(.foundationModel, "Sending \(message) to: \(destination.hex)")
            let pdu = AccessPdu(fromMeshMessage: message, sentFrom: element, to: MeshAddress(destination))
            logger?.i(.access, "Sending \(pdu)")
            let keySet = DeviceKeySet(networkKey: networkKey, node: node)
            
            // Set timers for the acknowledged messages.
            if let _ = message as? AcknowledgedConfigMessage {
                createReliableContext(for: pdu, sentFrom: element, using: keySet)
            }
            
            networkManager.upperTransportLayer.send(pdu, using: keySet)
        }
    }
    
    /// Replies to the received message, which was sent with the given key set,
    /// with the given message.
    ///
    /// - parameters:
    ///   - origin:      The destination address of the message that the reply is for.
    ///   - message:     The response message to be sent.
    ///   - element:     The source Element.
    ///   - destination: The destination address. This must be a Unicast Address.
    ///   - keySet:      The set of keys that the message was encrypted with.
    func reply(toMessageSentTo origin: Address, with message: MeshMessage,
               from element: Element, to destination: Address,
               using keySet: KeySet) {
        let category: LogCategory = message is ConfigMessage ? .foundationModel : .model
        logger?.i(category, "Replying with \(message) from: \(element), to: \(destination.hex)")
        let pdu = AccessPdu(fromMeshMessage: message, sentFrom: element, to: MeshAddress(destination))
        
        // If the message is sent in response to a received message that was sent to
        // a Unicast Address, the node should transmit the response message with a random
        // delay between 20 and 50 milliseconds. If the message is sent in response to a
        // received message that was sent to a group address or a virtual address, the node
        // should transmit the response message with a random delay between 20 and 500
        // milliseconds. This reduces the probability of multiple nodes responding to this
        // message at exactly the same time, and therefore increases the probability of
        // message delivery rather than message collisions.
        let delay = origin.isUnicast ?
            TimeInterval.random(in: 0.020...0.050) :
            TimeInterval.random(in: 0.020...0.500)
        
        Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            self.logger?.i(.access, "Sending \(pdu)")
            self.networkManager.upperTransportLayer.send(pdu, using: keySet)
        }
    }
    
}

private extension AccessLayer {
    
    /// This method converts the received Access PDU to a Mesh Message and
    /// sends to `handle(meshMessage:from)` if message was successfully created.
    ///
    /// - parameter accessPdu: The Access PDU received.
    /// - parameter keySet:    The set of keys that the message was encrypted with.
    func handle(accessPdu: AccessPdu, sentWith keySet: KeySet) {
        var MessageType: MeshMessage.Type?
        
        switch accessPdu.opCode {
            
        // Vendor Messages
        case let opCode where (opCode & 0xC00000) == 0xC00000:
            MessageType = networkManager.manager.vendorTypes[opCode] ?? UnknownMessage.self
            
        // Composition Data
        case ConfigCompositionDataGet.opCode:
            MessageType = ConfigCompositionDataGet.self
            
        case ConfigCompositionDataStatus.opCode:
            MessageType = ConfigCompositionDataStatus.self
            
        // Secure Network Beacon configuration
            
        case ConfigBeaconGet.opCode:
            MessageType = ConfigBeaconGet.self
            
        case ConfigBeaconSet.opCode:
            MessageType = ConfigBeaconSet.self
            
        case ConfigBeaconStatus.opCode:
            MessageType = ConfigBeaconStatus.self
            
        // Relay configuration
            
        case ConfigRelayGet.opCode:
            MessageType = ConfigRelayGet.self
            
        case ConfigRelaySet.opCode:
            MessageType = ConfigRelaySet.self
            
        case ConfigRelayStatus.opCode:
            MessageType = ConfigRelayStatus.self
            
            // GATT Proxy configuration
            
        case ConfigGATTProxyGet.opCode:
            MessageType = ConfigGATTProxyGet.self
            
        case ConfigGATTProxySet.opCode:
            MessageType = ConfigGATTProxySet.self
            
        case ConfigGATTProxyStatus.opCode:
            MessageType = ConfigGATTProxyStatus.self
            
        // Friend configuration
            
        case ConfigFriendGet.opCode:
            MessageType = ConfigFriendGet.self
            
        case ConfigFriendSet.opCode:
            MessageType = ConfigFriendSet.self
            
        case ConfigFriendStatus.opCode:
            MessageType = ConfigFriendStatus.self
            
        // Network Transmit configuration
            
        case ConfigNetworkTransmitGet.opCode:
            MessageType = ConfigNetworkTransmitGet.self
            
        case ConfigNetworkTransmitSet.opCode:
            MessageType = ConfigNetworkTransmitSet.self
            
        case ConfigNetworkTransmitStatus.opCode:
            MessageType = ConfigNetworkTransmitStatus.self
            
        // Network Keys Management
        case ConfigNetKeyAdd.opCode:
            MessageType = ConfigNetKeyAdd.self
            
        case ConfigNetKeyDelete.opCode:
            MessageType = ConfigNetKeyDelete.self
            
        case ConfigNetKeyUpdate.opCode:
            MessageType = ConfigNetKeyUpdate.self
            
        case ConfigNetKeyStatus.opCode:
            MessageType = ConfigNetKeyStatus.self
            
        case ConfigNetKeyGet.opCode:
            MessageType = ConfigNetKeyGet.self
            
        case ConfigNetKeyList.opCode:
            MessageType = ConfigNetKeyList.self
            
        // App Keys Management
        case ConfigAppKeyAdd.opCode:
            MessageType = ConfigAppKeyAdd.self
            
        case ConfigAppKeyDelete.opCode:
            MessageType = ConfigAppKeyDelete.self
            
        case ConfigAppKeyUpdate.opCode:
            MessageType = ConfigAppKeyUpdate.self
            
        case ConfigAppKeyStatus.opCode:
            MessageType = ConfigAppKeyStatus.self
            
        case ConfigAppKeyGet.opCode:
            MessageType = ConfigAppKeyGet.self
            
        case ConfigAppKeyList.opCode:
            MessageType = ConfigAppKeyList.self
            
        // Model Bindings
        case ConfigModelAppBind.opCode:
            MessageType = ConfigModelAppBind.self
            
        case ConfigModelAppUnbind.opCode:
            MessageType = ConfigModelAppUnbind.self
            
        case ConfigModelAppStatus.opCode:
            MessageType = ConfigModelAppStatus.self
            
        case ConfigSIGModelAppGet.opCode:
            MessageType = ConfigSIGModelAppGet.self
            
        case ConfigSIGModelAppList.opCode:
            MessageType = ConfigSIGModelAppList.self
            
        case ConfigVendorModelAppGet.opCode:
            MessageType = ConfigVendorModelAppGet.self
            
        case ConfigVendorModelAppList.opCode:
            MessageType = ConfigVendorModelAppList.self
            
        // Publications
        case ConfigModelPublicationGet.opCode:
            MessageType = ConfigModelPublicationGet.self
            
        case ConfigModelPublicationSet.opCode:
            MessageType = ConfigModelPublicationSet.self
            
        case ConfigModelPublicationVirtualAddressSet.opCode:
            MessageType = ConfigModelPublicationVirtualAddressSet.self
            
        case ConfigModelPublicationStatus.opCode:
            MessageType = ConfigModelPublicationStatus.self
            
        // Subscriptions
        case ConfigModelSubscriptionAdd.opCode:
            MessageType = ConfigModelSubscriptionAdd.self
            
        case ConfigModelSubscriptionDelete.opCode:
            MessageType = ConfigModelSubscriptionDelete.self
            
        case ConfigModelSubscriptionDeleteAll.opCode:
            MessageType = ConfigModelSubscriptionDeleteAll.self
            
        case ConfigModelSubscriptionOverwrite.opCode:
            MessageType = ConfigModelSubscriptionOverwrite.self
            
        case ConfigModelSubscriptionStatus.opCode:
            MessageType = ConfigModelSubscriptionStatus.self
            
        case ConfigModelSubscriptionVirtualAddressAdd.opCode:
            MessageType = ConfigModelSubscriptionVirtualAddressAdd.self
            
        case ConfigModelSubscriptionVirtualAddressDelete.opCode:
            MessageType = ConfigModelSubscriptionVirtualAddressDelete.self
            
        case ConfigModelSubscriptionVirtualAddressOverwrite.opCode:
            MessageType = ConfigModelSubscriptionVirtualAddressOverwrite.self
            
        case ConfigSIGModelSubscriptionGet.opCode:
            MessageType = ConfigSIGModelSubscriptionGet.self
            
        case ConfigSIGModelSubscriptionList.opCode:
            MessageType = ConfigSIGModelSubscriptionList.self
            
        case ConfigVendorModelSubscriptionGet.opCode:
            MessageType = ConfigVendorModelSubscriptionGet.self
            
        case ConfigVendorModelSubscriptionList.opCode:
            MessageType = ConfigVendorModelSubscriptionList.self
            
        // Resetting Node
        case ConfigNodeReset.opCode:
            MessageType = ConfigNodeReset.self
            
        case ConfigNodeResetStatus.opCode:
            MessageType = ConfigNodeResetStatus.self
            
        // Default TTL
        case ConfigDefaultTtlGet.opCode:
            MessageType = ConfigDefaultTtlGet.self
        
        case ConfigDefaultTtlSet.opCode:
            MessageType = ConfigDefaultTtlSet.self
            
        case ConfigDefaultTtlStatus.opCode:
            MessageType = ConfigDefaultTtlStatus.self
            
        // Generics
        case GenericOnOffGet.opCode:
            MessageType = GenericOnOffGet.self
            
        case GenericOnOffSet.opCode:
            MessageType = GenericOnOffSet.self
            
        case GenericOnOffSetUnacknowledged.opCode:
            MessageType = GenericOnOffSetUnacknowledged.self
            
        case GenericOnOffStatus.opCode:
            MessageType = GenericOnOffStatus.self
            
        case GenericLevelGet.opCode:
            MessageType = GenericLevelGet.self
            
        case GenericLevelSet.opCode:
            MessageType = GenericLevelSet.self
            
        case GenericLevelSetUnacknowledged.opCode:
            MessageType = GenericLevelSetUnacknowledged.self
            
        case GenericLevelStatus.opCode:
            MessageType = GenericLevelStatus.self
            
        case GenericDeltaSet.opCode:
            MessageType = GenericDeltaSet.self
            
        case GenericDeltaSetUnacknowledged.opCode:
            MessageType = GenericDeltaSetUnacknowledged.self
            
        case GenericMoveSet.opCode:
            MessageType = GenericMoveSet.self
            
        case GenericMoveSetUnacknowledged.opCode:
            MessageType = GenericMoveSetUnacknowledged.self
            
        case GenericDefaultTransitionTimeGet.opCode:
            MessageType = GenericDefaultTransitionTimeGet.self
            
        case GenericDefaultTransitionTimeSet.opCode:
            MessageType = GenericDefaultTransitionTimeSet.self
            
        case GenericDefaultTransitionTimeSetUnacknowledged.opCode:
            MessageType = GenericDefaultTransitionTimeSetUnacknowledged.self
            
        case GenericDefaultTransitionTimeStatus.opCode:
            MessageType = GenericDefaultTransitionTimeStatus.self
            
        case GenericOnPowerUpGet.opCode:
            MessageType = GenericOnPowerUpGet.self
            
        case GenericOnPowerUpSet.opCode:
            MessageType = GenericOnPowerUpSet.self
            
        case GenericOnPowerUpSetUnacknowledged.opCode:
            MessageType = GenericOnPowerUpSetUnacknowledged.self
            
        case GenericOnPowerUpStatus.opCode:
            MessageType = GenericOnPowerUpStatus.self
            
        case GenericPowerLevelGet.opCode:
            MessageType = GenericPowerLevelGet.self
            
        case GenericPowerLevelSet.opCode:
            MessageType = GenericPowerLevelSet.self
            
        case GenericPowerLevelSetUnacknowledged.opCode:
            MessageType = GenericPowerLevelSetUnacknowledged.self
            
        case GenericPowerLevelStatus.opCode:
            MessageType = GenericPowerLevelStatus.self
            
        case GenericPowerLastGet.opCode:
            MessageType = GenericPowerLastGet.self
            
        case GenericPowerLastStatus.opCode:
            MessageType = GenericPowerLastStatus.self
            
        case GenericPowerDefaultGet.opCode:
            MessageType = GenericPowerDefaultGet.self
            
        case GenericPowerDefaultStatus.opCode:
            MessageType = GenericPowerDefaultStatus.self
            
        case GenericPowerRangeGet.opCode:
            MessageType = GenericPowerRangeGet.self
            
        case GenericPowerRangeStatus.opCode:
            MessageType = GenericPowerRangeStatus.self
            
        case GenericPowerDefaultSet.opCode:
            MessageType = GenericPowerDefaultSet.self
            
        case GenericPowerDefaultSetUnacknowledged.opCode:
            MessageType = GenericPowerDefaultSetUnacknowledged.self
            
        case GenericPowerRangeSet.opCode:
            MessageType = GenericPowerRangeSet.self
            
        case GenericPowerRangeSetUnacknowledged.opCode:
            MessageType = GenericPowerRangeSetUnacknowledged.self
            
        case GenericBatteryGet.opCode:
            MessageType = GenericBatteryGet.self
            
        case GenericBatteryStatus.opCode:
            MessageType = GenericBatteryStatus.self
            
        // Other
            
        default:
            MessageType = UnknownMessage.self
        }
        
        if let MessageType = MessageType,
           var message = MessageType.init(parameters: accessPdu.parameters) {
            if var unknownMessage = message as? UnknownMessage {
                unknownMessage.opCode = accessPdu.opCode
                message = unknownMessage
            }
            if let configMessage = message as? ConfigMessage {
                logger?.i(.foundationModel, "\(message) received from: \(accessPdu.source.hex)")
                networkManager.foundationLayer.handle(configMessage: configMessage,
                                                      sentFrom: accessPdu.source, to: accessPdu.destination.address,
                                                      with: keySet)
            } else {
                logger?.i(.model, "\(message) received from: \(accessPdu.source.hex), to: \(accessPdu.destination.hex)")
            }
            networkManager.notifyAbout(newMessage: message, from: accessPdu.source, to: accessPdu.destination.address)
        }
    }
    
}

private extension AccessLayer {
    
    func key(for element: Element, and destination: MeshAddress) -> UInt32 {
        return (UInt32(element.unicastAddress) << 16) | UInt32(destination.address)
    }
    
    func createReliableContext(for pdu: AccessPdu, sentFrom element: Element, using keySet: KeySet) {
        guard let request = pdu.message as? AcknowledgedMeshMessage else {
            return
        }
        
        /// The TTL with which the request will be sent.
        let ttl = element.parentNode?.defaultTTL ?? networkManager.defaultTtl
        /// The delay after which the local Element will try to resend the
        /// request. When the response isn't received after the first retry,
        /// it will try again every time doubling the last delay until the
        /// time goes out.
        let initialDelay: TimeInterval =
            networkManager.acknowledgmentMessageInterval(ttl, pdu.segmentsCount)
        /// The timeout before which the response should be received.
        let timeout = networkManager.acknowledgmentMessageTimeout
        
        let ack = AcknowledgmentContext(for: request, sentFrom: pdu.source,
            repeatAfter: initialDelay, repeatBlock: {
                self.logger?.d(.access, "Resending \(pdu)")
                self.networkManager.upperTransportLayer.send(pdu, using: keySet)
            }, timeout: timeout, timeoutBlock: {
                self.logger?.w(.access, "Response to \(pdu) not received (timeout)")
                let category: LogCategory = request is AcknowledgedConfigMessage ? .foundationModel : .model
                self.logger?.w(category, "\(request) sent from: \(pdu.source.hex), to: \(pdu.destination.hex) timed out")
                self.reliableMessageContexts.removeAll(where: { $0.timeoutTimer == nil })
                self.networkManager.notifyAbout(AccessError.timeout,
                                                duringSendingMessage: request,
                                                from: element, to: pdu.destination.address)
            })
        reliableMessageContexts.append(ack)
    }
    
}
