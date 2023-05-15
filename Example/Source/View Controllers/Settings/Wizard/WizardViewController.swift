/*
* Copyright (c) 2023, Nordic Semiconductor
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

private struct Config {
    let name: String
    let minValue: Int
    let icon: String
}

protocol WizardDelegate: AnyObject {
    func importNetwork()
    func createNetwork(withFixedKeys fixed: Bool, networkKeys: Int, applicationKeys: Int, groups: Int, virtualGroups: Int, scenes: Int)
}

class WizardViewController: UIViewController,
                            UIAdaptivePresentationControllerDelegate {
    // MARK: - Outlets and Actions
    
    @IBOutlet weak var placeholder: UIView!
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var option: UISegmentedControl!
    
    @IBAction func optionDidChange(_ sender: UISegmentedControl) {
        table.reloadData()
        
        if sender.selectedSegmentIndex == 3 {
            dismiss(animated: true) { [weak self] in
                self?.delegate?.importNetwork()
            }
        }
    }
    
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        if option.selectedSegmentIndex == 0 {
            delegate?.createNetwork(withFixedKeys: false,
                networkKeys: 1,
                applicationKeys: 0,
                groups: 0,
                virtualGroups: 0,
                scenes: 0)
        } else {
            delegate?.createNetwork(
                withFixedKeys: option.selectedSegmentIndex == 2,
                networkKeys: customValues[0],
                applicationKeys: customValues[1],
                groups: customValues[2],
                virtualGroups: customValues[3],
                scenes: customValues[4])
        }
        dismiss(animated: true)
    }
    
    // MARK: - Public variables
    
    weak var delegate: WizardDelegate?
    
    // MARK: - Private variables
    
    private var presets: [Config]!
    private var customValues: [Int] = [1, 1, 3, 1, 4]
    
    // MARK: - Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make the dialog modal (non-dismissable).
        navigationController?.presentationController?.delegate = self

        placeholder.setEmptyView(title: "Welcome",
                          message: "nRF Mesh allows to provision, configure\nand control Bluetooth mesh devices.\n\nStart by creating a new mesh network.",
                          messageImage: #imageLiteral(resourceName: "baseline-network"))
        placeholder.showEmptyView()
        
        presets = [
            Config(name: "Network Keys",     minValue: 1, icon: "ic_vpn_key_24pt"),
            Config(name: "Application Keys", minValue: 0, icon: "ic_vpn_key_24pt"),
            Config(name: "Groups",           minValue: 0, icon: "ic_group_24pt"),
            Config(name: "Virtual Groups",   minValue: 0, icon: "ic_group_24pt"),
            Config(name: "Scenes",           minValue: 0, icon: "ic_scenes_24pt")
        ]
        
        table.delegate = self
        table.dataSource = self
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // Do not allow to dismiss the dialog.
        return false
    }

}

extension WizardViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard option.selectedSegmentIndex < 3 else {
            return 0
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard option.selectedSegmentIndex < 3 else {
            return 0
        }
        return presets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let preset = presets[indexPath.row]
        
        if option.selectedSegmentIndex == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "right", for: indexPath)
            cell.textLabel?.text = preset.name
            cell.detailTextLabel?.text = "\(preset.minValue)"
            cell.imageView?.image = UIImage(named: preset.icon)
            return cell
        }
        let cellIdentifier = indexPath.row < 2 ? "customKey" : "custom"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CustomConfigCell
        cell.icon = preset.icon
        cell.label = preset.name
        if indexPath.row < 2 {
            cell.detailText = option.selectedSegmentIndex == 1 ? "Random" : "Fixed"
        }
        cell.minValue = preset.minValue
        cell.value = customValues[indexPath.row]
        cell.delegate = self
        cell.tag = indexPath.row
        return cell
    }
    
}

extension WizardViewController: CustomConfigDelegate {
    
    func value(of cell: CustomConfigCell, didChangeTo value: Int) {
        customValues[cell.tag] = value
    }
    
}
