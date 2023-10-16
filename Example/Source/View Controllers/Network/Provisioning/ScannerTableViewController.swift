/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import UIKit
import CoreBluetooth
import nRFMeshProvision

typealias DiscoveredPeripheral = (
    device: UnprovisionedDevice,
    bearer: [ProvisioningBearer],
    rssi: [NSNumber]
)

class ScannerTableViewController: UITableViewController {
    
    // MARK: - Outlets and Actions
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    // MARK: - Properties
    
    weak var delegate: ProvisioningViewDelegate?
    
    private var centralManager: CBCentralManager!
    private var discoveredPeripherals: [DiscoveredPeripheral] = []

    private var alert: UIAlertController?
    private var selectedDevice: UnprovisionedDevice?
    private var previousNode: Node?
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEmptyView(title: "Can't see your device?",
                               message: "1. Make sure the device is turned on\nand connected to a power source.\n\n2. Make sure the relevant firmware\nand SoftDevices are flashed.",
                               messageImage: #imageLiteral(resourceName: "baseline-bluetooth"))
        centralManager = CBCentralManager()
        
        tableView.showEmptyView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Scanner can also receive messages sent from nodes with
        // Remote Provisioning Server model.
        MeshNetworkManager.instance.delegate = self
        
        if centralManager.state == .poweredOn {
            startScanning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }
    
    // MARK: - Segue and navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "identify" {
            let destination = segue.destination as! ProvisioningViewController
            destination.unprovisionedDevice = selectedDevice
            destination.bearer = sender as? ProvisioningBearer
            destination.previousNode = previousNode
            destination.delegate = delegate
            selectedDevice = nil
            previousNode = nil
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredPeripherals.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "peripheralCell", for: indexPath) as! DeviceCell
        let peripheral = discoveredPeripherals[indexPath.row]
        cell.setupView(withDevice: peripheral.device, andRSSI: peripheral.rssi)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        stopScanning()
        
        let selectedPeripheral = discoveredPeripherals[indexPath.row]
        let unprovisionedDevice = selectedPeripheral.device
        selectedDevice = unprovisionedDevice
        
        // Check if there is no conflicting Node already in the network.
        let network = MeshNetworkManager.instance.meshNetwork!
        if let oldNode = network.node(withUuid: unprovisionedDevice.uuid) {
            let removeAction = UIAlertAction(title: "Just reprovision", style: .default) { _ in
                network.remove(node: oldNode)
                self.provision(selectedPeripheral)
            }
            let reconfigureAction = UIAlertAction(title: "Reprovision and reconfigure", style: .default) { _ in
                self.previousNode = oldNode
                network.remove(node: oldNode)
                self.provision(selectedPeripheral)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            presentAlert(title: "Warning",
                         message: "A node with the same UUID already exists in the network and will be removed.\n\nDo you want to reprovision it and apply the same configuration?\n\nNote that the node will be provisioned with a new unicast address. All nodes that were configured to publish to any of the unicast addresses assigned to the old node will be reconfigured.",
                         options: [removeAction, reconfigureAction, cancelAction])
        } else {
            // If not, just continue.
            provision(selectedPeripheral)
        }
    }

}

// MARK: - Implementation

private extension ScannerTableViewController {
    
