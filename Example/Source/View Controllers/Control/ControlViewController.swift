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
    let element: MeshElement
    var models: [Model] = []
    
    init(_ element: MeshElement) {
        self.element = element
    }
}

private extension Array where Element == Section {
    
    subscript(element: MeshElement) -> Section? {
        if let index = firstIndex(where: { $0.element == element }) {
            return self[index]
        }
        return nil
    }
    
}

class ControlViewController: ProgressCollectionViewController {
    
    // MARK: - Properties
    
    private var sections: [Section] = []
    
    // MARK: - Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.setEmptyView(title: "No local node",
                                    message: "The local provisioner has no\nunicast address assigned.\n\nGo to Settings to set the address.",
                                    messageImage: #imageLiteral(resourceName: "baseline-bulb"))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sections.removeAll()
        if let network = MeshNetworkManager.instance.meshNetwork {
            let elements = network.localProvisioner?.node?.elements
            elements?.forEach { element in
                element.models.forEach { model in
                    if model.isSupported {
                        var section: Section! = sections[element]
                        if section == nil {
                            section = Section(element)
                            sections.append(section)
                        }
                        section.models.append(model)
                    }
                }
            }
        }
        collectionView.reloadData()
        
        if sections.isEmpty {
            collectionView.showEmptyView()
        } else {
            collectionView.hideEmptyView()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        MeshNetworkManager.instance.delegate = self
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let section = sections[section]
        return section.models.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "element", for: indexPath) as! ElementSectionView
        let element = sections[indexPath.section].element
        header.title.text = element.name?.uppercased() ?? "ELEMENT \(element.index + 1)"
        return header
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = sections[indexPath.section]
        let model = section.models[indexPath.row]
        let identifier = String(format: "%08X", model.modelId)
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! ModelControlCell
        cell.model = model
        return cell as! UICollectionViewCell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        let model = section.models[indexPath.row]
        let element = model.parentElement!
        let name = model.isSimpleOnOffClient ? "Simple OnOff Client" : model.name ?? "Unknown Model"
        var message: String?
        if !model.subscriptions.isEmpty {
            let groups = model.subscriptions.map { $0.name }.joined(separator: ", ")
            message = "This model is subscribed to the following groups: \(groups)."
            
            if let publish = model.publish {
                let network = MeshNetworkManager.instance.meshNetwork!
                let applicationKey = network.applicationKeys[publish.index]
                let group = network.group(withAddress: publish.publicationAddress) ?? Group.specialGroup(withAddress: publish.publicationAddress)
                message! += " It is also set up to publish to \(group?.name ?? publish.publicationAddress.asString()) using \(applicationKey?.name ?? "an unknown Application Key")."
            }
        } else if let publish = model.publish {
            let network = MeshNetworkManager.instance.meshNetwork!
            let applicationKey = network.applicationKeys[publish.index]
            let group = network.group(withAddress: publish.publicationAddress) ?? Group.specialGroup(withAddress: publish.publicationAddress)
            message = "This model is set up to publish to \(group?.name ?? publish.publicationAddress.asString()) using \(applicationKey?.name ?? "an unknown Application Key")."
        } else {
            message = "This model does not have subscription or publication set. Go to Network tab, find the local provisioner and configure the \(name) on \(element.name ?? "Element \(element.index + 1)")."
        }
        presentAlert(title: name, message: message)
    }

}

extension ControlViewController: UICollectionViewDelegateFlowLayout {
    
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

extension ControlViewController: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didReceiveMessage message: MeshMessage,
                            sentFrom source: Address, to destination: MeshAddress) {
        // Ignore.
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didSendMessage message: MeshMessage,
                            from localElement: Element, to destination: MeshAddress) {
        // Ignore.
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, failedToSendMessage message: MeshMessage,
                            from localElement: Element, to destination: MeshAddress, error: Error) {
        // Ignore.
    }
}

private extension Model {
    
    var isSupported: Bool {
        return modelIdentifier == .genericOnOffServerModelId ||
               modelIdentifier == .genericOnOffClientModelId ||
               modelIdentifier == .genericLevelServerModelId ||
               modelIdentifier == .genericLevelClientModelId ||
               isSimpleOnOffClient
    }
    
    var isSimpleOnOffClient: Bool {
        return modelIdentifier == .simpleOnOffClientModelId &&
               companyIdentifier == .nordicSemiconductorCompanyId
    }
    
}
