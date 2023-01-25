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

typealias DiscoveredProxy = (device: GattBearer, rssi: Int)

class ProxySelectorViewController: UITableViewController {
    
    // MARK: - Outlets and Actions
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    // MARK: - Properties
    
    weak var delegate: ProvisioningViewDelegate?
    var meshNetwork: MeshNetwork?
    
    private var centralManager: CBCentralManager!
    private var proxies: [DiscoveredProxy] = []
    
    private var alert: UIAlertController?
    private var selectedDevice: GattBearer?
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEmptyView(title: "Can't see your proxy?",
                               message: "1. Make sure the device is turned on\nand connected to a power source.\n\n2. Make sure it's provisioned to this mesh network.",
                               messageImage: #imageLiteral(resourceName: "baseline-bluetooth"))
        centralManager = CBCentralManager()
        
        tableView.showEmptyView()
        
        meshNetwork = MeshNetworkManager.instance.meshNetwork
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if centralManager.state == .poweredOn {
            startScanning()
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return proxies.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "peripheralCell", for: indexPath) as! ProxyCell
        let proxy = proxies[indexPath.row]
        cell.setupView(withProxy: proxy.device, andRSSI: proxy.rssi)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let bearer = proxies[indexPath.row].device
        bearer.logger = MeshNetworkManager.instance.logger
        bearer.delegate = self
        
        stopScanning()
        selectedDevice = bearer
        
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

}

// MARK: - CBCentralManagerDelegate

extension ProxySelectorViewController: CBCentralManagerDelegate {
    
    private func startScanning() {
        activityIndicator.startAnimating()
        centralManager.delegate = self
        centralManager.scanForPeripherals(withServices: [MeshProxyService.uuid],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
    }
    
    private func stopScanning() {
        activityIndicator.stopAnimating()
        centralManager.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let meshNetwork = meshNetwork else { return }
        
        // Is it a Network ID or Private Network Identity beacon?
        if let networkIdentity = advertisementData.networkIdentity {
            guard meshNetwork.matches(networkIdentity: networkIdentity) else {
                // A Node from another mesh network.
                return
            }
        } else {
            // Is it a Node Identity or Private Node Identity beacon?
            guard let nodeIdentity = advertisementData.nodeIdentity,
                  meshNetwork.matches(nodeIdentity: nodeIdentity) else {
                // A Node from another mesh network.
                return
            }
        }
        
        if let index = proxies.firstIndex(where: { $0.device.identifier == peripheral.identifier }) {
            if let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? ProxyCell {
                cell.deviceDidUpdate(proxies[index].device, andRSSI: RSSI.intValue)
            }
        } else {
            let bearer = GattBearer(target: peripheral)
            proxies.append((device: bearer, rssi: RSSI.intValue))
            tableView.insertRows(at: [IndexPath(row: proxies.count - 1, section: 0)], with: .fade)
            tableView.hideEmptyView()
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

extension ProxySelectorViewController: GattBearerDelegate {
    
    func bearerDidConnect(_ bearer: Bearer) {
        DispatchQueue.main.async { [weak self] in
            self?.alert?.message = "Discovering services..."
        }
    }
    
    func bearerDidDiscoverServices(_ bearer: Bearer) {
        DispatchQueue.main.async { [weak self] in
            self?.alert?.message = "Initializing..."
        }
    }
        
    func bearerDidOpen(_ bearer: Bearer) {
        MeshNetworkManager.bearer.use(proxy: bearer as! GattBearer)
        DispatchQueue.main.async { [weak self] in
            self?.alert?.dismiss(animated: true) { [weak self] in
                self?.dismiss(animated: true)
            }
            self?.alert = nil
        }
    }
    
    func bearer(_ bearer: Bearer, didClose error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.alert?.message = "Device disconnected"
            self.alert?.dismiss(animated: true)
            self.alert = nil
            self.selectedDevice = nil
            self.startScanning()
        }
    }
    
}
