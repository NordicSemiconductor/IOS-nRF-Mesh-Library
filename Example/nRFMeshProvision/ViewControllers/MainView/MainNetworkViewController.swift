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
    @IBOutlet weak var emptyNetworkView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var connectionButton: UIBarButtonItem!
    @IBAction func connectionButtonTapped(_ sender: Any) {
        handleConnectionButtonTapped()
    }
    @IBAction func addNodeButtonTapped(_ sender: Any) {
        handleAddNodeButtonTapped()
    }
    
    // MARK: - Properties
    var meshStateManager: MeshStateManager!

    // MARK: - Implementation
    public func reconnectionViewDidSelectNode(_ aNode: ProvisionedMeshNode) {
        (self.tabBarController as? MainTabBarViewController)!.targetProxyNode = aNode
        self.navigationController?.popToRootViewController(animated: true)
        self.updateConnectionButton()
    }

    func handleAddNodeButtonTapped() {
        if let mainTabBarController = self.tabBarController as? MainTabBarViewController {
            mainTabBarController.switchToAddNodesView()
        }
    }
    func handleConnectionButtonTapped() {
        if connectionButton.title == "Disconnect" {
            connectionButton.isEnabled = false
            if let proxyNode = (self.tabBarController as? MainTabBarViewController)!.targetProxyNode {
                if proxyNode.blePeripheral().state == .connected {
                    proxyNode.shouldDisconnect()
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
                        self.updateConnectionButton()
                    }
                } else {
                    self.updateConnectionButton()
                }
            } else {
                updateConnectionButton()
            }
        } else {
            self.performSegue(withIdentifier: "ShowReconnectionView", sender: self)
        }
    }

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
        
        self.updateEmptyNetworkView()
    }

    private func updateEmptyNetworkView() {
        if meshStateManager.state().provisionedNodes.count > 0 {
            emptyNetworkView.isHidden = true
        } else {
            emptyNetworkView.isHidden = false
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateConnectionButton()
    }

    private func updateConnectionButton() {
        updateEmptyNetworkView()
        //When we have no network configured, the connection button is
        //not necessary
        guard meshStateManager.state().provisionedNodes.count != 0 else {
            connectionButton.title = nil
            connectionButton.isEnabled = false
            return
        }
        
        let proxyNode = (self.tabBarController as? MainTabBarViewController)!.targetProxyNode
        if proxyNode == nil {
            connectionButton.title = "Reconnect"
            connectionButton.isEnabled = true
        } else {
            if proxyNode?.blePeripheral().state == .connected {
                connectionButton.isEnabled = true
                connectionButton.title = "Disconnect"
            } else {
                connectionButton.title = "Reconnect"
                connectionButton.isEnabled = true
            }
        }
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
        } else if segue.identifier == "ShowReconnectionView" {
            if let reconnectionView = segue.destination as? ReconnectionViewController {
                if let centralManager = (self.tabBarController as? MainTabBarViewController)!.centralManager {
                    reconnectionView.setMainViewController(self)
                    reconnectionView.setCentralManager(centralManager)
                }
            }
        }
    }
}
