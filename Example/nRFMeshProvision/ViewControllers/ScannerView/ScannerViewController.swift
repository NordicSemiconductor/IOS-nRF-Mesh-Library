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
    private var meshManager: NRFMeshManager!

    // MARK: - Outlets & Actions
    @IBOutlet weak var scanActivityIndictaor: UIActivityIndicatorView!
    @IBOutlet var emptyScannerView: UIView!

    // MARK: - Scanner Class Implementation
    private func showEmptyView() {
        if !tableView.backgroundView!.subviews.contains(emptyScannerView) {
            tableView.isScrollEnabled = false
            tableView.backgroundView?.addSubview(emptyScannerView)
            let tableFrame          = tableView.frame
            let height              = CGFloat(300)
            let width               = CGFloat(350)
            let horizontalSpacing   = tableFrame.midX - (width / 2.0)
            let verticalSpacing     = tableFrame.midY - (height / 2.0)
            emptyScannerView.frame = CGRect(x: horizontalSpacing, y: verticalSpacing, width: width, height: height)
        }
    }
    
    private func hideEmptyView() {
        if tableView.backgroundView!.subviews.contains(emptyScannerView) {
            tableView.isScrollEnabled = true
            emptyScannerView.removeFromSuperview()
        }
    }

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
        tableView.backgroundView = UIView(frame: self.view.frame)
        if let aManager = (UIApplication.shared.delegate as? AppDelegate)?.meshManager {
            meshManager = aManager
            centralManager = meshManager.centralManager()
            centralManager.delegate = self
        }
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
        centralManager.stopScan()
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        hideEmptyView()
        super.viewDidDisappear(animated)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if tableView.backgroundView!.subviews.contains(emptyScannerView) {
            coordinator.animate(alongsideTransition: { (context) in
                let tableFrame          = self.tableView.frame
                let height              = CGFloat(300)
                let width               = CGFloat(350)
                let horizontalSpacing   = tableFrame.midX - (width / 2.0)
                let verticalSpacing     = tableFrame.midY - (height / 2.0)
                self.emptyScannerView.frame = CGRect(x: horizontalSpacing, y: verticalSpacing, width: width, height: height)
            })
        }
    }

    // MARK: - UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if discoveredNodes.count == 0 {
            showEmptyView()
        } else {
            hideEmptyView()
        }
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
        if let targetProxy = (UIApplication.shared.delegate as? AppDelegate)?.meshManager.proxyNode() {
            centralManager.cancelPeripheralConnection(targetProxy.blePeripheral())
        }
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
            let addCellPath = IndexPath(item: Int(discoveredNodes.count - 1), section: 0)
            tableView.insertRows(at: [addCellPath], with: .automatic)
        } else {
            if let index = discoveredNodes.index(of: newNode) {
                let oldNode = discoveredNodes[index]
                oldNode.updateRSSI(RSSI)
                let reloadCellPath = IndexPath(item: Int(index), section: 0)
                let aCell = tableView.cellForRow(at: reloadCellPath) as? ScannerCell
                DispatchQueue.main.async {
                    aCell?.showNode(oldNode)
                }
            }
        }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showConfigurationView" {
            if let configurationView = segue.destination as? MeshProvisioningDataTableViewController {
                configurationView.setTargetNode(targetNode)
            }
    }
   }
}
