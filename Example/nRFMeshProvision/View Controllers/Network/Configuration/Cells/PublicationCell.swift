//
//  PublicationCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/08/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class PublicationCell: UITableViewCell {

    @IBOutlet weak var destinationIcon: UIImageView!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var destinationSubtitleLabel: UILabel!
    @IBOutlet weak var keyIcon: UIImageView!
    @IBOutlet weak var keyLabel: UILabel!
    @IBOutlet weak var boundKeyLabel: UILabel!
    
    var publish: Publish! {
        didSet {
            let address = publish.publicationAddress
            if address.address.isUnicast {
                let meshNetwork = MeshNetworkManager.instance.meshNetwork!
                let node = meshNetwork.node(withAddress: address.address)
                if let element = node?.element(withAddress: address.address) {
                    if let name = element.name {
                        destinationLabel.text = name
                        destinationSubtitleLabel.text = node?.name ?? "Unknown Device"
                    } else {
                        let index = node!.elements.firstIndex(of: element)!
                        let name = "Element \(index + 1)"
                        destinationLabel.text = name
                        destinationSubtitleLabel.text = node?.name ?? "Unknown Device"
                    }
                } else {
                    destinationLabel.text = "Unknown Element"
                    destinationSubtitleLabel.text = "Unknown Node"
                }
                destinationIcon.tintColor = .nordicLake
                destinationIcon.image = #imageLiteral(resourceName: "ic_flag_24pt")
            } else if address.address.isGroup || address.address.isVirtual {
                switch address.address {
                case .allProxies:
                    destinationLabel.text = "All Proxies"
                    destinationSubtitleLabel.text = nil
                case .allFriends:
                    destinationLabel.text = "All Friends"
                    destinationSubtitleLabel.text = nil
                case .allRelays:
                    destinationLabel.text = "All Relays"
                    destinationSubtitleLabel.text = nil
                case .allNodes:
                    destinationLabel.text = "All Nodes"
                    destinationSubtitleLabel.text = nil
                default:
                    let meshNetwork = MeshNetworkManager.instance.meshNetwork!
                    if let group = meshNetwork.group(withAddress: address) {
                        destinationLabel.text = group.name
                        destinationSubtitleLabel.text = nil
                    } else {
                        destinationLabel.text = "Unknown group"
                        destinationSubtitleLabel.text = address.asString()
                    }
                }
                destinationIcon.image = #imageLiteral(resourceName: "tab_groups_outline_black_24pt")
                destinationIcon.tintColor = .nordicLake
            } else {
                destinationLabel.text = "Invalid address"
                destinationSubtitleLabel.text = nil
                destinationIcon.tintColor = .nordicRed
                destinationIcon.image = #imageLiteral(resourceName: "ic_flag_24pt")
            }
            
            let meshNetwork = MeshNetworkManager.instance.meshNetwork!
            if let applicationKey = meshNetwork.applicationKeys[publish.index] {
                keyIcon.tintColor = .nordicLake
                keyLabel.text = applicationKey.name
                boundKeyLabel.text = "Bound to \(applicationKey.boundNetworkKey.name)"
            } else {
                keyIcon.tintColor = .lightGray
                keyLabel.text = "No Key Selected"
                boundKeyLabel.text = nil
            }
        }
    }
}
