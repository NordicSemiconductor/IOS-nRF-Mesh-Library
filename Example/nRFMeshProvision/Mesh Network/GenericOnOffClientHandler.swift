//
//  GenericOnOffClientHandler.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 01/10/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import nRFMeshProvision

class GenericOnOffClientHandler: ModelHandler {
    var manager: MeshNetworkManager!
    var model: Model!
    let messageTypes: [UInt32 : MeshMessage.Type]
    
    init() {
        let types: [GenericMessage.Type] = [
            GenericOnOffStatus.self
        ]
        messageTypes = types.toMap()
    }
    
    // MARK: - Message handlers
    
    func handle(acknowledgedMessage request: AcknowledgedMeshMessage,
                sentFrom source: Address) -> MeshMessage {
        fatalError("Not possible")
    }
    
    func handle(unacknowledgedMessage message: MeshMessage,
                sentFrom source: Address) {
        // Not possible.
    }
    
    func handle(response: MeshMessage, toAcknowledgedMessage request: AcknowledgedMeshMessage,
                sentFrom source: Address) {
        // Ignore.
    }
    
    // MARK: - API
    
    /// Sends the Generic On Off Set message, or Generic On Off
    /// Set Unacknowledged, depending on the parameter.
    ///
    /// - parameter on: The state.
    /// - parameter acknowledged: Should the message be sent as
    ///                           acknowledged one.
    /// - returns: The message handle if the message was sent,
    ///            `nil` otherwise.
    func set(_ on: Bool, acknowledged: Bool) -> MessageHandle? {
        if acknowledged {
            return send(GenericOnOffSet(on))
        } else {
            return send(GenericOnOffSetUnacknowledged(on))
        }
    }
    
}
