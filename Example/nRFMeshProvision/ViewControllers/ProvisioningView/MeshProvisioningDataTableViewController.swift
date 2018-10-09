//
//  MeshConfigurationTableViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 16/01/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision
import CoreBluetooth

enum provisioningViewSteps {
    case none
    case invite
    case provisioning
}

class MeshProvisioningDataTableViewController: UITableViewController, UITextFieldDelegate {

    // MARK: - Outlets and Actions
    @IBOutlet weak var provisionButton: UIBarButtonItem!
    @IBOutlet weak var abortButton: UIBarButtonItem!
    @IBOutlet weak var viewLogButton: UIButton!
    @IBOutlet weak var provisioningProgressIndicator: UIProgressView!
    @IBOutlet weak var provisioningProgressLabel: UILabel!
    @IBOutlet weak var provisioningProgressTitleLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var provisioningProgressCell: UITableViewCell!
    @IBOutlet weak var nodeNameCell: UITableViewCell!
    @IBOutlet weak var unicastAddressCell: UITableViewCell!
    @IBOutlet weak var appKeyCell: UITableViewCell!
    
    // Identification outlets
    @IBOutlet weak var elementCountSubtitle: UILabel!
    @IBOutlet weak var algorithmSubtitle: UILabel!
    @IBOutlet weak var publicKeyTypeSubtitle: UILabel!
    @IBOutlet weak var staticOOBTypeSubtitle: UILabel!
    @IBOutlet weak var supportedOutputActionsSubtitle: UILabel!
    @IBOutlet weak var outputOOBSizeSubtitle: UILabel!
    @IBOutlet weak var supportedInputActionsSubtitle: UILabel!
    @IBOutlet weak var inputOOBSizeSubtitle: UILabel!
    
    @IBAction func provisionButtonTapped(_ sender: Any) {
        handleProvisioningButtonTapped()
    }
    @IBAction func abortButtonTapped(_ sender: Any) {
        handleAbortButtonTapped()
    }
    
    // MARK: - Properties
    private var logViewController: ProvisioningLogTableViewController?
    private var provisioningState: provisioningViewSteps = .none
    private var totalSteps: Float = 24
    private var completedSteps: Float = 0
    private var targetNode: UnprovisionedMeshNode!
    private var logEntries: [LogEntry] = [LogEntry]()
    private var meshManager: NRFMeshManager!
    private var stateManager: MeshStateManager!
    private var centralManager: CBCentralManager!
    
    // AppKey Configuration
    private var netKeyIndex: Data!
    private var appKeyIndex: Data!
    private var appKeyData: Data!
    
    // Private temprorary Unicast storage between prov/config state
    private var targetNodeUnicast: Data?
    
    // Provisioned node properties
    var destinationAddress: Data!
    var targetProvisionedNode: ProvisionedMeshNode!

    var nodeName: String! = "Mesh Node"
    var nodeAddress: Data!
    var appKeyName: String!
    let freetextTag = 1 //Text fields tagged with this value will allow any input type
    let hexTextTag  = 2 //Text fields tagget with this value will only allow Hex input

