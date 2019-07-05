//
//  SetPublicationViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 03/07/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

protocol PublicationDelegate {
    /// This method is called when the publication has changed.
    func publicationChanged()
}

class SetPublicationViewController: ConnectableViewController {
    
    // MARK: - Outlets & Actions
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
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
    
    @IBOutlet weak var destinationCell: UITableViewCell!
    @IBOutlet weak var friendshipCredentialsFlagSwitch: UISwitch!
    @IBOutlet weak var ttlLabel: UILabel!
    @IBOutlet weak var periodLabel: UILabel!
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
    private var periodResolution: Publish.StepResolution = ._100_milliseconds
    private var retransmissionCount: UInt8 = 0
    private var retransmissionIntervalSteps: UInt8 = 0
    
    private var selectedDestinationIndexPath: IndexPath?
    
    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        
        MeshNetworkManager.instance.delegate = self
        
        destinationCleared()
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "selectKey" {
            return model.boundApplicationKeys.count > 1
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case .some("setDestination"):
            let destination = segue.destination as! SetPublicationDestinationsViewController
            destination.model = model
            destination.selectedApplicationKey = applicationKey
            destination.selectedIndexPath = selectedDestinationIndexPath
            destination.delegate = self
        default:
            break
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.isDestination {
            return 56
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
                         option: UIAlertAction(title: "Use Node's default", style: .default, handler: { _ in
                            self.ttl = 0xFF
                         })) { value in
                            self.ttl = UInt8(value)!
        }
    }
    
    func periodSelected(_ period: Float) {
        switch period {
        case let period where period < 1.0:
            periodLabel.text = "Disabled"
            periodSteps = 0
            periodResolution = ._100_milliseconds
        case let period where period >= 1 && period < 10:
            periodLabel.text = "\(Int(period) * 100) ms"
            periodSteps = UInt8(period)
            periodResolution = ._100_milliseconds
        case let period where period >= 10 && period < 64:
            periodLabel.text = String(format: "%.1f sec", floorf(period) / 10)
            periodSteps = UInt8(period)
            periodResolution = ._100_milliseconds
        case let period where period >= 64 && period < 117:
            periodLabel.text = "\(Int(period) - 57) sec"
            periodSteps = UInt8(period) - 57
            periodResolution = ._1_second
        case let period where period >= 117 && period < 121:
            periodLabel.text = "\(Int((period + 3) / 60) - 1) min 0\(Int(period + 3) % 60) sec"
            periodSteps = UInt8(period) - 57
            periodResolution = ._1_second
        case let period where period >= 121 && period < 178:
            let sec = (Int(period) % 6) * 10
            let secString = sec == 0 ? "00" : "\(sec)"
            periodLabel.text = "\(Int(period) / 6 - 19) min \(secString) sec"
            periodSteps = UInt8(period) - 114
            periodResolution = ._10_seconds
        case let period where period >= 178 && period < 182:
            periodLabel.text = "\((Int(period) - 176) * 10) min"
            periodSteps = UInt8(period) - 176
            periodResolution = ._10_minutes
        case let period where period >= 182:
            let min = (Int(period) - 176) % 6 * 10
            let minString = min == 0 ? "00" : "\(min)"
            periodLabel.text = "\(Int(period) / 6 - 29) h \(minString) min"
            periodSteps = UInt8(period) - 176
            periodResolution = ._10_minutes
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
        print("Steps: \(steps)")
    }
    
}

extension SetPublicationViewController: DestinationDelegate {
    
    func keySelected(_ applicationKey: ApplicationKey) {
        self.applicationKey = applicationKey
    }
    func destinationSet(to title: String, subtitle: String?, withAddress address: MeshAddress, indexPath: IndexPath) {
        self.selectedDestinationIndexPath = indexPath
        self.destination = address
        self.destinationCell.textLabel?.text = title
        self.destinationCell.textLabel?.textColor = .darkText
        self.destinationCell.detailTextLabel?.text = subtitle
        self.destinationCell.tintColor = .nordicLake
        self.doneButton.isEnabled = true
    }
    
    func destinationCleared() {
        self.selectedDestinationIndexPath = nil
        self.destination = nil
        self.destinationCell.textLabel?.text = "No destination selected"
        self.destinationCell.textLabel?.textColor = .lightGray
        self.destinationCell.detailTextLabel?.text = nil
        self.destinationCell.tintColor = .lightGray
        self.doneButton.isEnabled = false
    }
    
}

extension SetPublicationViewController: MeshNetworkDelegate {
    
    func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, from source: Address) {
        
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
