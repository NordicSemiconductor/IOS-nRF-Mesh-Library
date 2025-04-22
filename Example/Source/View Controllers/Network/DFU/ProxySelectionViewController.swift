/*
* Copyright (c) 2025, Nordic Semiconductor
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
import NordicMesh
import CoreBluetooth

private let links: [(title: String, url: URL)] = [
    ("Device Firmware Update", URL(string: "https://docs.nordicsemi.com/bundle/ncs-latest/page/zephyr/connectivity/bluetooth/api/mesh/dfu.html")!),
    ("DFU over Bluetooth Mesh", URL(string: "https://docs.nordicsemi.com/bundle/ncs-latest/page/nrf/protocols/bt/bt_mesh/dfu_over_bt_mesh.html")!),
    ("Sample: Distributor", URL(string: "https://docs.nordicsemi.com/bundle/ncs-latest/page/nrf/samples/bluetooth/mesh/dfu/distributor/README.html")!),
    ("Device Management and Simple Management Protocol (SMP)", URL(string: "https://docs.nordicsemi.com/bundle/ncs-latest/page/zephyr/services/device_mgmt/index.html")!)
]

private enum Section {
    case info
    case noProxy
    case proxyInformation
    case smp
    case distributor
    case boundAppKey
    case status
    case capabilities
    case documentation
    
    var rows: Int {
        switch self {
        case .info: return 0
        case .noProxy: return 1
        case .proxyInformation: return 3
        case .smp: return 0 // 2 or 1
        case .distributor: return 1
        case .boundAppKey: return 0 // number of bound app keys + 1
        case .status: return 1
        case .capabilities: return 5
        case .documentation: return links.count
        }
    }
}

private struct ProxyDetails {
    let name: String
    let unicastAddress: Address
    var isSmpSupported: Bool
    var isSmpSecure: Bool
    var distributorServerModel: Model?
    var applicationKeys: [ApplicationKey]
    var capabilities: Capabilities?
    var phase: FirmwareDistributionPhase?
    
    struct Capabilities {
        let maxReceiversListSize: UInt16
        let maxFirmwareImagesListSize: UInt16
        let maxFirmwareImageSize: UInt32
        let maxUploadSpace: UInt32
        let remainingUploadSpace: UInt32
    }
    
    init(_ proxy: Node) {
        self.name = proxy.name ?? "Unknown"
        self.unicastAddress = proxy.primaryUnicastAddress
        distributorServerModel = proxy.models(withSigModelId: .firmwareDistributionServerModelId).first
        self.applicationKeys = distributorServerModel?.boundApplicationKeys ?? []
        self.isSmpSupported = false
        self.isSmpSecure = proxy.contains(modelWithModelId: .lePairingResponder, definedBy: .nordicSemiconductorCompanyId)
    }
    
    var isSupported: Bool {
        return capabilities != nil && isSmpSupported && phase == .idle
    }
}

class ProxySelectionViewController: UITableViewController {
    // MARK: - Outlets
    
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBAction func nextTapped(_ sender: UIBarButtonItem) {
        guard let proxyDetails = proxyDetails, proxyDetails.isSupported else { return }
        if proxyDetails.isSmpSecure {
            performSegue(withIdentifier: "pair", sender: nil)
        } else {
            performSegue(withIdentifier: "continue", sender: nil)
        }
    }
    
    // MARK: - Properties
    
    private var sections: [Section] = []
    private var proxyDetails: ProxyDetails?
    private var selectedAppKey: ApplicationKey?
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "pair":
            let viewController = segue.destination as! PasskeyViewController
            viewController.node = proxyDetails!.distributorServerModel!.parentElement!.parentNode
            viewController.bearer = MeshNetworkManager.bearer.proxies.first { $0.isOpen }
        case "continue":
            let destination = segue.destination as! FirmwareSelectionViewController
            destination.node = proxyDetails!.distributorServerModel!.parentElement!.parentNode
            destination.bearer = MeshNetworkManager.bearer.proxies.first { $0.isOpen }
        default:
            break
        }
        let navigationController = segue.destination as? UINavigationController
        switch segue.identifier {
        case "bind":
            let viewController = navigationController?.topViewController as! ModelBindAppKeyViewController
            viewController.model = proxyDetails!.distributorServerModel
            viewController.delegate = self
        default:
            break
        }
    }
    
    // MARK: - Table View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MeshNetworkManager.bearer.delegate = self
        let proxyFilter = MeshNetworkManager.instance.proxyFilter
        proxyFilter.delegate = self
        
        // Refresh the view with the current proxy filter.
        proxyFilterUpdated(type: proxyFilter.type, addresses: proxyFilter.addresses)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sections[section]
        switch section {
        case .boundAppKey: return (proxyDetails?.applicationKeys.count ?? 0) + 1 // Bind App Key
        case .smp: return proxyDetails?.isSmpSupported == true ? 2 : 1
        default: return section.rows
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        switch section {
        case .noProxy:
            let cell = tableView.dequeueReusableCell(withIdentifier: "changeProxy", for: indexPath)
            cell.textLabel?.text = "Connect"
            return cell
        case .proxyInformation:
            if indexPath.row == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "changeProxy", for: indexPath)
                cell.textLabel?.text = "Change"
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "value", for: indexPath)
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Name"
                cell.detailTextLabel?.text = proxyDetails!.name
            case 1:
                cell.textLabel?.text = "Unicast Address"
                cell.detailTextLabel?.text = "0x\(proxyDetails!.unicastAddress.hex)"
            default:
                fatalError("Invalid row")
            }
            return cell
        case .smp:
            let cell = tableView.dequeueReusableCell(withIdentifier: "status", for: indexPath)
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = proxyDetails!.isSmpSupported ? "SMP Service supported" : "SMP Service not supported"
                cell.checked = proxyDetails!.isSmpSupported
            case 1:
                cell.textLabel?.text = proxyDetails!.isSmpSecure ? "Secured using LE Pairing Responder model" : "Insecure access"
                cell.checked = proxyDetails!.isSmpSecure
            default:
                fatalError("Invalid row")
            }
            return cell
        case .distributor:
            let isDistributor = proxyDetails?.distributorServerModel != nil
            let cell = tableView.dequeueReusableCell(withIdentifier: "status", for: indexPath)
            cell.textLabel?.text = "Firmware Distributor Server model \(isDistributor ? "found" : "not found")"
            cell.checked = isDistributor
            return cell
        case .boundAppKey:
            if indexPath.row == proxyDetails!.applicationKeys.count {
                return tableView.dequeueReusableCell(withIdentifier: "bind", for: indexPath)
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "key", for: indexPath)
                let key = proxyDetails!.applicationKeys[indexPath.row]
                cell.textLabel?.text = key.name
                cell.detailTextLabel?.text = "Bound to \(key.boundNetworkKey.name)"
                cell.accessoryType = key == selectedAppKey ? .checkmark : .none
                return cell
            }
        case .status:
            let cell = tableView.dequeueReusableCell(withIdentifier: "value", for: indexPath)
            cell.textLabel?.text = "Phase"
            cell.detailTextLabel?.text = proxyDetails?.phase?.debugDescription ?? "Unknown"
            return cell
        case .capabilities:
            let cell = tableView.dequeueReusableCell(withIdentifier: "value", for: indexPath)
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Max receivers list size"
                if let capabilities = proxyDetails?.capabilities {
                    cell.detailTextLabel?.text = "\(capabilities.maxReceiversListSize)"
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            case 1:
                cell.textLabel?.text = "Max firmware images list size"
                if let capabilities = proxyDetails?.capabilities {
                    cell.detailTextLabel?.text = "\(capabilities.maxFirmwareImagesListSize)"
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            case 2:
                cell.textLabel?.text = "Max firmware image size"
                if let capabilities = proxyDetails?.capabilities {
                    cell.detailTextLabel?.text = "\(capabilities.maxFirmwareImageSize) bytes"
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            case 3:
                cell.textLabel?.text = "Max upload space"
                if let capabilities = proxyDetails?.capabilities {
                    cell.detailTextLabel?.text = "\(capabilities.maxUploadSpace) bytes"
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            case 4:
                cell.textLabel?.text = "Remaining upload space"
                if let capabilities = proxyDetails?.capabilities {
                    cell.detailTextLabel?.text = "\(capabilities.remainingUploadSpace) bytes"
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                }
            default:
                fatalError("Invalid row")
            }
            return cell
        case .documentation:
            let cell = tableView.dequeueReusableCell(withIdentifier: "link", for: indexPath)
            cell.detailTextLabel?.text = nil
            cell.textLabel?.text = links[indexPath.row].title
            cell.detailTextLabel?.text = links[indexPath.row].url.absoluteString
            return cell
        case .info:
            fatalError("Info has no views, only footer")
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = sections[section]
        switch section {
        case .proxyInformation, .noProxy: return "GATT Proxy"
        case .smp: return "Device Management"
        case .distributor: return "Firmware Distributor"
        case .boundAppKey: return "Bound Application Keys"
        case .status: return "Distributor Status"
        case .capabilities: return "Capabilities"
        case .documentation: return "Read More"
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let section = sections[section]
        switch section {
        case .info: return "Active connection to a GATT Proxy node with Firmware Distributor Server model and SMP Service enabled is required."
        case .boundAppKey: return "Selected Application Key will be used for Firmware Distribution."
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let readMoreAction = UIAlertAction(title: "Read Mode", style: .default) { _ in
            UIApplication.shared.open(URL(string: "https://docs.nordicsemi.com/bundle/ncs-latest/page/nrf/samples/bluetooth/mesh/dfu/distributor/README.html#smp_over_bluetooth_authentication")!)
        }
        presentAlert(title: "Warning",
                     message: "Although the SMP Service has been discovered on the device, the node does not contain LE Pairing Responder model from Nordic Semiconductor. This may indicate, that the service is not protected and allows insecure access to the device management subsystem.\n\nConsider enabling Bluetooth authentication.",
                     option: readMoreAction,
        )
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let section = sections[indexPath.section]
        switch section {
        case .documentation, .noProxy, .boundAppKey: return true
        case .proxyInformation: return indexPath.row == 2
        default: return false
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let section = sections[indexPath.section]
        switch section {
        case .boundAppKey:
            guard indexPath.row < proxyDetails!.applicationKeys.count else {
                // A segue to bond app key was clicked.
                return
            }
            selectedAppKey = proxyDetails!.applicationKeys[indexPath.row]
            if let index = sections.firstIndex(of: .boundAppKey) {
                tableView.reloadSections(IndexSet(integer: index), with: .automatic)
            }
        case .documentation:
            UIApplication.shared.open(links[indexPath.row].url)
        default:
            break
        }
    }

}

extension ProxySelectionViewController: BindAppKeyDelegate, GattBearerDelegate {
    
    func bearerDidOpen(_ bearer: any NordicMesh.Bearer) {
        // Do nothing, we're waiting for the proxy filter to update.
    }
    
    func bearer(_ bearer: any Bearer, didClose error: (any Error)?) {
        nextButton.isEnabled = false
        // Make sure the ProxyFilter is not busy.
        MeshNetworkManager.instance.proxyFilter.proxyDidDisconnect()
        // The bearer has closed. Attempt to send a message
        // will fail, but the Proxy Filter will receive .bearerClosed
        // error, upon which it will clear the filter list and notify
        // the delegate.
        MeshNetworkManager.instance.proxyFilter.clear()
    }
    
    
    func keyBound() {
        if let model = proxyDetails?.distributorServerModel {
            proxyDetails?.applicationKeys = model.boundApplicationKeys
            
            if selectedAppKey == nil {
                selectedAppKey = model.boundApplicationKeys.first
            }
            if proxyDetails?.capabilities == nil {
                Task {
                    await self.readDistributionStatus(from: model, using: selectedAppKey!)
                    await self.readCapabilities(from: model, using: selectedAppKey!)
                }
            }
        }
        
        if let index = self.sections.firstIndex(of: .boundAppKey) {
            tableView.reloadSections(IndexSet(integer: index), with: .automatic)
        }
    }
    
}

extension ProxySelectionViewController: ProxyFilterDelegate {
    
    func proxyFilterUpdated(type: ProxyFilerType, addresses: Set<Address>) {
        // Reinitialize sections if Proxy filter is set.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.sections = [.info]
            if let proxy = MeshNetworkManager.instance.proxyFilter.proxy, !addresses.isEmpty {
                self.proxyDetails = ProxyDetails(proxy)
                self.selectedAppKey = proxyDetails?.distributorServerModel?.boundApplicationKeys.first
                self.sections.append(contentsOf: [.proxyInformation, .smp, .distributor])
                if let model = proxyDetails?.distributorServerModel {
                    self.sections.append(contentsOf: [.boundAppKey, .status, .capabilities])
                    if let applicationKey = self.selectedAppKey {
                        Task {
                            await self.readDistributionStatus(from: model, using: applicationKey)
                            await self.readCapabilities(from: model, using: applicationKey)
                        }
                    }
                } else {
                    self.sections.append(.documentation)
                }
                self.verifyProxy()
            } else {
                self.proxyDetails = nil
                self.selectedAppKey = nil
                self.sections.append(contentsOf: [.noProxy, .documentation])
            }
            self.tableView.reloadData()
        }
    }
    
}

private extension UITableViewCell {
    
    /// Sets a checked or xmark accessory.
    ///
    /// The cells with identifier "status" have accessory set to `.checkmark` in the Storyboard.
    /// This property sets a custom `accessoryView` with "xmark" image when `checked` is set to false.
    /// Setting it to true removes the accessory view making the default accessory visible.
    var checked: Bool {
        get {
            return accessoryView != nil
        }
        set {
            if newValue {
                accessoryView = nil
                tintColor = nil
            } else {
                accessoryView = UIImageView(image: UIImage(systemName: "xmark"))
                tintColor = .systemRed
            }
        }
    }
    
}

private extension ProxySelectionViewController {
    
    func readDistributionStatus(from model: Model, using applicationKey: ApplicationKey) async {
        do {
            let response = try await MeshNetworkManager.instance.send(FirmwareDistributionGet(), to: model, using: applicationKey)
            let status = response as! FirmwareDistributionStatus
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.proxyDetails?.phase = status.phase
                if let index = self.sections.firstIndex(of: .status) {
                    self.tableView.reloadSections(IndexSet(integer: index), with: .automatic)
                }
                if status.phase == .idle {
                    self.nextButton.isEnabled = self.proxyDetails?.isSupported ?? false
                } else {
                    self.nextButton.isEnabled = false
                }
            }
        } catch {
            NSLog("Error reading distribution status: %@", error.localizedDescription)
        }
    }
    
    func readCapabilities(from model: Model, using applicationKey: ApplicationKey) async {
        do {
            let response = try await MeshNetworkManager.instance.send(FirmwareDistributionCapabilitiesGet(), to: model, using: applicationKey)
            let capabilities = response as! FirmwareDistributionCapabilitiesStatus
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.proxyDetails?.capabilities = ProxyDetails.Capabilities(
                    maxReceiversListSize: capabilities.maxReceiversCount,
                    maxFirmwareImagesListSize: capabilities.maxFirmwareImagesListSize,
                    maxFirmwareImageSize: capabilities.maxFirmwareImageSize,
                    maxUploadSpace: capabilities.maxUploadSpace,
                    remainingUploadSpace: capabilities.remainingUploadSpace
                )
                self.nextButton.isEnabled = self.proxyDetails?.isSupported ?? false
                if let index = self.sections.firstIndex(of: .capabilities) {
                    self.tableView.reloadSections(IndexSet(integer: index), with: .automatic)
                }
            }
        } catch {
            NSLog("Error reading capabilities: %@", error.localizedDescription)
        }
    }
    
    func verifyProxy() {
        if let bearer = MeshNetworkManager.bearer?.proxies.first(where: { $0.isOpen }) {
            Task {
                do {
                    let isSmpSupported = try await checkSmpService(ofBearer: bearer)
                    proxyDetails?.isSmpSupported = isSmpSupported
                } catch {
                    proxyDetails?.isSmpSupported = false
                }
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.nextButton.isEnabled = self.proxyDetails?.isSupported ?? false
                    if let index = self.sections.firstIndex(of: .smp) {
                        self.tableView.reloadSections(IndexSet(integer: index), with: .automatic)
                    }
                }
            }
        }
    }
    
    enum ConnectionError: LocalizedError {
        case invalidState(state: CBManagerState)
        case peripheralNotFound
        case connectionFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidState(let state):
                return "Bluetooth is not powered on. State: \(state)"
            case .peripheralNotFound:
                return "Peripheral not found."
            case .connectionFailed:
                return "Failed to connect to peripheral."
            }
        }
    }
    
    func checkSmpService(ofBearer bearer: GattBearer) async throws -> Bool {
        class Connection: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
            public static let SmpServiceUUID        = CBUUID(string: "8D53DC1D-1DB7-4CD3-868B-8A527460AA84")
            public static let SmpCharacteristicUUID = CBUUID(string: "DA2E7828-FBCE-4E01-AE9E-261174997C48")
            
            private let continuation: CheckedContinuation<Bool, Error>
            private var identifier: UUID
            private var peripheral: CBPeripheral?
            
            init(for bearer: GattBearer, _ continuation: CheckedContinuation<Bool, Error>) {
                self.continuation = continuation
                self.identifier = bearer.identifier
            }
            
            func centralManagerDidUpdateState(_ central: CBCentralManager) {
                if central.state == .poweredOn {
                    guard let peripheral = central.retrievePeripherals(withIdentifiers: [identifier]).first else {
                        continuation.resume(throwing: ConnectionError.peripheralNotFound)
                        return
                    }
                    self.peripheral = peripheral
                    peripheral.delegate = self
                    central.connect(peripheral)
                } else {
                    continuation.resume(throwing: ConnectionError.invalidState(state: central.state))
                }
            }
            
            func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
                continuation.resume(throwing: ConnectionError.connectionFailed)
            }
            
            func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
                peripheral.discoverServices([Connection.SmpServiceUUID])
            }
            
            func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let services = peripheral.services,
                      let service = services.first(where: { $0.uuid == Connection.SmpServiceUUID }) else {
                    continuation.resume(returning: false)
                    return
                }
                peripheral.discoverCharacteristics([Connection.SmpCharacteristicUUID], for: service)
            }
            
            func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let characteristics = service.characteristics,
                      let characteristic = characteristics.first(where: { $0.uuid == Connection.SmpCharacteristicUUID }) else {
                    continuation.resume(returning: false)
                    return
                }
                continuation.resume(returning: characteristic.properties.contains(.notify))
            }
            
        }
        var manager: CBCentralManager!
        var strongReference: Connection!
        defer {
            strongReference = nil
            manager.delegate = nil
            manager = nil
        }
        return try await withCheckedThrowingContinuation { continuation in
            strongReference = Connection(for: bearer, continuation)
            manager = CBCentralManager(delegate: strongReference, queue: nil)
        }
    }
    
}

