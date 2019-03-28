//
//  KeyRefreshPhase.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 25/03/2019.
//

import Foundation

/// The type representing Key Refresh phase.
public enum KeyRefreshPhase: Int, Codable {
    /// Phase 0: Normal Operation.
    case normalOperation  = 0
    /// Phase 1: Distributing new keys to all nodes. Nodes will transmit using
    /// old keys, but can receive using old and new keys.
    case distributingKeys = 1
    /// Phase 2: Transmitting a Secure Network beacon that signals to the network
    /// that all nodes have the new keys. The nodes will then transmit using
    /// the new keys but can receive using the old or new keys.
    case finalizing       = 2
}
