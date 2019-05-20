//
//  NodeViewCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 16/05/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class NodeViewCell: UITableViewCell {
    
    @IBOutlet weak var nodeName: UILabel!
    @IBOutlet weak var icon: UIImageView!
    
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var company: UILabel!
    @IBOutlet weak var elements: UILabel!
    @IBOutlet weak var models: UILabel!
    
    var node: Node! {
        didSet {
            nodeName.text = node.name ?? "Unknown Device"
            address.text = node.unicastAddress.asString()
            
            if node.configComplete {
                elements.text = "\(node.elements.count)"
                let modelCount = node.elements.reduce(0, { (result, element) -> Int in
                    result + element.models.count
                })
                models.text = "\(modelCount)"
            } else {
                company.text = "Unknown"
                elements.text = "Configuration not complete"
            }
        }
    }
    
    

}
