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
    peripheral: CBPeripheral,
    rssi: Int
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
        if centralManager.state == .poweredOn {
            startScanning()
        }
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
        
        func start() {
            let bearer = PBGattBearer(target: selectedPeripheral.peripheral)
            bearer.logger = MeshNetworkManager.instance.logger
            open(bearer: bearer)
        }
        
        // Check if there is no conflicting Node already in the network.
        let network = MeshNetworkManager.instance.meshNetwork!
        if let oldNode = network.node(withUuid: unprovisionedDevice.uuid) {
            let removeAction = UIAlertAction(title: "Just reprovision", style: .default) { _ in
                network.remove(node: oldNode)
                start()
            }
            let reconfigureAction = UIAlertAction(title: "Reprovision and reconfigure", style: .default) { _ in
                self.previousNode = oldNode
                network.remove(node: oldNode)
                start()
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            presentAlert(title: "Warning",
                         message: "A node with the same UUID already exists in the network and will be removed.\n\nDo you want to reprovision it and try to apply the same configuration?\n\nNote that the device will be assigned a new unicast address. Other nodes will not get updated to accomodate for that change.",
                         options: [removeAction, reconfigureAction, cancelAction])
        } else {
            // If not, just continue.
            start()
        }
    }

}

// MARK: - CBCentralManagerDelegate

extension ScannerTableViewController: CBCentralManagerDelegate {
    
    private func startScanning() {
        activityIndicator.startAnimating()
        centralManager.delegate = self
        centralManager.scanForPeripherals(withServices: [MeshProvisioningService.uuid],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
    }
    
    private func stopScanning() {
        activityIndicator.stopAnimating()
        centralManager.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let index = discoveredPeripherals.firstIndex(where: { $0.peripheral == peripheral }) {
            if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? DeviceCell {
                let device = discoveredPeripherals[index].device
                device.name = advertisementData.localName
                cell.deviceDidUpdate(device, andRSSI: RSSI.intValue)
            }
        } else {
            if let unprovisionedDevice = UnprovisionedDevice(advertisementData: advertisementData) {
                discoveredPeripherals.append((unprovisionedDevice, peripheral, RSSI.intValue))
                tableView.insertRows(at: [IndexPath(row: discoveredPeripherals.count - 1, section: 0)], with: .fade)
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

extension ScannerTableViewController: GattBearerDelegate {
    
    private func open(bearer: PBGattBearer) {
        bearer.delegate = self
        
        alert = UIAlertController(title: "Status", message: "Connecting...", preferredStyle: .alert)
        alert!.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] action in
            action.isEnabled = false
            self?.alert?.title   = "Aborting"
            self?.alert?.message = "Cancelling connection..."
            bearer.close()
        })
        present(alert!, animated: true) {
            bearer.open()
        }
    }
    
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
            self.alert?.message = "Device disconnected"
            self.alert?.dismiss(animated: true)
            self.alert = nil
            self.selectedDevice = nil
            self.startScanning()
        }
    }
    
}