    func startScanning() {
        activityIndicator.startAnimating()
        
        // Scan for devices with Mesh Provisioning Service to provision them over PB GATT Bearer.
        centralManager.delegate = self
        centralManager.scanForPeripherals(withServices: [MeshProvisioningService.uuid],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        
        // Scan for other devices using Remote Provisioning.
        let bearer = MeshNetworkManager.bearer!
        guard bearer.isOpen else {
            return
        }
        
        let manager = MeshNetworkManager.instance
        let meshNetwork = manager.meshNetwork!
        
        let scanRequest = RemoteProvisioningScanStart(timeout: 10)!
        
        // Look for all Nodes with Remote Provisioning Server and send Scan Start request to all.
        meshNetwork.nodes
            .filter { $0.contains(modelWithSigModelId: .remoteProvisioningServerModelId) }
            .forEach { node in
                _ = try? manager.send(scanRequest, to: node)
            }
    }
    
    func stopScanning() {
        activityIndicator.stopAnimating()
        
        // Stop scanning for devices with Mesh Provisioning Service.
        centralManager.stopScan()
        
        // Stop all Remote Provisioning Servers.
        let bearer = MeshNetworkManager.bearer!
        guard bearer.isOpen else {
            return
        }
        
        let manager = MeshNetworkManager.instance
        let meshNetwork = manager.meshNetwork!
        
        // Look for all Nodes with Remote Provisioning Server.
        let remoteProvisioners = meshNetwork.nodes
            .filter { $0.contains(modelWithSigModelId: .remoteProvisioningServerModelId) }
        // Sent Stop Scan message.
        remoteProvisioners.forEach { node in
            let stopScanRequest = RemoteProvisioningScanStop()
            _ = try? manager.send(stopScanRequest, to: node)
        }
    }
    
    func provision(_ selectedPeripheral: DiscoveredPeripheral) {
        // Check if the device can be provisioned using just a single bearer.
        switch selectedPeripheral.bearer.count {
        case 0:
            // Not possible
            return
        case 1:
            let onlyBearer = selectedPeripheral.bearer.first!
            open(bearer: onlyBearer)
        default:
            let meshNetwork = MeshNetworkManager.instance.meshNetwork!
            let bearerOptions = selectedPeripheral.bearer.map { bearer in
                let type = (bearer as? PBRemoteBearer).map {
                    guard let node = meshNetwork.node(withAddress: $0.address) else {
                        return "PB Remote (using 0x\($0.address.hex))"
                    }
                    return "PB Remote via \(node.name ?? "Unknown Node") (0x\($0.address.hex))"
                } ?? "PB GATT"
                return UIAlertAction(title: type, style: .default) { _ in
                    self.open(bearer: bearer)
                }
            }
            let cancelOption = UIAlertAction(title: "Cancel", style: .cancel)
            presentAlert(title: "Choose bearer",
                         message: "Selected device can be provisioned using any of the bearers below:",
                         options: bearerOptions + [cancelOption],
                         preferredStyle: .actionSheet)
        }
    }
    
    func open(bearer: ProvisioningBearer) {
        bearer.delegate = self
        
        alert = UIAlertController(title: "Status", message: "Connecting...", preferredStyle: .alert)
        alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] action in
            guard let self = self else { return }
            action.isEnabled = false
            self.alert?.title   = "Aborting"
            self.alert?.message = "Cancelling connection..."
            do {
                try bearer.close()
            } catch {
                self.alert?.dismiss(animated: true) {
                    self.presentAlert(title: "Error", message: error.localizedDescription)
                }
                self.alert = nil
            }
        })
        present(alert!, animated: true) {
            do {
                try bearer.open()
            } catch {
                self.alert?.dismiss(animated: true) {
                    self.presentAlert(title: "Error", message: error.localizedDescription)
                }
                self.alert = nil
            }
        }
    }
    
}

extension ScannerTableViewController: MeshNetworkDelegate {
    
