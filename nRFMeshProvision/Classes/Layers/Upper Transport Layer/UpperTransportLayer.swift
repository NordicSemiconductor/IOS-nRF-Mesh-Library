//
//  UpperTransportLayer.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 28/05/2019.
//

import Foundation

internal class UpperTransportLayer {
    let networkManager: NetworkManager
    let meshNetwork: MeshNetwork
    let defaults: UserDefaults
    
    private var logger: LoggerDelegate? {
        return networkManager.manager.logger
    }
    
    init(_ networkManager: NetworkManager) {
        self.networkManager = networkManager
        self.meshNetwork = networkManager.meshNetwork!
        self.defaults = UserDefaults(suiteName: meshNetwork.uuid.uuidString)!
    }
    
    /// Handles received Lower Transport PDU.
    /// Depending on the PDU type, the message will be either propagated to
    /// Access Layer, or handled internally.
    ///
    /// - parameter lowetTransportPdu: The Lower Trasport PDU received.
    func handle(lowerTransportPdu: LowerTransportPdu) {
        switch lowerTransportPdu.type {
        case .accessMessage:
            let accessMessage = lowerTransportPdu as! AccessMessage
            if let (upperTransportPdu, keySet) = UpperTransportPdu.decode(accessMessage, for: meshNetwork) {
                logger?.i(.upperTransport, "\(upperTransportPdu) received")
                networkManager.accessLayer.handle(upperTransportPdu: upperTransportPdu, sentWith: keySet)
            } else {
                logger?.w(.upperTransport, "Failed to decode PDU")
            }
        case .controlMessage:
            let controlMessage = lowerTransportPdu as! ControlMessage
            switch controlMessage.opCode {
            case 0x0A:
                if let heartbeat = HearbeatMessage(fromControlMessage: controlMessage) {
                    logger?.i(.upperTransport, "\(heartbeat) received")
                    handle(hearbeat: heartbeat)
                }
            default:
                logger?.w(.upperTransport, "Unsupported Control Message received (opCode: \(controlMessage.opCode))")
                // Other Control Messages are not supported.
                break
            }
        }
    }
    
    /// Encrypts the Access PDU using given key set and sends it down to
    /// Lower Transport Layer.
    ///
    /// - parameter pdu: The Access PDU to be sent.
    /// - parameter keySet: The set of keys to encrypt the message with.
    func send(_ accessPdu: AccessPdu, using keySet: KeySet) {
        // Get the current sequence number for source Element's address.
        let source = accessPdu.localElement!.unicastAddress
        let sequence = UInt32(defaults.integer(forKey: "S\(source.hex)"))
        
        let pdu = UpperTransportPdu(fromAccessPdu: accessPdu,
                                    usingKeySet: keySet, sequence: sequence)
        
        logger?.i(.upperTransport, "Sending \(pdu) encrypted using key: \(keySet)")
        
        let isSegmented = pdu.transportPdu.count > 15 || accessPdu.isSegmented
        let networkKey = keySet.networkKey
        networkManager.lowerTransportLayer.send(upperTransportPdu: pdu,
                                                asSegmentedMessage: isSegmented,
                                                usingNetworkKey: networkKey)
    }
    
}

private extension UpperTransportLayer {
    
    func handle(hearbeat: HearbeatMessage) {
        // TODO: Implement handling Heartbeat messages
    }
    
}
