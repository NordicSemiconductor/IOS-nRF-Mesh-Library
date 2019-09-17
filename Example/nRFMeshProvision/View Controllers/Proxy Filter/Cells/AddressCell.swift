//
//  AddressCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 16/09/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class AddressCell: UITableViewCell {

    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subtitle: UILabel!
    @IBOutlet weak var detail: UILabel!
    
    var address: Address! {
        didSet {
            let meshNetwork = MeshNetworkManager.instance.meshNetwork!
            switch address! {
                
            case let address where address.isUnicast:
                let elements = meshNetwork.nodes.flatMap { $0.elements }
                let targetElement = elements.first { $0.unicastAddress == address }
                
                title.text = targetElement != nil ?
                    targetElement!.name ?? "Element \(targetElement!.index + 1)" : "Unknown Element"
                subtitle.text = targetElement?.parentNode?.name ?? "Unknown device"
                icon.image = #imageLiteral(resourceName: "ic_flag_24pt")
                tintColor = .nordicLake
                
            case let address where address.isSpecialGroup:
                icon.image = #imageLiteral(resourceName: "ic_group_24pt")
                subtitle.text = nil
                switch address {
                case Address.allProxies: title.text = "All Proxies"
                case Address.allRelays:  title.text = "All Relays"
                case Address.allFriends: title.text = "All Friends"
                default:                 title.text = "All Nodes"
                }
                tintColor = .nordicLake
                
            case let address where address.isGroup || address.isVirtual:
                let group = meshNetwork.groups.first { $0.address.address == address }
                
                title.text = group?.name ?? "Unknown group"
                subtitle.text = group?.address.virtualLabel?.uuidString
                icon.image = #imageLiteral(resourceName: "ic_group_24pt")
                tintColor = .nordicLake
                
            default:
                title.text = "Invalid address"
                icon.image = #imageLiteral(resourceName: "ic_flag_24pt")
                tintColor = .nordicRed
            }
            detail.text = address.asString()
        }
    }
    
}
