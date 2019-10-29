//
//  MessageHandle.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 25/09/2019.
//

import Foundation

/// The mesh message handle is returned upon sending a mesh message
/// and allows the message to be cancelled.
///
/// Only segmented or acknowledged messages may be cancelled.
/// Unsegmented unacknowledged messages are sent almost instantaneously
/// (depending on the connection interval and message size)
/// and therefore cannot be cancelled.
///
/// The handle contains information about the message that was sent:
/// its opcode, source and destination addresses.
public struct MessageHandle {
    let opCode: UInt32
    let source: Address
    let destination: Address
    weak var manager: MeshNetworkManager?
    
    init(for message: MeshMessage,
         sentFrom source: Address, to destination: Address,
         using manager: MeshNetworkManager) {
        self.opCode = message.opCode
        self.source = source
        self.destination = destination
        self.manager = manager
    }
    
    /// Cancels sending the message.
    ///
    /// Only segmented or acknowledged messages may be cancelled.
    /// Unsegmented unacknowledged messages are sent almost instantaneously
    /// (depending on the connection interval and message size)
    /// and therefore cannot be cancelled.
    public func cancel() {
        try? manager?.cancel(self)
    }
    
}
