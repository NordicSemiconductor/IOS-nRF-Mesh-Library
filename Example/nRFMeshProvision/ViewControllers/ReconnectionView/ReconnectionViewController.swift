//
//  ReconnectionViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 30/04/2018.
//  Copyright © 2018 NordicSemiconductor ASA. All rights reserved.
//

import UIKit
import CoreBluetooth
import nRFMeshProvision

class ReconnectionViewController: UITableViewController, CBCentralManagerDelegate, ProvisionedMeshNodeDelegate {

    // MARK: - Scanner Properties
    private var discoveredNodes = [UnprovisionedMeshNode]()
    private var centralManager: CBCentralManager!
    private var targetNode: ProvisionedMeshNode!
    private var mainView: MainNetworkViewController!
    private var originalCentraldelegate: CBCentralManagerDelegate?

    public func setMainViewController(_ aController: MainNetworkViewController) {
        mainView = aController
    }

    public func setCentralManager(_ aCentral: CBCentralManager) {
        centralManager = aCentral
        originalCentraldelegate = centralManager.delegate
        centralManager.delegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        centralManager.stopScan()
        centralManager.delegate = originalCentraldelegate
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard centralManager != nil else {
            print("CentralManager not set")
            return
        }
        guard centralManager.state == .poweredOn else {
            print("CentralManager not powered on")
            return
        }
        self.startProxyScanner()
    }

    // MARK: - Implementation
    private func startProxyScanner() {
        centralManager.delegate = self
        centralManager.scanForPeripherals(withServices: [MeshServiceProxyUUID],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredNodes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "proxyScannerCell", for: indexPath) as? ProxyScannerCell
        cell?.showNode(discoveredNodes[indexPath.row])
        return cell!
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let aNode = discoveredNodes[indexPath.row]
        targetNode = ProvisionedMeshNode(withUnprovisionedNode: aNode, andDelegate: self)
        centralManager.connect(targetNode.blePeripheral(), options: nil)
    }
    
    // MARK: - ProvisionedMeshNodeDelegate
    func nodeDidCompleteDiscovery(_ aNode: ProvisionedMeshNode) {
        centralManager.stopScan()
        centralManager.delegate = originalCentraldelegate
        aNode.delegate = nil
        mainView.reconnectionViewDidSelectNode(aNode)
        
    }
    
    func nodeShouldDisconnect(_ aNode: ProvisionedMeshNode) {
        //NOOP
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
    
    func configurationSucceeded() {
        //NOOP
    }

    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startProxyScanner()
        } else {
            print("Central not ready for scanning")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let tempNode = UnprovisionedMeshNode(withPeripheral: peripheral,
                                             andAdvertisementDictionary: advertisementData,
                                             RSSI: RSSI)
        if discoveredNodes.contains(tempNode) == false {
            discoveredNodes.append(tempNode)
        } else {
            if let anIndex = discoveredNodes.index(of: tempNode) {
                discoveredNodes[anIndex].updateRSSI(RSSI)
            } else {
                //NOOP
                return
            }
        }
        tableView.reloadData()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if targetNode.blePeripheral() == peripheral {
            targetNode.discover()
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if targetNode.blePeripheral() == peripheral {
            print("Failed to connect!")
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if targetNode.blePeripheral() == peripheral {
            print("Disconnected node!")
        }
    }
}
