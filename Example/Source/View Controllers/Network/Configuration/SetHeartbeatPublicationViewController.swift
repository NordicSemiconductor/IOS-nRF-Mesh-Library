/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import UIKit
import nRFMeshProvision

protocol HeartbeatPublicationDelegate {
    /// This method is called when the publication has changed.
    func heartbeatPublicationChanged()
}

class SetHeartbeatPublicationViewController: ProgressViewController {
    
    // MARK: - Outlets & Actions
    
    @IBOutlet weak var doneButton: UIBarButtonItem!

    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        setPublication()
    }
    @IBAction func countDidChange(_ sender: UISlider) {
        countSelected(sender.value)
    }
    @IBAction func periodDidChange(_ sender: UISlider) {
        periodSelected(sender.value)
    }
    
    @IBOutlet weak var destinationIcon: UIImageView!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var destinationSubtitleLabel: UILabel!
    @IBOutlet weak var keyIcon: UIImageView!
    @IBOutlet weak var keyLabel: UILabel!
    
    @IBOutlet weak var ttlLabel: UILabel!
    @IBOutlet weak var countSlider: UISlider!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var periodSlider: UISlider!
    @IBOutlet weak var periodLabel: UILabel!
    
    @IBOutlet weak var relaySwitch: UISwitch!
    @IBOutlet weak var proxySwitch: UISwitch!
    @IBOutlet weak var friendSwitch: UISwitch!
    @IBOutlet weak var lowPowerSwitch: UISwitch!
    
    // MARK: - Properties
    
    var node: Node!
    var delegate: HeartbeatPublicationDelegate?
    
    private var destination: Address?
    private var networkKey: NetworkKey?
    private var ttl: UInt8 = 5 {
        didSet {
            ttlLabel.text = "\(ttl)"
        }
    }
    private var countLog: UInt8 = 0
    private var periodLog: UInt8 = 1 // The UI does not allow to set periodLog to 0.
    
    // MARK: - View Controller    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MeshNetworkManager.instance.delegate = self
        
        if let publication = node.heartbeatPublication {
            destination = publication.address
            networkKey = node.networkKeys.first { $0.index == publication.networkKeyIndex }
            ttl = publication.ttl
            countLog = 0 // This is not stored in the database and is reset each time.
            periodLog = max(publication.periodLog, 1)
            relaySwitch.isOn = publication.features.contains(.relay)
            proxySwitch.isOn = publication.features.contains(.proxy)
            friendSwitch.isOn = publication.features.contains(.friend)
            lowPowerSwitch.isOn = publication.features.contains(.lowPower)
            // Period Slider only allows setting values greater than 0.
            // Disabling periodic Heartbeat messages is done by setting
            // countSlider to 0.
            periodSlider.value = Float(periodLog - 1)
        } else {
            networkKey = node.networkKeys.first
        }
        relaySwitch.isEnabled = node.features?.relay != .notSupported
        proxySwitch.isEnabled = node.features?.proxy != .notSupported
        friendSwitch.isEnabled = node.features?.friend != .notSupported
        lowPowerSwitch.isEnabled = node.features?.friend != .notSupported
        
        reloadKeyView()
        reloadDestinationView()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath == .ttl {
            presentTTLDialog()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case .some("setDestination"):
            let viewController = segue.destination as! SetHeartbeatPublicationDestinationsViewController
            viewController.target = node
            viewController.selectedNetworkKey = networkKey
            viewController.selectedDestination = destination
            viewController.delegate = self
        default:
            break
        }
    }

}

private extension SetHeartbeatPublicationViewController {
    
    /// Presents a dialog to edit the Initial TTL for Heartbeat messages.
    func presentTTLDialog() {
        presentTextAlert(title: "Initial TTL",
                         message: "TTL = Time To Live\n\nTTL to be used when sending Heartbeat messages.\n"
                                + "Max value is 127. Message with TTL 0 will not be relayed.",
                         text: "5", placeHolder: "Default is 5",
                         type: .ttlRequired, cancelHandler: nil) { value in
            self.ttl = UInt8(value)!
        }
    }
    
    func countSelected(_ value: Float) {
        countLog = value < 18 ? UInt8(value) : 0xFF
        countLabel.text = countLog.countString
        
        // Update Period slider.
        periodSlider.isEnabled = countLog > 0
        switch countLog {
        case 0:
            periodLabel.text = "N/A"
        default:
            periodLabel.text = UInt8(periodSlider.value + 1).periodString
            break
        }
    }
    
    func periodSelected(_ value: Float) {
        periodLog = UInt8(value + 1)
        periodLabel.text = periodLog.periodString
    }
    
    func reloadKeyView() {
        if let networkKey = networkKey {
            keyIcon.tintColor = .nordicLake
            keyLabel.text = networkKey.name
        } else {
            keyIcon.tintColor = .lightGray
            keyLabel.text = "No Key Selected"
        }
    }
    