    // MARK: - UIViewController implementation
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logViewController = nil
        if appKeyName == nil {
            updateProvisioningDataUI()
        }
        viewLogButton.isEnabled = logEntries.count > 0
        abortButton.isEnabled   = false
        abortButton.title       = nil
        provisionButton.title   = "Identify"
    }

    // MARK: - Implementaiton
    private func updateProvisioningDataUI() {
        if nodeName == "Mesh Node" {
            nodeName = targetNode.nodeBLEName()
        }
        let nextUnicast = meshManager.stateManager().state().nextUnicast
        //Set the unicast according to the state
        nodeAddress = nextUnicast
        //Update provisioning Data UI with default values
        unicastAddressCell.detailTextLabel?.text = "0x\(nodeAddress.hexString())"
        nodeNameCell.detailTextLabel?.text = nodeName
        //Select first key by default
        didSelectAppKeyWithIndex(0)
    }

    public func setTargetNode(_ aNode: UnprovisionedMeshNode) {
        if let aManager = (UIApplication.shared.delegate as? AppDelegate)?.meshManager {
            meshManager     = aManager
            targetNode      = aNode
            targetNode.delegate     = self
            targetNode.logDelegate  = self as UnprovisionedMeshNodeLoggingDelegate
            stateManager            = meshManager.stateManager()
            centralManager          = meshManager.centralManager()
        }
    }

    func handleAbortButtonTapped() {
        if provisioningState != .none {
            provisioningState = .none
            provisionButton.isEnabled = true
            provisionButton.title = "Identify"
            navigationItem.hidesBackButton = false
            abortButton.isEnabled = false
            abortButton.title = nil

            if targetNode != nil {
                targetNode.shouldDisconnect()
            }
            if targetProvisionedNode != nil {
                targetProvisionedNode.shouldDisconnect()
            }
            if centralManager.isScanning {
                centralManager.stopScan()
            }
        }
    }
    func handleProvisioningButtonTapped() {
        if provisioningState == .none {
            provisionButton.isEnabled = false
            provisionButton.title = "Identifying"
            navigationItem.hidesBackButton = true
            provisioningState = .invite
            connectNode(targetNode)
            abortButton.isEnabled = false
            abortButton.title = nil
        } else if provisioningState == .invite {
            provisioningState = .provisioning
            provisionButton.title = nil
            navigationItem.hidesBackButton = true
            if targetNode.blePeripheral().state != .connected {
                connectNode(targetNode)
            } else {
                provisionNode(targetNode)
            }
            abortButton.isEnabled = true
            abortButton.title = "Abort"
        }
        
        if tableView.numberOfSections == 1 {
            tableView.insertSections([1], with: .fade)
            tableView.scrollToRow(at: IndexPath(row: 7, section: 1), at: UITableViewScrollPosition.bottom, animated: true)
            resetSubtitleLabels()
        } else if tableView.numberOfSections == 2 {
            tableView.insertSections([2], with: .fade)
            tableView.scrollToRow(at: IndexPath(row: 0, section: 2), at: UITableViewScrollPosition.bottom, animated: true)
        }
    }

    func didSelectUnicastAddressCell() {
        let unicast = meshManager.stateManager().state().unicastAddress
        presentInputViewWithTitle("Please enter Unicast Address",
                                  message: "2 Bytes, > 0x0000",
                                  inputType: hexTextTag,
                                  placeholder: self.nodeAddress.hexString()) { (anAddress) -> Void in
                                    if var anAddress = anAddress {
                                        anAddress = anAddress.lowercased().replacingOccurrences(of: "0x", with: "")
                                        if anAddress.count == 4 {
                                            if anAddress == "0000" ||
                                                anAddress == String(data: unicast,
                                                                    encoding: .utf8) {
                                                print("Adderss cannot be 0x0000, minimum possible address is 0x0001")
                                            } else {
                                                self.nodeAddress = Data(hexString: anAddress)
                                                let readableName = "0x\(self.nodeAddress.hexString())"
                                                self.unicastAddressCell.detailTextLabel?.text = readableName
                                            }
                                        } else {
                                            print("Unicast address must be exactly 2 bytes")
                                        }
                                    }
        }
    }

    func didSelectNodeNameCell() {
        presentInputViewWithTitle("Name this node",
                                  message: "Name must be one or more characters",
                                  inputType: freetextTag,
                                  placeholder: "\(self.targetNode.nodeBLEName())") { (aName) -> Void in
                                    if let aName = aName {
                                        if aName.count > 0 {
                                            self.nodeName = aName
                                            self.nodeNameCell.detailTextLabel?.text = aName
                                        } else {
                                            print("Name must be longer 1 or more characters")
                                        }
                                    }
        }
    }

    func didSelectAppkeyCell() {
        self.performSegue(withIdentifier: "showAppKeySelector", sender: nil)
    }

    func didSelectAppKeyWithIndex(_ anIndex: Int) {
        let meshState = meshManager.stateManager().state()
        netKeyIndex = meshState.keyIndex
        let appKey = meshState.appKeys[anIndex]
        appKeyName = appKey.keys.first
        appKeyData = appKey.values.first
        let anAppKeyIndex = UInt16(anIndex)
        appKeyIndex = Data([UInt8((anAppKeyIndex & 0xFF00) >> 8), UInt8(anAppKeyIndex & 0x00FF)])
        appKeyCell.textLabel?.text = appKeyName
        appKeyCell.detailTextLabel?.text = "0x\(appKeyData!.hexString())"
    }

    // MARK: - Input Alert
    func presentInputViewWithTitle(_ aTitle: String,
                                   message aMessage: String,
                                   inputType: Int,
                                   placeholder aPlaceholder: String?,
                                   andCompletionHandler aHandler : @escaping (String?) -> Void) {
        let inputAlertView = UIAlertController(title: aTitle, message: aMessage, preferredStyle: .alert)
        inputAlertView.addTextField { (aTextField) in
            aTextField.keyboardType = UIKeyboardType.asciiCapable
            aTextField.returnKeyType = .done
            aTextField.delegate = self
            aTextField.tag = inputType
            //Show clear button button when user is not editing
            aTextField.clearButtonMode = UITextFieldViewMode.whileEditing
            if let aPlaceholder = aPlaceholder {
                aTextField.text = aPlaceholder
            }
        }

        let saveAction = UIAlertAction(title: "Save", style: .default) { (_) in
            DispatchQueue.main.async {
                if let text = inputAlertView.textFields![0].text {
                    if text.count > 0 {
                        if inputType == self.hexTextTag {
                            aHandler(text.uppercased())
                        } else {
                            aHandler(text)
                        }
                    }
                }
            }
        }

        let cancelACtion = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            DispatchQueue.main.async {
                aHandler(nil)
            }
        }

        inputAlertView.addAction(saveAction)
        inputAlertView.addAction(cancelACtion)
        present(inputAlertView, animated: true, completion: nil)
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if textField.tag == freetextTag {
            return true
        } else if textField.tag == hexTextTag {
            if range.length > 0 {
                //Going backwards, always allow deletion
                return true
            } else {
                let value = string.data(using: .utf8)![0]
                //Only allow HexaDecimal values 0->9, a->f and A->F or x
                return (value == 120 || value >= 48 && value <= 57) || (value >= 65 && value <= 70) || (value >= 97 && value <= 102)
            }
        } else {
            return true
        }
   }

    // MARK: - Table view delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        switch provisioningState {
            case .none:
                return 1
            case .invite:
                return 2
            case .provisioning:
                return 3
        }
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        //Only first section is selectable when not provisioning
        return provisioningState == .none && indexPath.section == 0
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard indexPath.section == 0 else {
            return
        }

        switch indexPath.row {
        case 0:
            didSelectNodeNameCell()
        case 1:
            didSelectUnicastAddressCell()
        case 2:
            didSelectAppkeyCell()
        default:
            break
        }
    }

    // MARK: - Segue and flow
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return ["showAppKeySelector", "showLogView"].contains(identifier)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showLogView" {
            if let destinationView = segue.destination as? ProvisioningLogTableViewController {
                self.logViewController = destinationView
                destinationView.initialLogEntries(entries: logEntries)
            }
        }
        if segue.identifier == "showAppKeySelector" {
            if let destinationView = segue.destination as? AppKeySelectorTableViewController {
                destinationView.setSelectionCallback({ (appKeyIndex) in
                    guard appKeyIndex != nil else {
                        return
                    }
                    self.didSelectAppKeyWithIndex(appKeyIndex!)
                }, andMeshStateManager: meshManager.stateManager())
            }
        }
    }
}

