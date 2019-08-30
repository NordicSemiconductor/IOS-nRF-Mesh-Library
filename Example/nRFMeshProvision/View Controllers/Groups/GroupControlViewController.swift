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

class GroupControlViewController: ConnectableCollectionViewController {
    
    // MARK: - Properties
    
    var group: Group!
    
    private var sections: [Section] = []
    
    // MARK: - Implementation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.setEmptyView(title: "No models configured", message: "No models are subscribed to this group.", messageImage: #imageLiteral(resourceName: "baseline-groups"))
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
            let bottomSheet = destination.topViewController as! BottomSheetViewController
            bottomSheet.models = sender as? [Model]
        }
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let section = sections[section]
        return section.items.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "key", for: indexPath) as! SectionView
        header.title.text = sections[indexPath.section].applicationKey.name.uppercased()
        return header
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
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
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
        return modelIdentifier == 0x1000 ||
               modelIdentifier == 0x1002
    }
    
    var modelId: UInt32 {
        let companyId = isBluetoothSIGAssigned ? 0 : companyIdentifier!
        return (UInt32(companyId) << 16) | UInt32(modelIdentifier)
    }
    
}
