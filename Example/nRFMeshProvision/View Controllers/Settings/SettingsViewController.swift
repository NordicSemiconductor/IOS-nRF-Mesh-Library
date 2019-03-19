//
//  SettingsViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 18/03/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    @IBOutlet weak var networkName: UITableViewCell!
    @IBOutlet weak var globalTTL: UITableViewCell!
    @IBOutlet weak var provisionerAddress: UITableViewCell!
    
    @IBOutlet weak var networkKey: UITableViewCell!
    @IBOutlet weak var keyIndex: UITableViewCell!
    @IBOutlet weak var flags: UITableViewCell!
    @IBOutlet weak var ivIndex: UITableViewCell!
    
    @IBOutlet weak var appKeys: UITableViewCell!
    
    @IBOutlet weak var appVersion: UITableViewCell!
    @IBOutlet weak var appBuildNumber: UITableViewCell!
    
    override func viewDidLoad() {
        appVersion.detailTextLabel?.text = getAppVersion()
        appBuildNumber.detailTextLabel?.text = getAppBuildNumber()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Private methods -
    
    /// Returns Application version as String.
    private func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "N/A"
    }
    
    /// Returns Build Number as String.
    private func getAppBuildNumber() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return version
        }
        return "N/A"
    }
}
