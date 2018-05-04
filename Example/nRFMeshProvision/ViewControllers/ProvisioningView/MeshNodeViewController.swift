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

    @IBOutlet weak var provisioningLogTableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

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

    // Private temprorary Unicast storage between prov/config state
    private var targetNodeUnicast: Data?

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
                                                        friendlyName: provisioningData.friendlyName,
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
            centralManager.cancelPeripheralConnection(aNode.blePeripheral())
        }
    }

    func receivedCompositionData(_ compositionData: CompositionStatusMessage) {
        guard targetProvisionedNode != nil else {
            logEventWithMessage("Received composition data from unknown node, NOOP")
            return
        }
        let state = meshState.state()
        if let anIndex = state.provisionedNodes.index(where: { $0.nodeUnicast == provisioningData.unicastAddr}) {
            let aNodeEntry = state.provisionedNodes[anIndex]
            state.provisionedNodes.remove(at: anIndex)
            aNodeEntry.companyIdentifier = compositionData.companyIdentifier
            aNodeEntry.productVersion = compositionData.productVersion
            aNodeEntry.productIdentifier = compositionData.productIdentifier
            aNodeEntry.featureFlags = compositionData.features
            aNodeEntry.replayProtectionCount = compositionData.replayProtectionCount
            aNodeEntry.elements = compositionData.elements
            //and update
            state.provisionedNodes.append(aNodeEntry)
            logEventWithMessage("Received composition data")
            logEventWithMessage("Company identifier:\(compositionData.companyIdentifier.hexString())")
            logEventWithMessage("Product identifier:\(compositionData.productIdentifier.hexString())")
            logEventWithMessage("Product version:\(compositionData.productVersion.hexString())")
            logEventWithMessage("Feature flags:\(compositionData.features.hexString())")
            logEventWithMessage("Element count:\(compositionData.elements.count)")
            for anElement in aNodeEntry.elements! {
                logEventWithMessage("Element models:\(anElement.totalModelCount())")
            }

            //Set unicast to current set value, to allow the user to force override addresses
            state.nextUnicast = self.provisioningData.unicastAddr
            //Increment next available address
            state.incrementUnicastBy(compositionData.elements.count)
            meshState.saveState()
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
            let state = meshState.state()
            if let anIndex = state.provisionedNodes.index(where: { $0.nodeUnicast == provisioningData.unicastAddr}) {
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
            activityIndicator.stopAnimating()
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

    func receivedDefaultTTLStatus(_ defaultTTLStatusData: DefaultTTLStatusMessage) {
        //NOOP
    }

    func configurationSucceeded() {
        logEventWithMessage("Configuration completed!")
        activityIndicator.stopAnimating()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
            (self.navigationController!.viewControllers[0] as? MainTabBarViewController)?.targetProxyNode = self.targetProvisionedNode
            (self.navigationController!.viewControllers[0] as? MainTabBarViewController)?.switchToNetworkView()
            self.navigationController?.popToRootViewController(animated: true)
        }
    }

    // MARK: - UnprovisionedMeshNodeDelegate
    func nodeShouldDisconnect(_ aNode: UnprovisionedMeshNode) {
        if aNode == targetNode {
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
            activityIndicator.stopAnimating()
            return
        }
        let state = meshState.state()
        if let anIndex = state.provisionedNodes.index(where: { $0.nodeUnicast == nodeEntry?.nodeUnicast}) {
            state.provisionedNodes.remove(at: anIndex)
        }
        nodeEntry?.nodeUnicast = provisioningData.unicastAddr
        //Store target node unicast to verify node identity on upcoming reconnect
        targetNodeUnicast = provisioningData.unicastAddr
        state.provisionedNodes.append(nodeEntry!)
        meshState.saveState()
        targetNode.shouldDisconnect()
        logEventWithMessage("Starting discovery to scan Provisioned Proxy node")
        //Now let's switch to a provisioned node object and start configuration
        targetProvisionedNode = ProvisionedMeshNode(withUnprovisionedNode: aNode, andDelegate: self)
        destinationAddress = provisioningData.unicastAddr
        centralManager.scanForPeripherals(withServices: [MeshServiceProxyUUID], options: nil)
        logEventWithMessage("Started scanning for Proxy...")
    }

    func nodeProvisioningFailed(_ aNode: UnprovisionedMeshNode, withErrorCode anErrorCode: ProvisioningErrorCodes) {
        logProvisioningFailed(withMessage: "provisioning failed, error: \(anErrorCode)")
        activityIndicator.stopAnimating()
    }

    // MARK: - UIView implementation
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logEventWithMessage("target node id: 0x\(targetNode.humanReadableNodeIdentifier())")
        title = targetNode.nodeBLEName()
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

    private func verifyNodeIdentity(_ identityData: Data, withUnicast aUnicast: Data) -> Bool{
        let dataToVerify = Data(identityData.dropFirst())
        let netKey = meshState.state().netKey
        let hash = Data(dataToVerify.dropLast(8))
        let random = Data(dataToVerify.dropFirst(8))
        let helper = OpenSSLHelper()
        let salt = helper.calculateSalt(Data([0x6E, 0x6B, 0x69, 0x6B])) //"nkik" ASCII
        let p =  Data([0x69, 0x64, 0x31, 0x32, 0x38, 0x01]) // id128 || 0x01
        if let identityKey = helper.calculateK1(withN: netKey, salt: salt, andP: p) {
            let padding = Data([0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
            let hashInputs = padding + random + aUnicast
            if let fullHash = helper.calculateEvalue(with: hashInputs, andKey: identityKey) {
            let calculatedHash = fullHash.dropFirst(fullHash.count - 8) //Keep only last 64 bits
                if calculatedHash == hash {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        }
        return false
    }

    // MARK: - CBCentralManagerDelegate
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        //Looking for advertisement data of service 0x1828 with 17 octet length
        //0x01 (Node ID), 8 Octets Hash + 8 Octets Random number
        if let serviceDataDictionary = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data]{
            if let data = serviceDataDictionary[MeshServiceProxyUUID] {
                if data.count == 17 {
                    if data[0] == 0x01 {
                        self.logEventWithMessage("found proxy node with node id: \(data.hexString())")
                        self.logEventWithMessage("verifying NodeID: \(data.hexString())")
                        if targetNodeUnicast != nil {
                            if verifyNodeIdentity(data, withUnicast: targetNodeUnicast!) {
                                logEventWithMessage("node identity verified!")
                                logEventWithMessage("unicast found: \(targetNodeUnicast!.hexString())")
                                central.stopScan()
                                targetProvisionedNode = ProvisionedMeshNode(withUnprovisionedNode: targetNode,
                                                                            andDelegate: self)
                                let currentDelegate = targetNode.blePeripheral().delegate
                                peripheral.delegate = currentDelegate
                                targetNode = nil
                                targetProvisionedNode.overrideBLEPeripheral(peripheral)
                                connectNode(targetProvisionedNode)
                                targetNodeUnicast = nil
                            } else {
                                self.logEventWithMessage("different unicast, skipping node.")
                            }
                        }
                    }
                }
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if targetNode != nil {
            if peripheral == targetNode.blePeripheral() {
                logDisconnect()
            }
        } else if targetProvisionedNode != nil {
            if peripheral == targetProvisionedNode.blePeripheral() {
                logDisconnect()
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
