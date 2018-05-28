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

class ReconnectionViewController: UITableViewController {

    // MARK: - Outlets and actions
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var emptyScannerView: UIView!
    
    // MARK: - Scanner Properties
    private var discoveredNodes = [UnprovisionedMeshNode]()
    private var centralManager: CBCentralManager!
    private var meshManager: NRFMeshManager!
    private var targetNode: ProvisionedMeshNode!
    private var mainView: MainNetworkViewController!
    private var originalCentraldelegate: CBCentralManagerDelegate?
    private var currentNetworkIdentity: Data?
    private var alertController: UIAlertController?

    public func setMainViewController(_ aController: MainNetworkViewController) {
        mainView = aController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundView = UIView(frame: self.view.frame)
    }

    override func viewWillDisappear(_ animated: Bool) {
        centralManager.stopScan()
        activityIndicator.stopAnimating()
        centralManager.delegate = originalCentraldelegate
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.hideEmptyView()
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let aMeshManager = (UIApplication.shared.delegate as? AppDelegate)?.meshManager {
            meshManager = aMeshManager
            centralManager = meshManager.centralManager()
            originalCentraldelegate = centralManager.delegate
            centralManager.delegate = self
            //Scanning requires comparing network identity to the current calculated one, we do this once
            //to avoid recalculation on every discovery
            let netKey = meshManager.stateManager().state().netKey
            currentNetworkIdentity = OpenSSLHelper().calculateK3(withN: netKey)
        } else {
            print("Mesh Manager not present!")
            mainView.dismiss(animated: true, completion: nil)
        }
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
    private func verifyNetworkIdentity(_ anIdentity: Data) -> Bool {
        if anIdentity[0] == 0x00 {
            //Network identity advertisement
            let broadcastedNetworkId = Data(anIdentity.dropFirst())
            if broadcastedNetworkId == currentNetworkIdentity {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }

    private func startProxyScanner() {
        centralManager.delegate = self
        centralManager.scanForPeripherals(withServices: [MeshServiceProxyUUID],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        activityIndicator.startAnimating()
    }

    private func showAlertController() {
        alertController = UIAlertController(title: "Connecting", message: "Connecting to proxy...", preferredStyle: .alert)
        self.present(alertController!, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(5)) {
            //No updates in 5 seconds
            if self.alertController != nil && self.alertController?.title == "Connecting" {
                self.alertController?.title = "Timeout"
                self.alertController?.message = "please try again"
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2), execute: {
                    if self.alertController != nil {
                        self.dismiss(animated: true)
                    }
                })
            }
        }
    }

    // MARK: - Table view data source
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "proxyScannerCell", for: indexPath) as? ProxyScannerCell
        cell?.showNode(discoveredNodes[indexPath.row])
        return cell!
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        centralManager.stopScan()
        activityIndicator.stopAnimating()
        showAlertController()
        let aNode = discoveredNodes[indexPath.row]
        targetNode = ProvisionedMeshNode(withUnprovisionedNode: aNode, andDelegate: self)
        centralManager.connect(targetNode.blePeripheral(), options: nil)
    }
}

extension ReconnectionViewController: CBCentralManagerDelegate {
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
        if let serviceDictionary = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Any] {
            if let serviceData = serviceDictionary[MeshServiceProxyUUID] as? Data {
                if verifyNetworkIdentity(serviceData) {
                    //Only update if the network identity matches
                    //
                    if discoveredNodes.contains(tempNode) == false {
                        discoveredNodes.append(tempNode)
                        let addCellPath = IndexPath(item: Int(discoveredNodes.count - 1), section: 0)
                        tableView.insertRows(at: [addCellPath], with: .automatic)
                    } else {
                        if let index = discoveredNodes.index(of: tempNode) {
                            let oldNode = discoveredNodes[index]
                            oldNode.updateRSSI(RSSI)
                            let reloadCellPath = IndexPath(item: Int(index), section: 0)
                            let aCell = tableView.cellForRow(at: reloadCellPath) as? ProxyScannerCell
                            DispatchQueue.main.async {
                                aCell?.showNode(oldNode)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if targetNode.blePeripheral() == peripheral {
            alertController?.title = "Discovering Services"
            alertController?.message = "please wait..."
            targetNode.discover()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if targetNode.blePeripheral() == peripheral {
            activityIndicator.stopAnimating()
            alertController?.title = "Failed to connect"
            if error?.localizedDescription != nil {
                alertController?.message = error!.localizedDescription
            } else {
                alertController?.message = "an unknown error occured."
            }
            let rescanAction = UIAlertAction(title: "Scan again", style: .default) { (_) in
                DispatchQueue.main.async {
                    self.startProxyScanner()
                }
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                }
            }
            alertController?.addAction(rescanAction)
            alertController?.addAction(cancelAction)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard targetNode != nil else {
            return
        }
        if targetNode.blePeripheral() == peripheral {
            activityIndicator.stopAnimating()
            alertController?.title = "Disconnected"
            if error?.localizedDescription != nil {
                alertController?.message = error?.localizedDescription
            } else {
                alertController?.message = "an unknown error occured."
            }
            let rescanAction = UIAlertAction(title: "Scan again", style: .default) { (_) in
                DispatchQueue.main.async {
                    self.startProxyScanner()
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                }
            }
            alertController?.addAction(rescanAction)
            alertController?.addAction(cancelAction)
        }
    }
}

extension ReconnectionViewController: ProvisionedMeshNodeDelegate {
    func receivedGenericOnOffStatusMessage(_ status: GenericOnOffStatusMessage) {
        print("OnOff status = \(status.onOffStatus)")
    }
    
    // MARK: - ProvisionedMeshNodeDelegate
    func nodeDidCompleteDiscovery(_ aNode: ProvisionedMeshNode) {
        centralManager.delegate = originalCentraldelegate
        aNode.delegate = nil
        alertController?.title = "Completed"
        alertController?.message = "discovery completed"
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
            self.dismiss(animated: true)
            self.mainView.reconnectionViewDidSelectNode(aNode)
        }
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
    
    func receivedNodeResetStatus(_ resetStatusData: NodeResetStatusMessage) {
        //NOOP
    }

    func configurationSucceeded() {
        //NOOP
    }
}