extension MeshProvisioningDataTableViewController {
    
    // MARK: - Progress handling
    func stepCompleted(withIndicatorState activityEnabled: Bool) {
        DispatchQueue.main.async {
            activityEnabled ? self.activityIndicator.startAnimating() : self.activityIndicator.stopAnimating()
            self.completedSteps += 1.0
            if self.completedSteps >= self.totalSteps {
                self.provisioningProgressLabel.text = "100 %"
                self.provisioningProgressTitleLabel.text = "Progress"
                self.provisioningProgressIndicator.setProgress(1, animated: true)
            } else {
                let completion = self.completedSteps / self.totalSteps * 100.0
                self.provisioningProgressLabel.text = "\(Int(completion)) %"
                self.provisioningProgressIndicator.setProgress(completion / 100.0, animated: true)
            }
        }
    }
    
    // MARK: - Logging
    public func logEventWithMessage(_ aMessage: String) {
        logEntries.append(LogEntry(withMessage: aMessage, andTimestamp: Date()))
        if logEntries.count > 0 {
            viewLogButton.isEnabled = true
        }
        logViewController?.logEntriesDidUpdate(newEntries: logEntries)
    }

    // MARK: - Provisioning and Configuration
    private func verifyNodeIdentity(_ identityData: Data, withUnicast aUnicast: Data) -> Bool{
        let dataToVerify = Data(identityData.dropFirst())
        let netKey = stateManager.state().netKey
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

    private func discoveryCompleted() {
        logEventWithMessage("discovery completed")
        switch provisioningState {
        case .none:
            break
        case .invite:
            identifyNode(targetNode)
        case .provisioning:
            self.provisionNode(targetNode)
        }
    }

    private func identifyNode(_ aNode: UnprovisionedMeshNode) {
        aNode.identifyWithDuration(5)
    }

    private func resetSubtitleLabels() {
        supportedOutputActionsSubtitle.text = "Loading..."
        supportedInputActionsSubtitle.text = "Loading..."
        algorithmSubtitle.text = "Loading..."
        inputOOBSizeSubtitle.text = "Loading..."
        elementCountSubtitle.text = "Loading..."
        publicKeyTypeSubtitle.text = "Loading..."
        staticOOBTypeSubtitle.text = "Loading..."
        outputOOBSizeSubtitle.text = "Loading..."
    }

    private func provisionNode(_ aNode: UnprovisionedMeshNode) {
        let meshStateObject = stateManager.state()
        let netKeyIndex = meshStateObject.keyIndex
        
        //Pack the Network Key
        let netKeyOctet1 = netKeyIndex[0] << 4
        var netKeyOctet2 =  netKeyIndex[1] & 0xF0
        netKeyOctet2 = netKeyOctet2 >> 4
        let firstOctet = netKeyOctet1 | netKeyOctet2
        let secondOctet = netKeyIndex[1] << 4
        let packedNetKey = Data([firstOctet, secondOctet])
        
        let nodeProvisioningdata = ProvisioningData(netKey: meshStateObject.netKey,
                                                    keyIndex: packedNetKey,
                                                    flags: meshStateObject.flags,
                                                    ivIndex: meshStateObject.IVIndex,
                                                    friendlyName: nodeName,
                                                    unicastAddress: self.nodeAddress)
        targetNode.provision(withProvisioningData: nodeProvisioningdata)
        stepCompleted(withIndicatorState: false)
    }

    private func connectNode(_ aNode: ProvisionedMeshNode) {
        targetProvisionedNode = aNode
        centralManager.delegate = self
        centralManager.connect(targetProvisionedNode.blePeripheral(), options: nil)
    }
    
    private func connectNode(_ aNode: UnprovisionedMeshNode) {
        targetNode = aNode
        centralManager.delegate = self
        centralManager.connect(targetNode.blePeripheral(), options: nil)
        targetNode.logDelegate?.logConnect()
    }
}

extension MeshProvisioningDataTableViewController: CBCentralManagerDelegate {
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
                                stepCompleted(withIndicatorState: true)
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
                                self.logEventWithMessage("unexpected unicast, skipping node.")
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
            logEventWithMessage("unprovisioned node connected")
            logEventWithMessage("starting service discovery")
            targetNode.discover()
        } else if targetProvisionedNode != nil {
            logEventWithMessage("provisioned proxy node connected")
            logEventWithMessage("starting service discovery")
            stepCompleted(withIndicatorState: true)
            targetProvisionedNode.discover()
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            if targetNode != nil {
                connectNode(targetNode)
            }
            if targetProvisionedNode != nil {
                stepCompleted(withIndicatorState: true)
                connectNode(targetProvisionedNode)
            }
        } else {
            logEventWithMessage("central manager not available")
        }
    }
}

