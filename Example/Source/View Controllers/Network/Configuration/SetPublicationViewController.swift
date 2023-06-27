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

protocol PublicationDelegate {
    /// This method is called when the publication has changed.
    func publicationChanged()
}

class SetPublicationViewController: ProgressViewController {
    
    // MARK: - Outlets & Actions
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        setPublication()
    }
    @IBAction func periodDidChange(_ sender: UISlider) {
        periodSelected(sender.value)
    }
    @IBAction func retransmissionCountDidChange(_ sender: UISlider) {
        retransmissionCountSelected(UInt8(sender.value))
    }
    @IBAction func retransmissionIntervalDidChange(_ sender: UISlider) {
        retransmissionIntervalSelected(UInt8(sender.value))
    }
    
    @IBOutlet weak var destinationIcon: UIImageView!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var destinationSubtitleLabel: UILabel!
    @IBOutlet weak var keyIcon: UIImageView!
    @IBOutlet weak var keyLabel: UILabel!
    @IBOutlet weak var boundKeyLabel: UILabel!
    
    @IBOutlet weak var friendshipCredentialsFlagSwitch: UISwitch!
    @IBOutlet weak var ttlLabel: UILabel!
    @IBOutlet weak var periodSlider: UISlider!
    @IBOutlet weak var periodLabel: UILabel!
    @IBOutlet weak var retransmitCountSlider: UISlider!
    @IBOutlet weak var retransmitCountLabel: UILabel!
    @IBOutlet weak var retransmitIntervalSlider: UISlider!
    @IBOutlet weak var retransmitIntervalLabel: UILabel!
        
    // MARK: - Properties
    
    var model: Model!
    var delegate: PublicationDelegate?
    
    private var destination: MeshAddress?
    private var applicationKey: ApplicationKey?
    private var ttl: UInt8 = 0xFF {
        didSet {
            if ttl == 0xFF {
                ttlLabel.text = "Default"
            } else {
                ttlLabel.text = "\(ttl)"
            }
        }
    }
    private var periodSteps: UInt8 = 0
    private var periodResolution: StepResolution = .hundredsOfMilliseconds
    private var retransmissionCount: UInt8 = 0
    private var retransmissionIntervalSteps: UInt8 = 0
    
    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        
        MeshNetworkManager.instance.delegate = self
        
        if let publish = model.publish {
            destination = publish.publicationAddress
            applicationKey = model.boundApplicationKeys.first { $0.index == publish.index }
            ttl = publish.ttl
            friendshipCredentialsFlagSwitch.isOn = publish.isUsingFriendshipSecurityMaterial
            // The Period Slider displays all 4 resolutions.
            // There are 63 values for resolution 100 ms: 0 - 6.3 sec.
            // For resolution 1 sec there are 7 options less, as, as it is possible to set 1 sec as 1 step of
            // resolution 1 sec, the slider will use 10 steps of 100 ms instead. 1 sec resolution is only
            // used from 7 sec until 1 minute 3 sec.
            // Similar situation is for 10 sec resolution, which starts from 1 minute and 10 seconds (7 steps).
            // The maximum value that can be calculated using resolution 10 sec is 10 min 30 sec, therefore
            // the last resolution starts from step 2 (20 minutes).
            let period = publish.period
            switch period.resolution {
            case .hundredsOfMilliseconds:
                periodSlider.value = Float(period.resolution.rawValue * 64 + period.numberOfSteps)
            case .seconds:
                periodSlider.value = Float(period.resolution.rawValue * 64 + period.numberOfSteps - 7)
            case .tensOfSeconds:
                periodSlider.value = Float(period.resolution.rawValue * 64 + period.numberOfSteps - 7 - 7)
            case .tensOfMinutes:
                periodSlider.value = Float(period.resolution.rawValue * 64 + period.numberOfSteps - 7 - 7 - 2)
            }
            retransmitCountSlider.value = Float(publish.retransmit.count)
            retransmitIntervalSlider.value = Float(publish.retransmit.steps)
            periodDidChange(periodSlider)
            // The following 2 methods must be called in order: interval, count.
            retransmissionIntervalDidChange(retransmitIntervalSlider)
            retransmissionCountDidChange(retransmitCountSlider)
        } else {
            applicationKey = model.boundApplicationKeys.first
        }
        reloadKeyView()
        reloadDestinationView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "setDestination":
            let viewController = segue.destination as! SetPublicationDestinationsViewController
            viewController.model = model
            viewController.selectedApplicationKey = applicationKey
            viewController.selectedDestination = destination
            viewController.delegate = self
        default:
            break
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.isDestination {
            return 123
        }
        if indexPath.isDetailsSection {
            return 44
        }
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath == .ttl {
            presentTTLDialog()
        }
    }

}

private extension SetPublicationViewController {
    
    /// Presents a dialog to edit the Publish TTL.
    func presentTTLDialog() {
        presentTextAlert(title: "Publish TTL",
                         message: "TTL = Time To Live\n\nTTL limits the number of times a message can be relayed.\nMax value is 127. Message with TTL 0 will not be relayed.",
                         text: "5", placeHolder: "Default is 5",
                         type: .ttlRequired,
                         option: UIAlertAction(title: "Use Node's default", style: .default) { _ in
                            self.ttl = 0xFF
                         },
                         handler: { value in
                            self.ttl = UInt8(value)!
                         }
        )
    }
    
