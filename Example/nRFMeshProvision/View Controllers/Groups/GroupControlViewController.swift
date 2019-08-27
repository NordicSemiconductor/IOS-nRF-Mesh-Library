//
//  GroupControlViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 27/08/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

private class Section {
    let applicationKey: ApplicationKey
    var sigModelIds: [UInt16] = []
    var hasVendorModels: Bool = false
    
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

class GroupControlViewController: ConnectableCollectionViewController {
    
    // MARK: - Properties
    
    var group: Group!
    
    private var sections: [Section] = []
    
    // MARK: - Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = group.name
        
        if let network = MeshNetworkManager.instance.meshNetwork {
            let models = network.models(subscribedTo: group)
            models.forEach { model in
                model.boundApplicationKeys.forEach { key in
                    var section = sections[key]
                    let newSection = section == nil
                    if newSection {
                        section = Section(key)
                    }
                    if model.isBluetoothSIGAssigned {
                        if model.isSupported && !section!.sigModelIds.contains(model.modelIdentifier) {
                            section!.sigModelIds.append(model.modelIdentifier)
                            if newSection {
                                sections.append(section!)
                            }
                        }
                    } else {
                        section!.hasVendorModels = true
                        if newSection {
                            sections.append(section!)
                        }
                    }
                }
            }
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
        return section.sigModelIds.count + (section.hasVendorModels ? 1 : 0)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "key", for: indexPath) as! SectionView
        header.title.text = sections[indexPath.section].applicationKey.name.uppercased()
        return header
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = sections[indexPath.section]
        var identifier = "1000" //"vendor" // TODO: Uncomment
        if indexPath.row < section.sigModelIds.count {
            let modelId = section.sigModelIds[indexPath.row]
            identifier = modelId.hex
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! ModelGroupCell
        cell.group = group
        cell.applicationKey = section.applicationKey
        cell.delegate = self
        return cell
    }

}

extension GroupControlViewController: ModelGroupViewCellDelegate {
    
    func send(_ message: MeshMessage, description: String, using applicationKey: ApplicationKey) {
        whenConnected { alert in
            alert?.message = description
            MeshNetworkManager.instance.send(message, to: self.group, using: applicationKey)
        }
    }
    
}

extension GroupControlViewController: MeshNetworkDelegate {
    
    func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, from source: Address) {
        // Has the Node been reset remotely.
        guard !(message is ConfigNodeReset) else {
            (UIApplication.shared.delegate as! AppDelegate).meshNetworkDidChange()
            navigationController?.popToRootViewController(animated: true)
            return
        }
    }
    
    func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, to destination: Address) {
        done()
    }
    
    func meshNetwork(_ meshNetwork: MeshNetwork, failedToDeliverMessage message: MeshMessage, to destination: Address, error: Error) {
        done() {
            self.presentAlert(title: "Error", message: "Message could not be sent.")
        }
    }
}

private extension Model {
    
    var isSupported: Bool {
        return modelIdentifier == 0x1000
    }
    
}
