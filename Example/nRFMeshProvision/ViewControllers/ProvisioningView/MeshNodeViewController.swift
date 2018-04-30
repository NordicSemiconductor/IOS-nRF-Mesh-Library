//
//  MeshNodeViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 18/12/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import CoreBluetooth
import nRFMeshProvision

class MeshNodeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
CBCentralManagerDelegate, UnprovisionedMeshNodeDelegate, UnprovisionedMeshNodeLoggingDelegate,
ProvisionedMeshNodeDelegate, ProvisionedMeshNodeLoggingDelegate {

    @IBOutlet weak var nodeIdentifierLabel: UILabel!
    @IBOutlet weak var provisioningLogTableView: UITableView!

    // MARK: - Class properties
    private var meshState: MeshStateManager!
    private var provisioningData: ProvisioningData!
    private var targetNode: UnprovisionedMeshNode!
    private var centralManager: CBCentralManager!
    private var logEntries: [LogEntry] = [LogEntry]()
    // AppKey Configuration
    private var netKeyIndex: Data!
    private var appKeyIndex: Data!
    private var appKeyData: Data!

    // Provisioned node properties
    var destinationAddress: Data!
    var targetProvisionedNode: ProvisionedMeshNode!

    // MARK: - Implementation
    func handleConfigureButtonTapped() {
        logConfigurationWillStart()
    }

    public func logEventWithMessage(_ aMessage: String) {
        logEntries.append(LogEntry(withMessage: aMessage, andTimestamp: Date()))
        provisioningLogTableView?.reloadData()
        if logEntries.count > 0 {
            //Scroll to bottom of table view when we start getting data
            //(.bottom places the last row to the bottom of tableview)
            provisioningLogTableView?.scrollToRow(at: IndexPath(row: logEntries.count - 1, section: 0),
                                                  at: .bottom, animated: true)
        }
   }

    func showFullLogMessageForItemAtIndexPath(_ anIndexPath: IndexPath) {
        let logEntry = logEntries[anIndexPath.row]
        let formattedTimestamp = DateFormatter.localizedString(from: logEntry.timestamp,
                                                               dateStyle: .none,
                                                               timeStyle: .medium)
        let alertView = UIAlertController(title: formattedTimestamp,
                                          message: logEntry.message,
                                          preferredStyle: UIAlertControllerStyle.alert)
        let copyAction = UIAlertAction(title: "Copy to clipboard", style: .default) { (_) in
            UIPasteboard.general.string = "\(formattedTimestamp): \(logEntry.message)"
            self.dismiss(animated: true, completion: nil)
        }
        let doneAction = UIAlertAction(title: "Done", style: .cancel) { (_) in
            self.dismiss(animated: true, completion: nil)
        }
        alertView.addAction(copyAction)
        alertView.addAction(doneAction)
        self.present(alertView, animated: true, completion: nil)
    }

    public func setMeshStateManager(_ aManager: MeshStateManager) {
        meshState = aManager
    }

    public func setProvisioningData(_ someProvisioningData: ProvisioningData) {
        provisioningData = someProvisioningData
    }

    public func setConfigurationData(withAppKeyData anAppKeyData: Data,
                                     appKeyIndex anAppKeyIndex: Data,
                                     andNetKeyIndex aNetKeyIndex: Data) {
        appKeyIndex = anAppKeyIndex
        appKeyData  = anAppKeyData
        netKeyIndex = aNetKeyIndex
    }

    public func setTargetNode(_ aNode: UnprovisionedMeshNode, andCentralManager aCentralManager: CBCentralManager) {
        targetNode              = aNode
        targetNode.delegate     = self
        targetNode.logDelegate  = self
        centralManager          = aCentralManager
    }

    private func discoveryCompleted() {
        if let provisioningData = provisioningData, meshState != nil {
            logEventWithMessage("provisioning started")
            let meshStateObject = meshState.state()
            let netKeyIndex = meshStateObject.keyIndex
            let packedNetKey = Data([netKeyIndex[0] << 4 | ((netKeyIndex[1] & 0xF0) >> 4), netKeyIndex[1] << 4])
            let nodeProvisioningdata = ProvisioningData(netKey: meshStateObject.netKey,
                                                        keyIndex: packedNetKey,
                                                        flags: meshStateObject.flags,
                                                        ivIndex: meshStateObject.IVIndex,
                                                        unicastAddress: provisioningData.unicastAddr)
            targetNode.provision(withProvisioningData: nodeProvisioningdata)
        } else {
            logEventWithMessage("missing provisioning data")
            print("Provisioning data not present, cannot provision")
        }
   }

    private func connectNode(_ aNode: ProvisionedMeshNode) {
        targetProvisionedNode = aNode
        centralManager.delegate = self
        centralManager.connect(targetProvisionedNode.blePeripheral(), options: nil)
        //targetProvisionedNode.logDelegate?.logConnect()
    }

    private func connectNode(_ aNode: UnprovisionedMeshNode) {
        targetNode = aNode
        centralManager.delegate = self
        centralManager.connect(targetNode.blePeripheral(), options: nil)
        targetNode.logDelegate?.logConnect()
    }

    // MARK: - ProvisionedMeshNodeDelegate
    func nodeDidCompleteDiscovery(_ aNode: ProvisionedMeshNode) {
        print("Provisioned node discovery completed!")
        if aNode == targetProvisionedNode {
            targetProvisionedNode.configure(destinationAddress: destinationAddress,
                                            appKeyIndex: appKeyIndex,
                                            appKeyData: appKeyData,
                                            andNetKeyIndex: netKeyIndex)
        }
    }

    func nodeShouldDisconnect(_ aNode: ProvisionedMeshNode) {
        if aNode == targetProvisionedNode {
//            targetProvisionedNode.logDelegate?.logDisconnect()
            centralManager.cancelPeripheralConnection(aNode.blePeripheral())
        }
    }

    func receivedCompositionData(_ compositionData: CompositionStatusMessage) {
        guard targetProvisionedNode != nil else {
            logEventWithMessage("Received composition data from unknown node, NOOP")
            return
        }
        let nodeIdentifier = targetProvisionedNode.nodeIdentifier()
        let state = meshState.state()
        if let anIndex = state.provisionedNodes.index(where: { $0.nodeId == nodeIdentifier}) {
            let aNodeEntry = state.provisionedNodes[anIndex]
            state.provisionedNodes.remove(at: anIndex)
            aNodeEntry.companyIdentifier = compositionData.companyIdentifier
            aNodeEntry.vendorIdentifier = compositionData.vendorIdentifier
            aNodeEntry.productIdentifier = compositionData.productIdentifier
            aNodeEntry.featureFlags = compositionData.features
            aNodeEntry.replayProtectionCount = compositionData.replayProtectionCount
            aNodeEntry.elements = compositionData.elements
            //and update
            state.provisionedNodes.append(aNodeEntry)
            meshState.saveState()
            logEventWithMessage("Received composition data")
            logEventWithMessage("Company identifier:\(compositionData.companyIdentifier.hexString())")
            logEventWithMessage("Vendor identifier:\(compositionData.vendorIdentifier.hexString())")
            logEventWithMessage("Product identifier:\(compositionData.productIdentifier.hexString())")
            logEventWithMessage("Feature flags:\(compositionData.features.hexString())")
            logEventWithMessage("Element count:\(compositionData.elements.count)")
            for anElement in aNodeEntry.elements! {
                logEventWithMessage("Element models:\(anElement.totalModelCount())")
            }
        } else {
            logEventWithMessage("Received composition data but node isn't stored, please provision again")
        }
    }

    func receivedAppKeyStatusData(_ appKeyStatusData: AppKeyStatusMessage) {
        logEventWithMessage("Received app key status messasge")
        if appKeyStatusData.statusCode == .success {
            logEventWithMessage("Status code: Success")
            logEventWithMessage("Appkey index: \(appKeyStatusData.appKeyIndex.hexString())")
            logEventWithMessage("netKey index: \(appKeyStatusData.netKeyIndex.hexString())")

            // Update state with configured key
            let nodeIdentifier = targetProvisionedNode.nodeIdentifier()
            let state = meshState.state()
            if let anIndex = state.provisionedNodes.index(where: { $0.nodeId == nodeIdentifier}) {
                let aNodeEntry = state.provisionedNodes[anIndex]
                state.provisionedNodes.remove(at: anIndex)
                if aNodeEntry.appKeys.contains(appKeyStatusData.appKeyIndex) == false {
                    aNodeEntry.appKeys.append(appKeyStatusData.appKeyIndex)
                }
                //and update
                state.provisionedNodes.append(aNodeEntry)
                meshState.saveState()
                for aKey in aNodeEntry.appKeys {
                    logEventWithMessage("AppKeyData:\(aKey.hexString())")
                }
            }
        } else {
            logEventWithMessage("Status: Failed, code: \(appKeyStatusData.statusCode)")
        }
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

    func configurationSucceeded() {
        logEventWithMessage("Configuration completed!")
        (self.navigationController!.viewControllers[0] as? MainTabBarViewController)?.targetProxyNode = targetProvisionedNode
        self.navigationController?.popToRootViewController(animated: true)
    }

    // MARK: - UnprovisionedMeshNodeDelegate
    func nodeShouldDisconnect(_ aNode: UnprovisionedMeshNode) {
        if aNode == targetNode {
            targetNode.logDelegate?.logDisconnect()
            centralManager.cancelPeripheralConnection(aNode.blePeripheral())
        }
   }

    func nodeRequiresUserInput(_ aNode: UnprovisionedMeshNode,
                               completionHandler aHandler: @escaping (String) -> Void) {
        let alertView = UIAlertController(title: "Device request",
                                          message: "please enter confirmation code",
                                          preferredStyle: UIAlertControllerStyle.alert)
        var textField: UITextField?
        alertView.addTextField { (aTextField) in
            aTextField.placeholder = "1234"
            aTextField.keyboardType = .decimalPad
            textField = aTextField
        }
   let okAction = UIAlertAction(title: "Ok", style: .default) { (_) in
            aHandler((textField?.text)!)
            self.dismiss(animated: true, completion: nil)
        }
   let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            self.logEventWithMessage("user input cancelled")
            self.dismiss(animated: true, completion: nil)
        }
   alertView.addAction(okAction)
        alertView.addAction(cancelAction)
        self.present(alertView, animated: true, completion: nil)
    }

    func nodeDidCompleteDiscovery(_ aNode: UnprovisionedMeshNode) {
        if aNode == targetNode {
            discoveryCompleted()
        } else {
            print("Other node completed discovery")
        }
   }

    func nodeProvisioningCompleted(_ aNode: UnprovisionedMeshNode) {
        logProvisioningSucceeded()
        //Store provisioning node data now
        let nodeEntry = aNode.getNodeEntryData()
        guard nodeEntry != nil else {
            print("Failed to get node entry data")
            return
        }
        let state = meshState.state()
        if let anIndex = state.provisionedNodes.index(where: { $0.nodeId == aNode.nodeIdentifier()}) {
            state.provisionedNodes.remove(at: anIndex)
        }
        nodeEntry?.nodeUnicast = provisioningData.unicastAddr
        state.provisionedNodes.append(nodeEntry!)
        meshState.saveState()
        logEventWithMessage("Starting discovery to scan Provisioned Proxy node")
        targetNode.shouldDisconnect()
        //Now let's switch to a provisioned node object and start configuration
        targetProvisionedNode = ProvisionedMeshNode(withUnprovisionedNode: aNode, andDelegate: self)
//        targetNode = nil
        destinationAddress = provisioningData.unicastAddr
        centralManager.scanForPeripherals(withServices: [MeshServiceProxyUUID], options: nil)
        logEventWithMessage("Scan started")
    }

    func nodeProvisioningFailed(_ aNode: UnprovisionedMeshNode, withErrorCode anErrorCode: ProvisioningErrorCodes) {
        logProvisioningFailed(withMessage: "provisioning failed, error: \(anErrorCode)")
    }

    // MARK: - UIView implementation
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logEventWithMessage("target node id: 0x\(targetNode.humanReadableNodeIdentifier())")
        title = targetNode.nodeBLEName()
        nodeIdentifierLabel.text = "0x\(targetNode.humanReadableNodeIdentifier())"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        connectNode(targetNode)
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logEntries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCell(withIdentifier: "LogEntryCell", for: indexPath)
        let logEntry = logEntries[indexPath.row]
        if let aCell = aCell as? MeshNodeLogTableViewCell {
            aCell.setLogMessage(logEntry.message, withTimestamp: logEntry.timestamp)
        }
        return aCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.showFullLogMessageForItemAtIndexPath(indexPath)
    }

    // MARK: - CBCentralManagerDelegate
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        logEventWithMessage("Proxy Node discovered")
        if peripheral.name == targetNode.blePeripheral().name {
            logEventWithMessage("Proxy Node is the target node, will connect.")
            central.stopScan()
            targetProvisionedNode = ProvisionedMeshNode(withUnprovisionedNode: targetNode,
                                                        andDelegate: self)
            let currentDelegate = targetNode.blePeripheral().delegate
            peripheral.delegate = currentDelegate
            targetNode = nil
            targetProvisionedNode.overrideBLEPeripheral(peripheral)
            connectNode(targetProvisionedNode)
        } else {
            logEventWithMessage("Proxy Node is not the target node, NOOP.")
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if targetNode != nil {
            if peripheral == targetNode.blePeripheral() {
                logEventWithMessage("Node disconnected")
            }
        } else if targetProvisionedNode != nil {
            if peripheral == targetProvisionedNode.blePeripheral() {
                logEventWithMessage("Provisioned node disconnected")
            }
        }
   }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if targetNode != nil {
            logEventWithMessage("Unprovisioned node connected, discover.")
            targetNode.discover()
        } else if targetProvisionedNode != nil {
            logEventWithMessage("Provisioned proxy node connected, start discovery")
            targetProvisionedNode.discover()
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            if targetNode != nil {
                connectNode(targetNode)
            }
            if targetProvisionedNode != nil {
                connectNode(targetProvisionedNode)
            }
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }

    // MARK: - UnprovisionedMeshNodeLoggingDelegate
    func logDisconnect() {
        logEventWithMessage("disconnected")
    }

    func logConnect() {
        logEventWithMessage("connected")
    }

    func logDiscoveryStarted() {
        logEventWithMessage("started discovery")
    }

    func logDiscoveryCompleted() {
        logEventWithMessage("discovery completed")
    }

    func logSwitchedToProvisioningState(withMessage aMessage: String) {
        logEventWithMessage("switched provisioning state: \(aMessage)")
    }

    func logUserInputRequired() {
        logEventWithMessage("user input required")
    }

    func logUserInputCompleted(withMessage aMessage: String) {
        logEventWithMessage("input complete: \(aMessage)")
    }

    func logGenerateKeypair(withMessage aMessage: String) {
        logEventWithMessage("keypare generated, pubkey: \(aMessage)")
    }

    func logCalculatedECDH(withMessage aMessage: String) {
        logEventWithMessage("calculated DHKey: \(aMessage)")
    }

    func logGeneratedProvisionerRandom(withMessage aMessage: String) {
        logEventWithMessage("provisioner random: \(aMessage)")
    }

    func logReceivedDeviceRandom(withMessage aMessage: String) {
        logEventWithMessage("device random: \(aMessage)")
    }

    func logGeneratedProvisionerConfirmationValue(withMessage aMessage: String) {
        logEventWithMessage("provisioner confirmation: \(aMessage)")
    }

    func logReceivedDeviceConfirmationValue(withMessage aMessage: String) {
        logEventWithMessage("device confirmation: \(aMessage)")
    }

    func logGenratedProvisionInviteData(withMessage aMessage: String) {
        logEventWithMessage("provision invite data: \(aMessage)")
    }

    func logGeneratedProvisioningStartData(withMessage aMessage: String) {
        logEventWithMessage("provision start data: \(aMessage)")
    }

    func logReceivedCapabilitiesData(withMessage aMessage: String) {
        logEventWithMessage("capabilities : \(aMessage)")
    }

    func logReceivedDevicePublicKey(withMessage aMessage: String) {
        logEventWithMessage("device public key: \(aMessage)")
    }

    func logProvisioningSucceeded() {
        logEventWithMessage("provisioning succeeded")
    }

    func logProvisioningFailed(withMessage aMessage: String) {
        logEventWithMessage("provisioning failed: \(aMessage)")
    }

    func logConfigurationWillStart() {
        logEventWithMessage("Starting node configuration")
    }
}
