//
//  ScannerViewController.swift
//  nRFMeshProvision
//
//  Created by mostafaberg on 12/18/2017.
//  Copyright (c) 2017 mostafaberg. All rights reserved.
//

import UIKit
import CoreBluetooth
import nRFMeshProvision

class ScannerViewController: UITableViewController, CBCentralManagerDelegate {
    // MARK: - Class properties
    private var centralManager: CBCentralManager! = nil
    private var targetNode: UnprovisionedMeshNode!
    private var targetNodeId: Data!
    private var discoveredNodes: [UnprovisionedMeshNode] = []
    private var stateManager: MeshStateManager!

    // MARK: - Outlets & Actions
    @IBOutlet weak var scanActivityIndictaor: UIActivityIndicatorView!

    // MARK: - Scanner Class Implementation
    private func startNodeScan() {
        scanActivityIndictaor.startAnimating()
        //Take back the delegate in case of return from other views that were the central's delegate.
        centralManager.delegate = self
        if !centralManager.isScanning {
            centralManager.scanForPeripherals(withServices: [MeshServiceProvisioningUUID],
                                              options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }

    private func stopNodeScan() {
        if centralManager.isScanning {
            centralManager.stopScan()
        }
        scanActivityIndictaor.stopAnimating()
    }

    // MARK: - UIViewController Implementation
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = (self.tabBarController as? MainTabBarViewController)!.centralManager
        centralManager.delegate = self
        stateManager = MeshStateManager.restoreState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        discoveredNodes.removeAll()
        tableView.reloadData()
        if centralManager.state == .poweredOn {
            centralManager.stopScan()
            startNodeScan()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        centralManager.stopScan()
    }
    // MARK: - UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredNodes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "peripheralCell", for: indexPath) as? ScannerCell
        //Node name
        let node = discoveredNodes[indexPath.row]
        cell?.showNode(node)
        return cell!
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        stopNodeScan()
        targetNode    = discoveredNodes[indexPath.row]
        performSegue(withIdentifier: "showConfigurationView", sender: nil)
    }

    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startNodeScan()
        }
   }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        let newNode = UnprovisionedMeshNode(withPeripheral: peripheral, andAdvertisementDictionary: advertisementData, RSSI: RSSI)
        if discoveredNodes.contains(newNode) == false {
            discoveredNodes.append(newNode)
        } else {
            if let index = discoveredNodes.index(of: newNode) {
                let oldNode = discoveredNodes[index]
                oldNode.updateRSSI(RSSI)
            } else {
                //NOOP
                return
            }
        }
        tableView.reloadData()
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showConfigurationView" {
            if let configurationView = segue.destination as? MeshProvisioningDataTableViewController {
                configurationView.setMeshState(stateManager)
                configurationView.setTargetNode(targetNode, andCentralManager: centralManager)
            }
    }
   }
}
