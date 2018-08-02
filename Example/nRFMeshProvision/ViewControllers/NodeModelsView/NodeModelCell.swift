//
//  NodeModelCell.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 30/05/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class NodeModelCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var statusIcon: UIImageView!
    
    public func configureWithModel(_ aModel: Data, inElement anElement: CompositionElement) {
        var hasPublication  : Bool
        var hasSubscription : Bool
        
        if let publishAddress = anElement.publishAddressForModelId(aModel) {
            if let publicationType = MeshAddressTypes(rawValue: publishAddress) {
                if publicationType == .Unassigned {
                    hasPublication = false
                }else {
                    hasPublication = true
                }
            } else {
                hasPublication = true
            }
        } else {
            hasPublication = false
        }

        if anElement.subscriptionAddressesForModelId(aModel) != nil {
            if anElement.subscriptionAddressesForModelId(aModel)!.count > 0 {
                hasSubscription = true
            } else {
                hasSubscription = false
            }
        } else {
             hasSubscription = false
        }
        if hasPublication && hasSubscription {
            statusIcon.image = #imageLiteral(resourceName: "ic_pub_sub_24pt")
        } else if hasSubscription {
            statusIcon.image = #imageLiteral(resourceName: "ic_sub_24pt")
        } else if hasPublication {
            statusIcon.image = #imageLiteral(resourceName: "ic_pub_24pt")
        } else {
            statusIcon.image = nil
        }

        if aModel.count == 2 {
            subtitleLabel.text = "SIG Model ID: 0x\(aModel.hexString())"
            let upperInt = UInt16(aModel[0]) << 8
            let lowerInt = UInt16(aModel[1])
            if let modelIdentifier = MeshModelIdentifiers(rawValue: upperInt | lowerInt) {
                let modelString = MeshModelIdentifierStringConverter().stringValueForIdentifier(modelIdentifier)
                titleLabel.text = modelString
            } else {
                titleLabel.text = aModel.hexString()
            }
        } else {
            let vendorCompanyData = Data(aModel[0...1])
            let vendorModelId     = Data(aModel[2...3])
            var vendorModelInt    =  UInt32(0)
            vendorModelInt |= UInt32(aModel[0]) << 24
            vendorModelInt |= UInt32(aModel[1]) << 16
            vendorModelInt |= UInt32(aModel[2]) << 8
            vendorModelInt |= UInt32(aModel[3])
            subtitleLabel.text = "Vendor Model"
            if let vendorModelIdentifier = MeshVendorModelIdentifiers(rawValue: vendorModelInt) {
                let vendorModelString = MeshVendorModelIdentifierStringConverter().stringValueForIdentifier(vendorModelIdentifier)
                titleLabel.text = vendorModelString
            } else {
                let formattedModel = "\(vendorCompanyData.hexString()):\(vendorModelId.hexString())"
                titleLabel.text  = formattedModel
            }
        }
    }
}
