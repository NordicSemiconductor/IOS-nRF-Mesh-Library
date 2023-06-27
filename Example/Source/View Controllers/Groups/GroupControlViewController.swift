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

private class Section {
    let applicationKey: ApplicationKey
    var items: [(modelId: UInt32, models: [Model])] = []
    
    init(_ applicationKey: ApplicationKey) {
        self.applicationKey = applicationKey
    }
}

private extension Array where Element == Section {
    
    subscript(applicationKey: ApplicationKey) -> Section? {
        if let index = firstIndex(where: { $0.applicationKey == applicationKey }) {
            return self[index]
        }
        return nil
    }
    
}

class GroupControlViewController: ProgressCollectionViewController {
    
    // MARK: - Properties
    
    var group: Group!
    
    private var sections: [Section] = []
    private var messageInProgress: MeshMessage?
    
    // MARK: - Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.setEmptyView(title: "No models configured",
                                    message: "No supported models are subscribed to this group.\n\n"
                                           + "nRF Mesh currently supports the following\n"
                                           + "models on the Groups tab:\n"
                                           + "- Generic OnOff Server,\n"
                                           + "- Generic Level Server,\n"
                                           + "- Scene Server,\n"
                                           + "- Scene Setup Server.\n\n"
                                           + "This limitation only applies to the app,\n"
                                           + "not the underlying mesh library.",
                                    messageImage: #imageLiteral(resourceName: "baseline-groups"))
        collectionView.delegate = self
        
        title = group.name
        
        if let network = MeshNetworkManager.instance.meshNetwork {
            let models = network.models(subscribedTo: group)
            models.forEach { model in
                model.boundApplicationKeys.forEach { key in
                    if model.isSupported {
                        var section: Section! = sections[key]
                        if section == nil {
                            section = Section(key)
                            sections.append(section)
                        }
                        if let index = section.items.firstIndex(where: { $0.modelId == model.modelId }) {
                            section.items[index].models.append(model)
                        } else {
                            section.items.append((modelId: model.modelId, models: [model]))
                        }
                    }
                }
            }
        }
        if sections.isEmpty {
            collectionView.showEmptyView()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        MeshNetworkManager.instance.delegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "edit" {
            let destination = segue.destination as! UINavigationController
            let viewController = destination.topViewController as! AddGroupViewController
            viewController.group = group
            viewController.delegate = self
            viewController.canModifyAddress = sections.isEmpty
        } else if segue.identifier == "showDetails" {
            let destination = segue.destination as! UINavigationController
            let dialog = destination.topViewController as! GroupTargetModelsViewController
            dialog.models = sender as? [Model]
        }
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        let section = sections[section]
        return section.items.count
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "key", for: indexPath) as! SectionView
        header.title.text = sections[indexPath.section].applicationKey.name.uppercased()
        return header
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = sections[indexPath.section]
        let item = section.items[indexPath.row]
        let identifier = String(format: "%08X", item.modelId)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! ModelGroupCell
        cell.group = group
        cell.applicationKey = section.applicationKey
        cell.delegate = self
        cell.models = item.models
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 didSelectItemAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        let models = section.items[indexPath.row].models
        performSegue(withIdentifier: "showDetails", sender: models)
    }
}

extension GroupControlViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let inset: CGFloat = 16
        let standardSize: CGFloat = 130
        let numberOfColumnsOnCompactWidth: CGFloat = 3
        let width = view.frame.width - inset * 2
        if width > standardSize * numberOfColumnsOnCompactWidth + inset * (numberOfColumnsOnCompactWidth - 1) {
            return CGSize(width: standardSize, height: standardSize)
        }
        return CGSize(width: width / 2 - inset / 2, height: standardSize)
    }
    
}

extension GroupControlViewController: GroupDelegate {
    
    func groupChanged(_ group: Group) {
        title = group.name
    }
    
}

extension GroupControlViewController: ModelGroupViewCellDelegate {
    
    func send(_ message: MeshMessage, description: String, using applicationKey: ApplicationKey) {
        guard messageInProgress == nil else {
            return
        }
        messageInProgress = message
        start(description) {
            return try MeshNetworkManager.instance.send(message, to: self.group, using: applicationKey)
        }
    }
    
}

extension GroupControlViewController: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didReceiveMessage message: MeshMessage,
                            sentFrom source: Address, to destination: MeshAddress) {
        // Has the Node been reset remotely.
        guard !(message is ConfigNodeReset) else {
            (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
            navigationController?.popToRootViewController(animated: true)
            return
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didSendMessage message: MeshMessage,
                            from localElement: Element, to destination: MeshAddress) {
        if messageInProgress != nil {
            messageInProgress = nil
            done()
        }
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, failedToSendMessage message: MeshMessage,
                            from localElement: Element, to destination: MeshAddress, error: Error) {
        if messageInProgress != nil {
            messageInProgress = nil
            done {
                self.presentAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
}

private extension Model {
    
    var isSupported: Bool {
        return modelIdentifier == .genericOnOffServerModelId ||
               modelIdentifier == .genericLevelServerModelId ||
               modelIdentifier == .sceneServerModelId ||
               modelIdentifier == .sceneSetupServerModelId
    }
    
    var modelId: UInt32 {
        let companyId = isBluetoothSIGAssigned ? 0 : companyIdentifier!
        return (UInt32(companyId) << 16) | UInt32(modelIdentifier)
    }
    
}
