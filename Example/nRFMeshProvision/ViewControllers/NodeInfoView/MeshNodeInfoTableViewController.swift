//
//  MeshNodeInfoTableViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 12/04/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class MeshNodeInfoTableViewController: UITableViewController {

    // MARK: - Properties
    static let cellReuseIdentifier = "NodeInfoDataCell"
    private var nodeEntry: MeshNodeEntry!

    // MARK: - Implementation
    public func setNodeEntry(_ aNodeEntry: MeshNodeEntry) {
       nodeEntry = aNodeEntry
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        //Section 0 -> Node info
        //Section 1 -> AppKey info
        //Section 2 -> Elements info
        var appKeyExists = 0
        if nodeEntry.appKeys.count > 0 {
            appKeyExists = 1
        }
        if nodeEntry.elements != nil {
            return 1 + appKeyExists + nodeEntry.elements!.count
        } else {
            return 1 + appKeyExists
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 9
        case 1:
            return nodeEntry.appKeys.count
//        case 2:
//
        default:
            return nodeEntry.elements![section - 2].totalModelCount()
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Node details"
        case 1:
            return "Application Keys"
        default:
            return "Element \(section - 1)"
        }
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        //This is just informational, no actions
        return false
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MeshNodeInfoTableViewController.cellReuseIdentifier,
                                                 for: indexPath)

        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                cell.detailTextLabel?.text = "Name"
                cell.textLabel?.text = nodeEntry.nodeName
            case 1:
                cell.detailTextLabel?.text = "Provisioning Timestamp"
                cell.textLabel?.text = DateFormatter.localizedString(from: nodeEntry.provisionedTimeStamp,
                                                                     dateStyle: .short,
                                                                     timeStyle: .short)
            case 2:
                cell.detailTextLabel?.text = "Node Identifier"
                cell.textLabel?.text = nodeEntry.nodeId.hexString()
            case 3:
                cell.detailTextLabel?.text = "Unicast Address"
                cell.textLabel?.text = nodeEntry.nodeUnicast!.hexString()
            case 4:
                cell.detailTextLabel?.text = "Company Identifier"
                if let anIdentifier = nodeEntry.companyIdentifier {
                    if let aName = CompanyIdentifiers().humanReadableNameFromIdentifier(anIdentifier) {
                        cell.textLabel?.text = aName
                    } else {
                        cell.textLabel?.text = anIdentifier.hexString()
                    }
                } else {
                    cell.textLabel?.text = "N/A"
                }
            case 5:
                cell.detailTextLabel?.text = "Product Identifier"
                if let anIdentifier = nodeEntry.productIdentifier {
                    cell.textLabel?.text = anIdentifier.hexString()
                } else {
                    cell.textLabel?.text = "N/A"
                }
            case 6:
                cell.detailTextLabel?.text = "Vendor Identifier"
                if let anIdentifier = nodeEntry.vendorIdentifier {
                    cell.textLabel?.text = anIdentifier.hexString()
                } else {
                    cell.textLabel?.text = "N/A"
                }
            case 7:
                cell.detailTextLabel?.text = "Replay Protection Count"
                if let aCount = nodeEntry.replayProtectionCount {
                    cell.textLabel?.text = aCount.hexString()
                } else {
                    cell.textLabel?.text = "N/A"
                }
            case 8:
                cell.detailTextLabel?.text = "Features"
                if let someFeatures = nodeEntry.featureFlags {
                    cell.textLabel?.text = someFeatures.hexString()
                } else {
                    cell.textLabel?.text = "N/A"
                }
            default:
                cell.detailTextLabel?.text = "Unknown field"
                cell.textLabel?.text = "N/A"
            }
        } else if indexPath.section == 1 {
            let appKey = nodeEntry.appKeys[indexPath.row]
            cell.textLabel?.text = "AppKey"
            cell.detailTextLabel?.text = appKey.hexString()
        } else {
            let element = nodeEntry.elements![indexPath.section - 2]
            if element.allSigAndVendorModels()[indexPath.row].count == 2 {
                cell.detailTextLabel?.text = "SIG Model"
                let modelData = element.allSigAndVendorModels()[indexPath.row]
                let upperInt = UInt16(modelData[0]) << 8
                let lowerInt = UInt16(modelData[1])
                if let modelIdentifier = MeshModelIdentifiers(rawValue: upperInt | lowerInt) {
                    let modelString = MeshModelIdentifierStringConverter().stringValueForIdentifier(modelIdentifier)
                    cell.textLabel?.text = modelString
                } else {
                    cell.textLabel?.text = modelData.hexString()
                }
            } else {
                cell.detailTextLabel?.text = "Vendor Model"
                let modelData = element.allSigAndVendorModels()[indexPath.row]
                let vendorCompanyData = Data(modelData[0...1])
                let vendorModelId     = Data(modelData[2...3])
                let formattedModel = "\(vendorCompanyData.hexString()):\(vendorModelId.hexString())"
                cell.textLabel?.text  = formattedModel
            }
        }

        return cell
    }
}