extension MeshProvisioningDataTableViewController: UnprovisionedMeshNodeDelegate {
    func nodeCompletedProvisioningInvitation(_ aNode: UnprovisionedMeshNode, withCapabilities capabilities: InviteCapabilities) {
        print("Received intitation capabilities")
        navigationItem.hidesBackButton = false
        elementCountSubtitle.text = "\(capabilities.elementCount)"
        outputOOBSizeSubtitle.text = "\(capabilities.outputOOBSize)"
        inputOOBSizeSubtitle.text = "\(capabilities.inputOOBSize)"
        
        switch capabilities.algorithm {
            case .fipsp256EllipticCurve:
                algorithmSubtitle.text = "FIPS-256 Elliptic curve"
            case .none:
                algorithmSubtitle.text = "None"
        }
        
        switch capabilities.publicKeyAvailability {
            case .publicKeyInformationAvailable:
                publicKeyTypeSubtitle.text = "Public Key information available"
            case .publicKeyInformationUnavailable:
                publicKeyTypeSubtitle.text = "Public Key information unavailable"
        }
        
        switch capabilities.staticOOBAvailability {
            case .staticOutOfBoundInformationAvailable:
                staticOOBTypeSubtitle.text = "Static OOB information available"
            case .staticOutOfBoundInformationUnavailable:
                staticOOBTypeSubtitle.text = "Static OOB information unavailable"
        }
        
        let outputActions = capabilities.supportedOutputOOBActions.compactMap { (action) -> String? in
            return action.description()
            }.joined(separator: ", ")
        
        let inputActions = capabilities.supportedInputOOBActions.compactMap { (action) -> String? in
            return action.description()
            }.joined(separator: ", ")
        
        if outputActions.count == 0 {
            supportedOutputActionsSubtitle.text = "Not supported"
        } else {
            supportedOutputActionsSubtitle.text  = outputActions
        }
        if inputActions.count == 0 {
            supportedInputActionsSubtitle.text = "Not supported"
        } else {
            supportedInputActionsSubtitle.text = inputActions
        }

        provisionButton.isEnabled = true
        provisionButton.title = "Provision"
    }

