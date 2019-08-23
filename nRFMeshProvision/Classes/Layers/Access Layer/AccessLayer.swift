//
//  AccessLayer.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 29/05/2019.
//

import Foundation

internal class AccessLayer {
    let networkManager: NetworkManager
    /// Next Transaction Identifier to use.
    var tid = UInt8.random(in: UInt8.min...UInt8.max)
    
    init(_ networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    /// This method handles the Upper Transport PDU and reads the Opcode.
    /// If the Opcode is supported, a message object is created and sent
    /// to the delegate. Otherwise, a generic MeshMessage object is created
    /// for the app to handle.
    ///
    /// - parameter upperTransportPdu: The decoded Upper Transport PDU.
    func handle(upperTransportPdu: UpperTransportPdu) {
        guard let accessPdu = AccessPdu(fromUpperTransportPdu: upperTransportPdu) else {
            return
        }
        handle(accessPdu: accessPdu)
    }
    
    /// Sends the MeshMessage to the destination. The message is encrypted
    /// using given Application Key and a Network Key bound to it.
    ///
    /// - parameter message: The Mesh Message to send.
    /// - parameter destination: The destination Address. This can be any
    ///                          valid mesh Address.
    /// - parameter applicationKey: The Application Key to sign the message with.
    func send(_ message: MeshMessage, to destination: Address, using applicationKey: ApplicationKey) {
        var m = message
        if var tranactionMessage = message as? TransactionMessage, tranactionMessage.tid == nil {
            tranactionMessage.tid = tid
            // Increase the TID to the next value modulo 255.
            if tid < 255 { tid = tid + 1 } else { tid = 0 }
            m = tranactionMessage
        }
        print("Sending \(m) to 0x\(destination.hex)") // TODO: Remove me
        networkManager.upperTransportLayer.send(m, to: destination, using: applicationKey)
    }
    
    /// Sends the ConfigMessage to the destination. The message is encrypted
    /// using the Device Key which belongs to the target Node, and first
    /// Network Key known to this Node.
    ///
    /// - parameter message: The Mesh Config Message to send.
    /// - parameter destination: The destination Address. This must be a Unicast Address.
    func send(_ message: ConfigMessage, to destination: Address) {
        guard destination.isUnicast else {
            print("Error: Address: 0x\(destination.hex) is not a Unicast Address")
            return
        }
        if networkManager.foundationLayer.handle(configMessage: message, to: destination) {
            print("Sending \(message) to 0x\(destination.hex)") // TODO: Remove me
            networkManager.upperTransportLayer.send(message, to: destination)
        }
    }
    
}

private extension AccessLayer {
    
    /// This method converts the received Access PDU to a Mesh Message and
    /// sends to `handle(meshMessage:from)` if message was successfully created.
    ///
    /// - parameter accessPdu: The Access PDU received.
    func handle(accessPdu: AccessPdu) {
        var MessageType: MeshMessage.Type?
        
        switch accessPdu.opCode {
            
        // Vendor Messages
        case let opCode where (opCode & 0xC00000) == 0xC00000:
            MessageType = networkManager.meshNetworkManager.vendorTypes[opCode] ?? UnknownMessage.self
            
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
            print("\(message) received") // TODO: Remove me
            if let configMessage = message as? ConfigMessage {
                networkManager.foundationLayer.handle(configMessage: configMessage, from: accessPdu.source)
            }
            networkManager.notifyAbout(newMessage: message, from: accessPdu.source)
        }
    }
    
}
