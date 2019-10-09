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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