    func nodeShouldDisconnect(_ aNode: UnprovisionedMeshNode) {
        if aNode == targetNode {
            centralManager.cancelPeripheralConnection(aNode.blePeripheral())
        }
    }

    func nodeRequiresUserInput(_ aNode: UnprovisionedMeshNode, outputAction: OutputOutOfBoundActions, length: UInt8, completionHandler aHandler: @escaping (String) -> (Void)) {
        var titleString: String?
        switch outputAction {
            case .beep:
                titleString = "Please enter number of beeps"
            case .blink:
                titleString = "Please enter number of blinks"
            case .outputNumeric:
                titleString = "please enter the numeric code"
            case .outputAlphaNumeric:
                titleString = "Please enter the alphanumeric code"
            default:
                titleString = "Please enter the confirmation code"
        }

        let alertView = UIAlertController(title: "Device request",
                                          message: titleString!,
                                          preferredStyle: UIAlertControllerStyle.alert)
        var textField: UITextField?
        alertView.addTextField { (aTextField) in
            if outputAction == .outputAlphaNumeric {
                aTextField.placeholder = "ABC123"
                aTextField.keyboardType = .asciiCapable
            } else {
                aTextField.placeholder = "1234"
                aTextField.keyboardType = .decimalPad
            }
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
            logEventWithMessage("unknown node completed discovery")
        }
    }
    
    func nodeProvisioningCompleted(_ aNode: UnprovisionedMeshNode) {
        stepCompleted(withIndicatorState: true)
        logEventWithMessage("Provisioning succeeded")
        //Store provisioning node data now
        let nodeEntry = aNode.getNodeEntryData()
        guard nodeEntry != nil else {
            logEventWithMessage("failed to get node entry data")
            activityIndicator.stopAnimating()
            provisioningState = .none
            navigationItem.hidesBackButton = false
            provisionButton.isEnabled = true
            provisionButton.title = "Identify"
            abortButton.isEnabled = false
            abortButton.title = nil
            return
        }
        let state = stateManager.state()
        if let anIndex = state.provisionedNodes.index(where: { $0.nodeUnicast == nodeEntry?.nodeUnicast}) {
            state.provisionedNodes.remove(at: anIndex)
        }
        nodeEntry?.nodeUnicast = self.nodeAddress
        //Store target node unicast to verify node identity on upcoming reconnect
        targetNodeUnicast = self.nodeAddress
        state.provisionedNodes.append(nodeEntry!)
        stateManager.saveState()
        targetNode.shouldDisconnect()
        stepCompleted(withIndicatorState: true)
        //Now let's switch to a provisioned node object and start configuration
        targetProvisionedNode = ProvisionedMeshNode(withUnprovisionedNode: aNode, andDelegate: self)
        destinationAddress = self.nodeAddress
        centralManager.scanForPeripherals(withServices: [MeshServiceProxyUUID], options: nil)
        logEventWithMessage("scanning for provisioned proxy nodes")
    }
    