    func reloadDestinationView() {
        guard let address = destination else {
            destinationLabel.text = "No destination selected"
            if #available(iOS 13.0, *) {
                destinationLabel.textColor = .secondaryLabel
                destinationIcon.tintColor = .secondaryLabel
            } else {
                destinationLabel.textColor = .lightGray
                destinationIcon.tintColor = .lightGray
            }
            destinationSubtitleLabel.text = nil
            doneButton.isEnabled = false
            return
        }
        if #available(iOS 13.0, *) {
            destinationLabel.textColor = .label
        } else {
            destinationLabel.textColor = .darkText
        }
        let meshNetwork = MeshNetworkManager.instance.meshNetwork!
        if address.isUnicast {
            let node = meshNetwork.node(withAddress: address)
            destinationLabel.text = node?.name ?? "Unknown Device"
            destinationSubtitleLabel.text = nil
            destinationIcon.tintColor = .nordicLake
            destinationIcon.image = #imageLiteral(resourceName: "ic_flag_24pt")
            doneButton.isEnabled = true
        } else if address.isGroup {
            if let group = meshNetwork.group(withAddress: address) ?? Group.specialGroup(withAddress: address) {
                destinationLabel.text = group.name
                destinationSubtitleLabel.text = nil
            } else {
                destinationLabel.text = "Unknown group"
                destinationSubtitleLabel.text = address.asString()
            }
            destinationIcon.image = #imageLiteral(resourceName: "tab_groups_outline_black_24pt")
            destinationIcon.tintColor = .nordicLake
            doneButton.isEnabled = true
        } else {
            destinationLabel.text = "Invalid address"
            destinationSubtitleLabel.text = nil
            destinationIcon.tintColor = .nordicRed
            destinationIcon.image = #imageLiteral(resourceName: "ic_flag_24pt")
            doneButton.isEnabled = false
        }
    }
    
    func setPublication() {
        guard let destination = destination, let networkKey = networkKey,
              let node = self.node else {
            return
        }
        var features: NodeFeatures = []
        if relaySwitch.isOn { features.insert(.relay) }
        if proxySwitch.isOn { features.insert(.proxy) }
        if friendSwitch.isOn { features.insert(.friend) }
        if lowPowerSwitch.isOn { features.insert(.lowPower) }
        let periodLog = countLog > 0 ? self.periodLog : 0
        let countLog = self.countLog
        let ttl = self.ttl
        
        start("Setting Heartbeat Publication...") { [features] in
            let message: AcknowledgedConfigMessage =
                ConfigHeartbeatPublicationSet(startSending: countLog,
                                              heartbeatMessagesEvery: periodLog,
                                              secondsTo: destination,
                                              usingTtl: ttl, andNetworkKey: networkKey,
                                              andEnableHeartbeatMessagesTriggeredByChangeOf: features)!
            return try MeshNetworkManager.instance.send(message, to: node)
        }
    }
    
}

extension SetHeartbeatPublicationViewController: HeartbeatDestinationDelegate {
    
    func keySelected(_ key: NetworkKey) {
        networkKey = key
        reloadKeyView()
    }
    
    func destinationSelected(_ address: Address) {
        destination = address
        reloadDestinationView()
    }
    
}

extension SetHeartbeatPublicationViewController: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didReceiveMessage message: MeshMessage,
                            sentFrom source: Address, to destination: MeshAddress) {
        // Has the Node been reset remotely.
        guard !(message is ConfigNodeReset) else {
            (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
            done {
                let rootViewControllers = self.presentingViewController?.children
                self.dismiss(animated: true) {
                    rootViewControllers?.forEach {
                        if let navigationController = $0 as? UINavigationController {
                            navigationController.popToRootViewController(animated: true)
                        }
                    }
                }
            }
            return
        }
        // Is the message targeting the current Node?
        guard node.primaryUnicastAddress == source else {
            return
        }
        
        // Handle the message based on its type.
        switch message {
            
        case let status as ConfigHeartbeatPublicationStatus:
            done {
                if status.status == .success {
                    self.dismiss(animated: true)
                    self.delegate?.heartbeatPublicationChanged()
                } else {
                    self.presentAlert(title: "Error", message: status.message)
                }
            }
            
        default:
            break
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            failedToSendMessage message: MeshMessage,
                            from localElement: Element, to destination: MeshAddress,
                            error: Error) {
        // Ignore messages sent from model publication.
        guard message is ConfigMessage else {
            return
        }
        done {
            self.presentAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
}

private extension UInt8 {
    
    var countString: String {
        switch self {
        case 0:
            return "Disabled"
        case 0x11:
            return "65534"
        case 0xFF:
            return "Indefinitely"
        default:
            return "\(Int(pow(2.0, Double(self - 1))))"
        }
    }
    
    var periodString: String {
        assert(self > 0)
        let value = self < 0x11 ? Int(pow(2.0, Double(self - 1))) : 0xFFFF
        if value / 3600 > 0 {
            return "\(value / 3600) h \((value % 3600) / 60) min \(value % 60) sec"
        }
        if value / 60 > 0 {
            return "\(value / 60) min \(value % 60) sec"
        }
        if value == 1 {
            return "1 second"
        }
        return "\(value) seconds"
    }
    
}

private extension IndexPath {
    static let destinationSection = 0
    static let detailsSection     = 1
    
    static let ttl = IndexPath(row: 0, section: 1)
    
    var isDestination: Bool {
        return section == IndexPath.destinationSection && row == 0
    }
    
    var isDetailsSection: Bool {
        return section == IndexPath.detailsSection
    }
    
}
