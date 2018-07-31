//
//  MainNetworkViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 09/04/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import CoreBluetooth
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
    var meshManager: NRFMeshManager!
    var currentNode: ProvisionedMeshNode? // Current node is a node we are currently running an operation against
                                          // I.E: disconnect,reconnect, etc...

    // MARK: - Implementation
    public func reconnectionViewDidSelectNode(_ aNode: ProvisionedMeshNode) {
        (UIApplication.shared.delegate as? AppDelegate)?.meshManager.updateProxyNode(aNode)
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
            if let proxyNode = (UIApplication.shared.delegate as? AppDelegate)?.meshManager.proxyNode() {
                if proxyNode.blePeripheral().state == .connected {
                    proxyNode.delegate = self
                    proxyNode.shouldDisconnect()
                    
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
        let meshState = meshManager.stateManager().state()
        let aNodeEntry = meshState.provisionedNodes[anIndex]
        self.performSegue(withIdentifier: "ShowNodeDetails", sender: aNodeEntry)
    }

    // MARK: - UICollectionViewDataSource
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if meshManager != nil {
            let meshState = meshManager.stateManager().state()
            return meshState.provisionedNodes.count
        } else {
            return 0
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        meshManager = (UIApplication.shared.delegate as? AppDelegate)?.meshManager
        collectionView.reloadData()
        let nodes = meshManager.stateManager().state().provisionedNodes
        self.updateEmptyNetworkView(withNodeCount: nodes.count)
    }

    private func updateEmptyNetworkView(withNodeCount aCount: Int) {
        if aCount > 0 {
            emptyNetworkView.isHidden = true
        } else {
            emptyNetworkView.isHidden = false
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        let contentSize = UIScreen.main.bounds.width - 16.0
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical //.horizontal
        layout.itemSize = CGSize(width: contentSize, height: 100)
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        layout.minimumLineSpacing = 8.0
        layout.minimumInteritemSpacing = 8.0
        collectionView.setCollectionViewLayout(layout, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateConnectionButton()
        meshManager.centralManager().delegate = self
        
        //Auto-rejoin
        if true ==  UserDefaults.standard.value(forKey: UserDefaultsKeys.autoRejoinKey) as? Bool ?? false {
            if meshManager.stateManager().state().provisionedNodes.count > 0 && !isProxyConnected() {
                self.performSegue(withIdentifier: "ShowReconnectionView", sender: self)
            }
        }
    }

    private func updateConnectionButton() {
        //When we have no network configured, the connection button is
        //not necessary
        let nodeCount = meshManager.stateManager().state().provisionedNodes.count
        guard nodeCount != 0 else {
            connectionButton.title = nil
            connectionButton.isEnabled = false
            return
        }
        
        if let proxyNode = (UIApplication.shared.delegate as? AppDelegate)?.meshManager.proxyNode() {
            if proxyNode.blePeripheral().state == .connected {
                connectionButton.title = "Disconnect"
            } else {
                connectionButton.title = "Reconnect"
            }
        } else {
            connectionButton.title = "Reconnect"
        }
        connectionButton.isEnabled = true
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let aCell = collectionView.dequeueReusableCell(withReuseIdentifier: "meshNodeCell",
                                                       for: indexPath) as? MeshNodeCollectionViewCell
        let allNodes = meshManager.stateManager().state().provisionedNodes
        let aNodeEntry = allNodes[indexPath.row]
        aCell?.setupCellWithNodeEntry(aNodeEntry, atIndexPath: indexPath, andNetworkView: self)

        return aCell!
    }

    func showDisconnectedAlertView() {
        let alertcontroller = UIAlertController(title: "Disconnected",
                                                message: "You are not currently connected to a mesh network.\nWould you like to reconnect?",
                                                preferredStyle: .alert)
        
        let reconnectAction = UIAlertAction(title: "Reconnect", style: .default) { (_) in
            self.performSegue(withIdentifier: "ShowReconnectionView", sender: self)
        }
        let alwaysReconnectAction = UIAlertAction(title: "Always reconnect", style: .default) { (_) in
            UserDefaults.standard.setValue(true, forKey: UserDefaultsKeys.autoRejoinKey)
            UserDefaults.standard.synchronize()
            self.performSegue(withIdentifier: "ShowReconnectionView", sender: self)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            self.dismiss(animated: true, completion: nil)
        }
        alertcontroller.addAction(reconnectAction)
        alertcontroller.addAction(alwaysReconnectAction)
        alertcontroller.addAction(cancelAction)
        self.present(alertcontroller, animated: true)
    }

    func isProxyConnected() -> Bool {
        if (UIApplication.shared.delegate as? AppDelegate)?.meshManager.proxyNode() == nil {
            return false
        } else {
            return (UIApplication.shared.delegate as? AppDelegate)?.meshManager.proxyNode()?.blePeripheral().state == .connected
        }
    }

    // MARK: - UICollectionViewDelegate
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let allNodes = meshManager.stateManager().state().provisionedNodes
        let aNodeEntry = allNodes[indexPath.row]

        if shouldPerformSegue(withIdentifier: "ShowNodeConfiguration", sender: nil) {
            self.performSegue(withIdentifier: "ShowNodeConfiguration", sender: aNodeEntry)
        } else {
            print("Not connected")
            showDisconnectedAlertView()
        }
    }

    // MARK: - Navigation & Segues
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "ShowNodeDetails" {
            return true
        }
        if identifier == "ShowNodeConfiguration" {
            return isProxyConnected()
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
                    if (UIApplication.shared.delegate as? AppDelegate)?.meshManager.proxyNode() != nil {
                        configView.setNodeEntry(nodeEntry)
                    } else {
                        print("proxy node doesn't exist")
                    }
                }
            }
        } else if segue.identifier == "ShowReconnectionView" {
            if let reconnectionView = segue.destination as? ReconnectionViewController {
                reconnectionView.setMainViewController(self)
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate Extension
extension MainNetworkViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            print("Bluetooth not available..")
        } else {
            print("Bluetooth ready!")
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral == currentNode?.blePeripheral() {
            print("target node has disconnected successfully.")
            currentNode = nil
        } else {
            if peripheral == meshManager.proxyNode()?.blePeripheral() {
                print("Proxy disconnected!")
            } else {
                print("an unknown peripheral has disconnected.")
            }
        }
        updateConnectionButton()
    }

}

// MARK: - ProvisionedMeshNodeDelegate Extension
extension MainNetworkViewController: ProvisionedMeshNodeDelegate {
    func receivedGenericOnOffStatusMessage(_ status: GenericOnOffStatusMessage) {
        print("OnOff status = \(status.onOffStatus)")
    }
    
 
    func nodeDidCompleteDiscovery(_ aNode: ProvisionedMeshNode) {
        //NOOP
    }
    
    func nodeShouldDisconnect(_ aNode: ProvisionedMeshNode) {
        //Mark this node as our target to disconnect
        //having a reference allows our node entry to be checked in cases where
        //a different node disconnects.
        currentNode = aNode
        meshManager.centralManager().delegate = self
        meshManager.centralManager().cancelPeripheralConnection(aNode.blePeripheral())
    }
    
    func receivedCompositionData(_ compositionData: CompositionStatusMessage) {
        //NOOP
    }
    
    func receivedAppKeyStatusData(_ appKeyStatusData: AppKeyStatusMessage) {
        //NOOP
    }
    
    func receivedModelAppBindStatus(_ modelAppStatusData: ModelAppBindStatusMessage) {
        //NOOP
    }
    
    func receivedModelPublicationStatus(_ modelPublicationStatusData: ModelPublicationStatusMessage) {
        //NOOP
    }
    
    func receivedModelSubsrciptionStatus(_ modelSubscriptionStatusData: ModelSubscriptionStatusMessage) {
        //NOOP
    }
    
    func receivedDefaultTTLStatus(_ defaultTTLStatusData: DefaultTTLStatusMessage) {
        //NOOP
    }

    func receivedNodeResetStatus(_ resetStatusData: NodeResetStatusMessage) {
        //NOOP
    }

    func configurationSucceeded() {
        //NOOP
    }
}