    func nodeProvisioningFailed(_ aNode: UnprovisionedMeshNode, withErrorCode anErrorCode: ProvisioningErrorCodes) {
        stepCompleted(withIndicatorState: false)
        logEventWithMessage("provisioning failed, error: \(anErrorCode)")
        provisioningState = .none
        navigationItem.hidesBackButton = false
        provisionButton.isEnabled = true
        provisionButton.title = "Identify"
        abortButton.isEnabled = false
        abortButton.title = nil
    }
}

extension MeshProvisioningDataTableViewController: ProvisionedMeshNodeDelegate {
    func receivedGenericLevelStatusMessage(_ status: GenericLevelStatusMessage) {
        print("Level status = \(status.levelStatus)")
    }
    
    func receivedGenericOnOffStatusMessage(_ status: GenericOnOffStatusMessage) {
        print("OnOff status = \(status.onOffStatus)")
    }

    func configurationSucceeded() {
        stepCompleted(withIndicatorState: false)
        provisioningState = .none
        navigationItem.hidesBackButton = false
        provisionButton.isEnabled = false
        provisionButton.title = nil
        abortButton.isEnabled = false
        abortButton.title = nil
        logEventWithMessage("Configuration completed!")
        meshManager.updateProxyNode(self.targetProvisionedNode)
        (UIApplication.shared.delegate as? AppDelegate)?.meshManager = meshManager
        (self.navigationController!.viewControllers[0] as? MainTabBarViewController)?.switchToNetworkView()
        if self.logViewController == nil {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }

    func nodeDidCompleteDiscovery(_ aNode: ProvisionedMeshNode) {
        if aNode == targetProvisionedNode {
            stepCompleted(withIndicatorState: false)
            targetProvisionedNode.configure(destinationAddress: destinationAddress)
        }
    }

    func nodeShouldDisconnect(_ aNode: ProvisionedMeshNode) {
        if aNode == targetProvisionedNode {
            centralManager.cancelPeripheralConnection(aNode.blePeripheral())
        }
    }
    
    func receivedCompositionData(_ compositionData: CompositionStatusMessage) {
        guard targetProvisionedNode != nil else {
            logEventWithMessage("received composition data from unknown node, ignoring")
            return
        }
        stepCompleted(withIndicatorState: false)
        logEventWithMessage("received composition data")
        logEventWithMessage("company identifier:\(compositionData.companyIdentifier.hexString())")
        logEventWithMessage("product identifier:\(compositionData.productIdentifier.hexString())")
        logEventWithMessage("product version:\(compositionData.productVersion.hexString())")
        logEventWithMessage("feature flags:\(compositionData.features.hexString())")
        logEventWithMessage("element count:\(compositionData.elements.count)")
        //Jump to app Key add state
        targetProvisionedNode.appKeyAdd(appKeyData, atIndex: appKeyIndex, forNetKeyAtIndex: netKeyIndex, onDestinationAddress: nodeAddress)
    }
    
    func receivedAppKeyStatusData(_ appKeyStatusData: AppKeyStatusMessage) {
        stepCompleted(withIndicatorState: false)
        logEventWithMessage("received app key status messasge")
        if appKeyStatusData.statusCode == .success {
            logEventWithMessage("status code: Success")
            logEventWithMessage("appkey index: \(appKeyStatusData.appKeyIndex.hexString())")
            logEventWithMessage("netKey index: \(appKeyStatusData.netKeyIndex.hexString())")
            
            // Update state with configured key
            configurationSucceeded()
        } else {
            logEventWithMessage("Received error code: \(appKeyStatusData.statusCode)")
            activityIndicator.stopAnimating()
        }
    }
    
    func receivedModelAppStatus(_ modelAppStatusData: ModelAppStatusMessage) {}
    func receivedModelPublicationStatus(_ modelPublicationStatusData: ModelPublicationStatusMessage) {}
    func receivedModelSubsrciptionStatus(_ modelSubscriptionStatusData: ModelSubscriptionStatusMessage) {}
    func receivedDefaultTTLStatus(_ defaultTTLStatusData: DefaultTTLStatusMessage) {}
    func receivedNodeResetStatus(_ resetStatusData: NodeResetStatusMessage) {}
}

extension MeshProvisioningDataTableViewController: ProvisionedMeshNodeLoggingDelegate {

}

extension MeshProvisioningDataTableViewController: UnprovisionedMeshNodeLoggingDelegate {
    func logDisconnect() {
        stepCompleted(withIndicatorState: false)
        logEventWithMessage("disconnected")
    }
    
