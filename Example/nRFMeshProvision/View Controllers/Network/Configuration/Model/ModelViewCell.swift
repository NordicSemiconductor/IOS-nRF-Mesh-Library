//
//  ModelViewCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 12/08/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

protocol ModelViewCellDelegate: class {
    /// Encrypts the message with the first Application Key bound to the given
    /// Model and a Network Key bound to it, and sends it to the Node
    /// to which the Model belongs to.
    ///
    /// - parameter message: The message to be sent.
    /// - parameter description: The message to be displayed for the user.
    func send(_ message: MeshMessage, description: String)
    
    /// Sends Configuration Message to the given Node to which the Model belongs to.
    ///
    /// - parameter message: The message to be sent.
    /// - parameter description: The message to be displayed for the user.
    func send(_ message: ConfigMessage, description: String)
    
    /// Whether the view is being refreshed with Pull-to-Refresh or not.
    var isRefreshing: Bool { get }
}

class ModelViewCell: UITableViewCell {
    var model: Model! {
        didSet {
            reload(using: model)
        }
    }
    weak var delegate: ModelViewCellDelegate!
    
    func reload(using model: Model) {
        // Empty.
    }
    
    /// Initializes reading of all fields in the Model View. This should
    /// send the first request, after which the cell should wait for a response,
    /// call another request, wait, etc.
    ///
    /// - returns: `True`, if any request has been made, `false` if the cell does not
    ///            provide any refreshing mechanism.
    func startRefreshing() -> Bool {
        return false
    }

    /// A callback called whenever a Mesh Message has been received
    /// from the mesh network.
    ///
    /// - parameters:
    ///   - meshNetwork: The mesh network from which the message has
    ///                  been received.
    ///   - message:     The received message.
    ///   - source:      The Unicast Address of the Element from which
    ///                  the message was sent.
    /// - returns: `True`, when another request has been made, `false` if
    ///            the request has complete.
    func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, from source: Address) -> Bool {
        return false
    }
    
    /// A callback called when an unsegmented message was sent to the
    /// `transmitter`, or when all segments of a segmented message targetting
    /// a Unicast Address were acknowledged by the target Node.
    ///
    /// - parameters:
    ///   - meshNetwork: The mesh network to which the message has
    ///                  been sent.
    ///   - message:     The message that has been sent.
    ///   - source:      The Unicast Address of the Element to which
    ///                  the message was sent.
    /// - returns: `True`, when another request has been made or an Acknowledgement
    ///            is expected, `false` if the request has complete.
    func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, to destination: Address) -> Bool {
        return false
    }

}
