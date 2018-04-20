//
//  MainNetworkViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 09/04/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class MainNetworkViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    // MARK: - Outlets and actions
    @IBOutlet weak var collectionView: UICollectionView!

    // MARK: - Properties
    var meshStateManager: MeshStateManager!

    // MARK: - Implementation
    public func presentInformationForNodeAtIndex(_ anIndex: Int) {
        let aNodeEntry = meshStateManager.state().provisionedNodes[anIndex]
        self.performSegue(withIdentifier: "ShowNodeDetails", sender: aNodeEntry)
    }

    // MARK: - UICollectionViewDataSource
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard meshStateManager != nil else {
            return 0
        }
        return meshStateManager.state().provisionedNodes.count
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        meshStateManager = MeshStateManager.restoreState()!
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        let contentSize = UIScreen.main.bounds.width - 16.0
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical //.horizontal
        layout.itemSize = CGSize(width: contentSize, height: 100)
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        layout.minimumLineSpacing = 8.0
        layout.minimumInteritemSpacing = 8.0
        collectionView.setCollectionViewLayout(layout, animated: true)
        collectionView.reloadData()
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let aCell = collectionView.dequeueReusableCell(withReuseIdentifier: "meshNodeCell",
                                                       for: indexPath) as? MeshNodeCollectionViewCell
        let aNodeEntry = meshStateManager.state().provisionedNodes[indexPath.row]
        aCell?.setupCellWithNodeEntry(aNodeEntry, atIndexPath: indexPath, andNetworkView: self)

        return aCell!
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    // MARK: - UICollectionViewDelegate
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let aNodeEntry = meshStateManager.state().provisionedNodes[indexPath.row]
        if shouldPerformSegue(withIdentifier: "ShowNodeConfiguration", sender: nil) {
            self.performSegue(withIdentifier: "ShowNodeConfiguration", sender: aNodeEntry)
        }
    }
    
    // MARK: - Navigation & Segues
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "ShowNodeDetails" {
            return true
        }
        if identifier == "ShowNodeConfiguration" {
            if (self.tabBarController as? MainTabBarViewController)!.targetProxyNode == nil {
                return false
            } else {
                return true
            }
        }
        return false
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowNodeDetails" {
            if let nodeEntry = sender as? MeshNodeEntry {
                if let infoView = segue.destination as? MeshNodeInfoTableViewController {
                    infoView.setNodeEntry(nodeEntry)
                }
            }
        } else if segue.identifier == "ShowNodeConfiguration" {
            if let nodeEntry = sender as? MeshNodeEntry {
                if let configView = segue.destination as? NodeModelsTableViewController {
                    configView.setProxyNode((self.tabBarController as? MainTabBarViewController)!.targetProxyNode!)
                    configView.setMeshStateManager(meshStateManager)
                    configView.setNodeEntry(nodeEntry)
                }
            }
        }
    }
}