    func periodSelected(_ period: Float) {
        switch period {
        case let period where period < 1.0:
            periodLabel.text = "Disabled"
            periodSteps = 0
            periodResolution = .hundredsOfMilliseconds
        case let period where period >= 1 && period < 10:
            periodLabel.text = "\(Int(period) * 100) ms"
            periodSteps = UInt8(period)
            periodResolution = .hundredsOfMilliseconds
        case let period where period >= 10 && period < 64:
            periodLabel.text = String(format: "%.1f sec", floorf(period) / 10)
            periodSteps = UInt8(period)
            periodResolution = .hundredsOfMilliseconds
        case let period where period >= 64 && period < 117:
            periodLabel.text = "\(Int(period) - 57) sec"
            periodSteps = UInt8(period) - 57
            periodResolution = .seconds
        case let period where period >= 117 && period < 121:
            periodLabel.text = "\(Int((period + 3) / 60) - 1) min 0\(Int(period + 3) % 60) sec"
            periodSteps = UInt8(period) - 57
            periodResolution = .seconds
        case let period where period >= 121 && period < 178:
            let sec = (Int(period) % 6) * 10
            let secString = sec == 0 ? "00" : "\(sec)"
            periodLabel.text = "\(Int(period) / 6 - 19) min \(secString) sec"
            periodSteps = UInt8(period) - 114
            periodResolution = .tensOfSeconds
        case let period where period >= 178 && period < 182:
            periodLabel.text = "\((Int(period) - 176) * 10) min"
            periodSteps = UInt8(period) - 176
            periodResolution = .tensOfMinutes
        case let period where period >= 182:
            let min = (Int(period) - 176) % 6 * 10
            let minString = min == 0 ? "00" : "\(min)"
            periodLabel.text = "\(Int(period) / 6 - 29) h \(minString) min"
            periodSteps = UInt8(period) - 176
            periodResolution = .tensOfMinutes
        default:
            break
        }
    }
    
    func retransmissionCountSelected( _ count: UInt8) {
        retransmitIntervalSlider.isEnabled = count > 0
        if count == 0 {
            retransmitCountLabel.text = "Disabled"
            retransmitIntervalLabel.text = "N/A"
        } else if count == 1 {
            retransmitCountLabel.text = "\(count) time"
            retransmitIntervalLabel.text = "\(retransmissionIntervalSteps.interval) ms"
        } else {
            retransmitCountLabel.text = "\(count) times"
            retransmitIntervalLabel.text = "\(retransmissionIntervalSteps.interval) ms"
        }
        retransmissionCount = count
    }
    
    func retransmissionIntervalSelected(_ steps: UInt8) {
        retransmissionIntervalSteps = steps
        retransmitIntervalLabel.text = "\(steps.interval) ms"
    }
    
    func reloadKeyView() {
        if let applicationKey = applicationKey {
            keyIcon.tintColor = .nordicLake
            keyLabel.text = applicationKey.name
            boundKeyLabel.text = "Bound to \(applicationKey.boundNetworkKey.name)"
        } else {
            keyIcon.tintColor = .lightGray
            keyLabel.text = "No Key Selected"
            boundKeyLabel.text = nil
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
            doneButton.isEnabled = true
        } else if address.address.isGroup || address.address.isVirtual {
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
        guard let destination = destination, let applicationKey = applicationKey,
              let model = model,
              let node = model.parentElement?.parentNode else {
            return
        }
        let publish = Publish(to: destination, using: applicationKey,
                              usingFriendshipMaterial: friendshipCredentialsFlagSwitch.isOn, ttl: ttl,
                              period: Publish.Period(steps: periodSteps, resolution: periodResolution),
                              retransmit: Publish.Retransmit(publishRetransmitCount: retransmissionCount,
                                                             intervalSteps: retransmissionIntervalSteps))
        start("Setting Model Publication...") {
            let message: AcknowledgedConfigMessage =
                ConfigModelPublicationSet(publish, to: model) ??
                ConfigModelPublicationVirtualAddressSet(publish, to: model)!
            return try MeshNetworkManager.instance.send(message, to: node)
        }
    }
    
}

extension SetPublicationViewController: DestinationDelegate {
    
    func keySelected(_ key: ApplicationKey) {
        applicationKey = key
        reloadKeyView()
    }
    
    func destinationSelected(_ address: MeshAddress) {
        destination = address
        reloadDestinationView()
    }
    
    func destinationCleared() {
        destination = nil
        reloadDestinationView()
    }
    
}

extension SetPublicationViewController: MeshNetworkDelegate {
    
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
        guard model.parentElement?.parentNode?.primaryUnicastAddress == source else {
            return
        }
        
        // Handle the message based on its type.
        switch message {
            
        case let status as ConfigModelPublicationStatus:
            done {
                if status.status == .success {
                    self.dismiss(animated: true)
                    self.delegate?.publicationChanged()
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
    
    var interval: Int {
        return (Int(self) + 1) * 50
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