    func meshNetworkManager(_ manager: MeshNetworkManager,
                            didReceiveMessage message: MeshMessage,
                            sentFrom source: Address, to destination: MeshAddress) {
        switch message {
        case let message as RemoteProvisioningScanReport:
            // Check if a device with the same UUID was already scanned before.
            if let index = discoveredPeripherals.firstIndex(where: { $0.device.uuid == message.uuid }) {
                // Note: RemoteProvisioningScanReport message does not contain the device name.
                //       Unless the device can be provisioned using PB GATT Bearer and it
                //       advertises its Local Name it will be shown as Unknown Device.
                
                // Check if the same bearer already exists.
                // For PB Remote Bearer it's not likely, as scan results are not repeated for the same
                // devices from the same Remote Provisioning Server. Anyway...
                if let bearerIndex = discoveredPeripherals[index].bearer.firstIndex(where: { ($0 as? PBRemoteBearer)?.address == source }) {
                    // If so, just update the RSSI value.
                    discoveredPeripherals[index].rssi[bearerIndex] = message.rssi
                } else {
                    // Add the new PB Remote Bearer to the list.
                    guard let meshNetwork = manager.meshNetwork,
                          let server = meshNetwork.node(withAddress: source),
                          let model = server.models(withSigModelId: .remoteProvisioningServerModelId).first,
                          let bearer = try? PBRemoteBearer(target: message.uuid, using: model, over: manager) else {
                        return
                    }
                    bearer.logger = MeshNetworkManager.instance.logger
                    discoveredPeripherals[index].bearer.append(bearer)
                    discoveredPeripherals[index].rssi.append(message.rssi)
                }
                tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            } else {
                guard let meshNetwork = manager.meshNetwork,
                      let server = meshNetwork.node(withAddress: source),
                      let model = server.models(withSigModelId: .remoteProvisioningServerModelId).first,
                      let bearer = try? PBRemoteBearer(target: message.uuid, using: model, over: manager) else {
                    return
                }
                bearer.logger = MeshNetworkManager.instance.logger
                
                let unprovisionedDevice = UnprovisionedDevice(scanReport: message)
                self.discoveredPeripherals.append((unprovisionedDevice, [bearer], [message.rssi]))
                self.tableView.insertRows(at: [IndexPath(row: discoveredPeripherals.count - 1, section: 0)], with: .automatic)
                self.tableView.hideEmptyView()
            }
        default:
            break
        }
    }
    
}

// MARK: - CBCentralManagerDelegate

extension ScannerTableViewController: CBCentralManagerDelegate {
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Ignore all packets without Unprovisioned Device UUID.
        guard let uuid = advertisementData.unprovisionedDeviceUUID else {
            return
        }
        // Check if a device with the same UUID was already scanned before.
        if let index = discoveredPeripherals.firstIndex(where: { $0.device.uuid == uuid }) {
            // Update the device name.
            // The name is only available when the device is advertising using
            // Service Data and Local Name ADs.
            let device = discoveredPeripherals[index].device
            device.name = advertisementData.localName
            
            // Check if the PB GATT Bearer already exists.
            if let bearerIndex = discoveredPeripherals[index].bearer.firstIndex(where: { $0 is PBGattBearer }) {
                // If so, just update the RSSI value.
                discoveredPeripherals[index].rssi[bearerIndex] = RSSI
            } else {
                // If the PB GATT Bearer doesn't exist, add it and corresponding RSSI value.
                let bearer = PBGattBearer(target: peripheral)
                bearer.logger = MeshNetworkManager.instance.logger
                discoveredPeripherals[index].bearer.append(bearer)
                discoveredPeripherals[index].rssi.append(RSSI)
            }
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        } else {
            if let unprovisionedDevice = UnprovisionedDevice(advertisementData: advertisementData) {
                let bearer = PBGattBearer(target: peripheral)
                bearer.logger = MeshNetworkManager.instance.logger
                
                discoveredPeripherals.append((unprovisionedDevice, [bearer], [RSSI]))
                tableView.insertRows(at: [IndexPath(row: discoveredPeripherals.count - 1, section: 0)], with: .automatic)
                tableView.hideEmptyView()
            }
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            print("Central is not powered on")
        } else {
            startScanning()
        }
    }
    
}

// MARK: - GattBearerDelegate

extension ScannerTableViewController: GattBearerDelegate {
    
    func bearerDidConnect(_ bearer: Bearer) {
        DispatchQueue.main.async {
            self.alert?.message = "Discovering services..."
        }
    }
    
    func bearerDidDiscoverServices(_ bearer: Bearer) {
        DispatchQueue.main.async {
            self.alert?.message = "Initializing..."
        }
    }
        
    func bearerDidOpen(_ bearer: Bearer) {
        DispatchQueue.main.async {
            self.alert?.dismiss(animated: false) {
                self.performSegue(withIdentifier: "identify", sender: bearer)
            }
            self.alert = nil
        }
    }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        DispatchQueue.main.async {
            self.alert?.dismiss(animated: true) {
                self.presentAlert(title: "Status", message: error?.localizedDescription ?? "Device disconnected", cancelable: false)
            }
            self.selectedDevice = nil
            self.startScanning()
        }
    }
    
}