    func logConnect() {
        stepCompleted(withIndicatorState: true)
        logEventWithMessage("connected")
    }
    
    func logDiscoveryStarted() {
        stepCompleted(withIndicatorState: true)
        logEventWithMessage("started discovery")
    }
    
    func logDiscoveryCompleted() {
        stepCompleted(withIndicatorState: false)
        logEventWithMessage("discovery completed")
    }
    
    func logSwitchedToProvisioningState(withMessage aMessage: String) {
        logEventWithMessage("switched provisioning state: \(aMessage)")
    }
    
    func logUserInputRequired() {
        stepCompleted(withIndicatorState: true)
        logEventWithMessage("user input required")
    }
    
    func logUserInputCompleted(withMessage aMessage: String) {
        stepCompleted(withIndicatorState: false)
        logEventWithMessage("input complete: \(aMessage)")
    }
    
    func logGenerateKeypair(withMessage aMessage: String) {
        stepCompleted(withIndicatorState: false)
        logEventWithMessage("keypare generated, pubkey: \(aMessage)")
    }
    
    func logCalculatedECDH(withMessage aMessage: String) {
        stepCompleted(withIndicatorState: false)
        logEventWithMessage("calculated DHKey: \(aMessage)")
    }
    
    func logGeneratedProvisionerRandom(withMessage aMessage: String) {
        stepCompleted(withIndicatorState: false)
        logEventWithMessage("provisioner random: \(aMessage)")
    }
    
    func logReceivedDeviceRandom(withMessage aMessage: String) {
        stepCompleted(withIndicatorState: false)
        logEventWithMessage("device random: \(aMessage)")
    }
    
    func logGeneratedProvisionerConfirmationValue(withMessage aMessage: String) {
        stepCompleted(withIndicatorState: false)
        logEventWithMessage("provisioner confirmation: \(aMessage)")
    }
    
    func logReceivedDeviceConfirmationValue(withMessage aMessage: String) {
        stepCompleted(withIndicatorState: false)
        logEventWithMessage("device confirmation: \(aMessage)")
    }
    
    func logGenratedProvisionInviteData(withMessage aMessage: String) {
        stepCompleted(withIndicatorState: true)
        logEventWithMessage("provision invite data: \(aMessage)")
    }
    
    func logGeneratedProvisioningStartData(withMessage aMessage: String) {
        stepCompleted(withIndicatorState: false)
        logEventWithMessage("provision start data: \(aMessage)")
    }
    
    func logReceivedCapabilitiesData(withMessage aMessage: String) {
        stepCompleted(withIndicatorState: false)
        logEventWithMessage("capabilities : \(aMessage)")
    }
    
    func logReceivedDevicePublicKey(withMessage aMessage: String) {
        stepCompleted(withIndicatorState: false)
        logEventWithMessage("device public key: \(aMessage)")
    }
    
    func logProvisioningSucceeded() {
        stepCompleted(withIndicatorState: true)
        logEventWithMessage("provisioning succeeded")
    }
    
    func logProvisioningFailed(withMessage aMessage: String) {
        stepCompleted(withIndicatorState: false)
        provisioningState = .none
        navigationItem.hidesBackButton = false
        provisionButton.isEnabled = true
        provisionButton.title = "Identify"
        abortButton.isEnabled = false
        abortButton.title = nil
        logEventWithMessage("provisioning failed: \(aMessage)")
    }
}
