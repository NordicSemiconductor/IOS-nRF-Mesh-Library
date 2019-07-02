//
//  ModelViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 02/07/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class ModelViewController: ConnectableViewController {

    // MARK: - Properties
    
    var model: Model!
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = model.name ?? "Model"
    }
    
    // MARK: - Table View Controller
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case IndexPath.detailsSection:
            return IndexPath.detailsTitles.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //if indexPath.isDetailsSection {
        let cell = tableView.dequeueReusableCell(withIdentifier: "normal", for: indexPath)
        cell.textLabel?.text = indexPath.title
        cell.selectionStyle = .none
        if indexPath.isModelId {
            cell.detailTextLabel?.text = model.modelIdentifier.asString()
        }
        if indexPath.isCompany {
            if model.isBluetoothSIGAssigned {
                cell.detailTextLabel?.text = "Bluetooth SIG"
            } else {
                if let companyId = model.companyIdentifier {
                    if let companyName = CompanyIdentifier.name(for: companyId) {
                        cell.detailTextLabel?.text = companyName
                    } else {
                        cell.detailTextLabel?.text = "Unknown Company ID (\(companyId.asString()))"
                    }
                } else {
                    cell.detailTextLabel?.text = "Unknown Company ID"
                }
            }
        }
        return cell
        //}
    }

}

private extension IndexPath {
    static let detailsSection   = 0
    static let bindingsSection  = 1
    static let publishSection   = 2
    static let sunscribeSection = 3
    
    static let detailsTitles = [
        "Model ID", "Company"
    ]
    
    var title: String? {
        if isDetailsSection {
            return IndexPath.detailsTitles[row]
        }
        return nil
    }
    
    var isDetailsSection: Bool {
        return section == IndexPath.detailsSection
    }
    
    var isModelId: Bool {
        return isDetailsSection && row == 0
    }
    
    var isCompany: Bool {
        return isDetailsSection && row == 1
    }
}
