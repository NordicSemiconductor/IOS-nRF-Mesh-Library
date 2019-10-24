//
//  ControlViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 01/10/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

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
        cell.delegate = self
        return cell as! UICollectionViewCell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        let model = section.models[indexPath.row]
        let element = model.parentElement!
        let name = model.name ?? "Unknown Model"
        var message: String?
        if !model.subscriptions.isEmpty {
            let groups = model.subscriptions.map({ $0.name }).joined(separator: ", ")
            message = "This model is subscribed to the following groups: \(groups)."
            
            if let publish = model.publish {
                let network = MeshNetworkManager.instance.meshNetwork!
                let applicationKey = network.applicationKeys[publish.index]
                let group = network.group(withAddress: publish.publicationAddress)
                message! += " It is also set up to publish to \(group?.name ?? publish.publicationAddress.asString()) using \(applicationKey?.name ?? "unknown Application Key")."
            }
        } else if let publish = model.publish {
            let network = MeshNetworkManager.instance.meshNetwork!
            let applicationKey = network.applicationKeys[publish.index]
            let group = network.group(withAddress: publish.publicationAddress)
            message = "This model is set up to publish to \(group?.name ?? publish.publicationAddress.asString()) using \(applicationKey?.name ?? "unknown Application Key")."
        } else {
            message = "This model does not have subscription or publication set. Go to Network tab, find the local provisioner and configure the \(name) on \(element.name ?? "Element \(element.index + 1)")."
        }
        presentAlert(title: name, message: message)
    }

}

extension ControlViewController: ModelControlDelegate {
    
    func publish(_ message: MeshMessage, description: String, fromModel model: Model) {
        start(description) {
            return MeshNetworkManager.instance.publish(message, fromModel: model)
        }
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
                            sentFrom source: Address, to destination: Address) {
        // Ignore.
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didSendMessage message: MeshMessage,
                            from localElement: Element, to destination: Address) {
        done()
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, failedToSendMessage message: MeshMessage,
                            from localElement: Element, to destination: Address, error: Error) {
        done() {
            self.presentAlert(title: "Error", message: error.localizedDescription)
        }
    }
}

private extension Model {
    
    var isSupported: Bool {
        return modelIdentifier == 0x1000 ||
               modelIdentifier == 0x1001 ||
               modelIdentifier == 0x1002 ||
               modelIdentifier == 0x1003
    }
    
    var modelId: UInt32 {
        let companyId = isBluetoothSIGAssigned ? 0 : companyIdentifier!
        return (UInt32(companyId) << 16) | UInt32(modelIdentifier)
    }
    
}
