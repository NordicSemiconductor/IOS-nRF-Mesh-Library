//
//  GenericLevelClientHandler.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/10/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import nRFMeshProvision

class GenericLevelClientHandler: ModelHandler {
    var manager: MeshNetworkManager!
    var model: Model!
    let messageTypes: [UInt32 : MeshMessage.Type]
    
    init() {
        let types: [GenericMessage.Type] = [
            GenericLevelStatus.self
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
    
    /// Sends the Generic Level Set message, or Generic Level
    /// Set Unacknowledged, depending on the parameter.
    ///
    /// - parameter level: The level.
    /// - parameter acknowledged: Should the message be sent as
    ///                           acknowledged one.
    /// - returns: The message handle if the message was sent,
    ///            `nil` otherwise.
    func set(_ level: Int16, acknowledged: Bool) -> MessageHandle? {
        if acknowledged {
            return send(GenericLevelSet(level: level))
        } else {
            return send(GenericLevelSetUnacknowledged(level: level))
        }
    }
    
}
