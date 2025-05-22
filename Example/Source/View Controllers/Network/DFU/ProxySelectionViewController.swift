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
        case .capabilities: return 5 + 1 // Free Space
        case .documentation: return links.count
        }
    }
}

private struct ProxyDetails {
    let node: Node
    let name: String
    let unicastAddress: Address
    var isSmpSupported: Bool
    var isSmpSecure: Bool
    var distributorServerModel: Model?
    var applicationKeys: [ApplicationKey]
    var parameters: DFUParameters?
    var phase: FirmwareDistributionPhase?
    var capabilities: Capabilities?
    var storedFirmwareImagesListSize: UInt16?
    
    struct Capabilities {
        let maxReceiversListSize: UInt16
        let maxFirmwareImagesListSize: UInt16
        let maxFirmwareImageSize: UInt32
        let maxUploadSpace: UInt32
        let remainingUploadSpace: UInt32
    }
    
    init(_ proxy: Node) {
        self.node = proxy
        self.name = proxy.name ?? "Unknown"
        self.unicastAddress = proxy.primaryUnicastAddress
        distributorServerModel = proxy.models(withSigModelId: .firmwareDistributionServerModelId).first
        self.applicationKeys = distributorServerModel?.boundApplicationKeys ?? []
        self.isSmpSupported = false
        self.isSmpSecure = proxy.contains(modelWithModelId: .lePairingResponder, definedBy: .nordicSemiconductorCompanyId)
    }
    
    var isSupported: Bool {
        guard let capabilities = capabilities else {
            return false
        }
        /// Whether distribution is in progress.
        let updateInProgress = phase == .transferActive || phase == .transferSuccess || phase == .transferSuspended
        /// Number of used slots.
        let occupiedSlots = storedFirmwareImagesListSize ?? 0
        /// Whether the Distributor is idle and can start new Firmware Update
        ///
        /// Note, that for that we need SMP support, available slots, etc..
        let idle = phase == .idle &&
                   isSmpSupported &&
                   capabilities.maxFirmwareImageSize > 0 &&
                   capabilities.maxUploadSpace > 0 &&
                   capabilities.remainingUploadSpace > 0 &&
                   (
                        capabilities.remainingUploadSpace == capabilities.maxUploadSpace ||
                        capabilities.maxFirmwareImagesListSize > occupiedSlots
                   )
        return updateInProgress || idle
    }
}

class ProxySelectionViewController: UITableViewController {
    // MARK: - Outlets
    
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBAction func nextTapped(_ sender: UIBarButtonItem) {
        guard let proxyDetails = proxyDetails, proxyDetails.isSupported else { return }
        // Can we go directly to the Firmware Update screen to see progress?
        if let _ = proxyDetails.capabilities,
           proxyDetails.phase == .transferActive || proxyDetails.phase == .transferSuccess || proxyDetails.phase == .transferSuspended {
            performSegue(withIdentifier: "progress", sender: nil)
            return
        }
        // If the SMP Service is secured using LE Pairing Responder model,
        // we need to pair with the device before proceeding.
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
            let destination = segue.destination as! PasskeyViewController
            destination.node = proxyDetails!.distributorServerModel!.parentElement!.parentNode
            destination.bearer = MeshNetworkManager.bearer.proxies.first { $0.isOpen }
            destination.applicationKey = selectedAppKey
            destination.maxReceiversListSize = proxyDetails?.capabilities?.maxReceiversListSize
            if let maxUploadSpace = proxyDetails?.capabilities?.remainingUploadSpace,
               let maxImageSize = proxyDetails?.capabilities?.maxFirmwareImageSize {
                destination.availableSpace = min(maxUploadSpace, maxImageSize)
            } else {
                // This should never happen.
                destination.availableSpace = 0
            }
        case "continue":
            let destination = segue.destination as! FirmwareSelectionViewController
            destination.node = proxyDetails!.distributorServerModel!.parentElement!.parentNode
            destination.bearer = MeshNetworkManager.bearer.proxies.first { $0.isOpen }
            destination.applicationKey = selectedAppKey
            destination.maxReceiversListSize = proxyDetails?.capabilities?.maxReceiversListSize
            if let maxUploadSpace = proxyDetails?.capabilities?.remainingUploadSpace,
               let maxImageSize = proxyDetails?.capabilities?.maxFirmwareImageSize {
                destination.availableSpace = min(maxUploadSpace, maxImageSize)
            } else {
                // This should never happen.
                destination.availableSpace = 0
            }
        case "progress":
            let destination = segue.destination as! DFUViewController
            destination.distributor = proxyDetails!.distributorServerModel!.parentElement!.parentNode
            destination.bearer = MeshNetworkManager.bearer.proxies.first { $0.isOpen }
            destination.applicationKey = selectedAppKey
            destination.parameters = proxyDetails!.parameters
            destination.estimatedFirmwareSize = Int(proxyDetails!.capabilities!.maxUploadSpace) - Int(proxyDetails!.capabilities!.remainingUploadSpace)
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
            cell.textLabel?.text = "Connect"
            return cell
        case .proxyInformation:
            if indexPath.row == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
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
                cell.textLabel?.text = "SMP Service"
                cell.detailTextLabel?.text = proxyDetails!.isSmpSupported ? "Supported" : "Not supported"
                cell.checked = proxyDetails!.isSmpSupported
            case 1:
                cell.textLabel?.text = "Access"
                cell.detailTextLabel?.text = proxyDetails!.isSmpSecure ? "Secure" : "Insecure"
                if proxyDetails!.isSmpSecure {
                    cell.checked = true
                } else {
                    cell.tintColor = .systemOrange
                    cell.accessoryView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle"))
                }
            default:
                fatalError("Invalid row")
            }
            return cell
        case .distributor:
            let isDistributor = proxyDetails?.distributorServerModel != nil
            let cell = tableView.dequeueReusableCell(withIdentifier: "status", for: indexPath)
            cell.textLabel?.text = "Firmware Distributor Server model"
            cell.detailTextLabel?.text = "\(isDistributor ? "Found" : "Not found")"
            cell.checked = isDistributor
            return cell
        case .boundAppKey:
            if indexPath.row == proxyDetails!.applicationKeys.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
                cell.textLabel?.text = "Bind Application Key"
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "key", for: indexPath)
                let key = proxyDetails!.applicationKeys[indexPath.row]
                cell.textLabel?.text = key.name
                cell.detailTextLabel?.text = "Bound to \(key.boundNetworkKey.name)"
                cell.accessoryType = key == selectedAppKey ? .checkmark : .none
                return cell
            }
        case .status:
            let cell = tableView.dequeueReusableCell(withIdentifier: "status", for: indexPath)
            cell.textLabel?.text = "Phase"
            cell.detailTextLabel?.text = proxyDetails?.phase?.debugDescription ?? "Unknown"
            switch proxyDetails?.phase {
            case .idle, .failed, .completed, .transferActive, .transferSuccess, .transferSuspended, .applyingUpdate:
                cell.checked = true
            default:
                cell.checked = false
            }
            return cell
        case .capabilities:
            if indexPath.row == 5 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
                cell.textLabel?.text = "Free Space"
                if let storedSlots = proxyDetails?.storedFirmwareImagesListSize {
                    cell.isUserInteractionEnabled = storedSlots > 0 && proxyDetails?.phase?.isBusy == false
                    cell.textLabel?.isEnabled = storedSlots > 0 && proxyDetails?.phase?.isBusy == false
                } else {
                    cell.isUserInteractionEnabled = false
                    cell.textLabel?.isEnabled = false
                }
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "status", for: indexPath)
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Max Receiver List Size"
                if let proxyDetails = proxyDetails,
                   let maxReceivers = proxyDetails.capabilities?.maxReceiversListSize {
                    cell.detailTextLabel?.text = "\(maxReceivers)"
                    cell.checked = maxReceivers > 0
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                    cell.checked = false
                }
            case 1:
                cell.textLabel?.text = "Available Firmware Images"
                if let proxyDetails = proxyDetails,
                   let storedSlots = proxyDetails.storedFirmwareImagesListSize,
                   let maxSlots = proxyDetails.capabilities?.maxFirmwareImagesListSize {
                    cell.detailTextLabel?.text = "\(maxSlots - storedSlots) / \(maxSlots)"
                    let hasAvailableSlots = storedSlots < maxSlots
                    let canResume = proxyDetails.phase == .transferActive || proxyDetails.phase == .transferSuccess || proxyDetails.phase == .transferSuspended
                    cell.checked = hasAvailableSlots || canResume
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                    cell.checked = false
                }
            case 2:
                cell.textLabel?.text = "Max Firmware Image Size"
                if let capabilities = proxyDetails?.capabilities {
                    cell.detailTextLabel?.text = "\(capabilities.maxFirmwareImageSize) bytes"
                    cell.checked = capabilities.maxFirmwareImageSize > 0
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                    cell.checked = false
                }
            case 3:
                cell.textLabel?.text = "Max Upload Space"
                if let capabilities = proxyDetails?.capabilities {
                    cell.detailTextLabel?.text = "\(capabilities.maxUploadSpace) bytes"
                    cell.checked = capabilities.maxUploadSpace > 0
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                    cell.checked = false
                }
            case 4:
                cell.textLabel?.text = "Remaining Upload Space"
                if let capabilities = proxyDetails?.capabilities {
                    cell.detailTextLabel?.text = "\(capabilities.remainingUploadSpace) bytes"
                    cell.checked = capabilities.remainingUploadSpace > 0
                } else {
                    cell.detailTextLabel?.text = "Unknown"
                    cell.checked = false
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
        case .smp: return "SMP Service may be secured using LE Pairing Responder model."
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
                     option: readMoreAction
        )
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let section = sections[indexPath.section]
        switch section {
        case .documentation, .noProxy, .boundAppKey: return true
        case .proxyInformation: return indexPath.row == 2
        case .capabilities: return indexPath.row == 5
        default: return false
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let section = sections[indexPath.section]
        switch section {
        case .noProxy, .proxyInformation:
            performSegue(withIdentifier: "connect", sender: self)
        case .boundAppKey:
            guard indexPath.row < proxyDetails!.applicationKeys.count else {
                performSegue(withIdentifier: "bind", sender: self)
                return
            }
            selectedAppKey = proxyDetails!.applicationKeys[indexPath.row]
            if let index = sections.firstIndex(of: .boundAppKey) {
                tableView.reloadSections(IndexSet(integer: index), with: .automatic)
            }
        case .capabilities:
            guard let selectedAppKey = selectedAppKey,
                  let distributorServerModel = proxyDetails?.distributorServerModel else {
                return
            }
            Task {
                do {
                    if proxyDetails?.phase == .completed || proxyDetails?.phase == .failed || proxyDetails?.phase == .applyingUpdate {
                        let phase = try await cancelDistribution(from: distributorServerModel, using: selectedAppKey)
                        proxyDetails?.phase = phase
                        if let index = sections.firstIndex(of: .status) {
                            tableView.reloadSections(IndexSet(integer: index), with: .automatic)
                        }
                    }
                    // Clear the list of slots if the maximum number of slots is reached,
                    // or if the list of Receivers is empty. The last condition allows
                    // clearing the list of Receivers and the list of slots in 2 steps
                    // when the list of slots is lower than the maximum value.
                    // In that case user would click Free Space button twice.
                    if proxyDetails?.storedFirmwareImagesListSize != 0 &&
                       proxyDetails?.storedFirmwareImagesListSize == proxyDetails?.capabilities?.maxFirmwareImagesListSize {
                        let slots = try await deleteStoredFirmwareImages(from: distributorServerModel, using: selectedAppKey)
                        proxyDetails?.storedFirmwareImagesListSize = slots
                        
                        let capabilities = try await readCapabilities(from: distributorServerModel, using: selectedAppKey)
                        proxyDetails?.capabilities = capabilities
                    }
                    nextButton.isEnabled = proxyDetails?.isSupported ?? false
                    if let index = sections.firstIndex(of: .capabilities) {
                        tableView.reloadSections(IndexSet(integer: index), with: .automatic)
                    }
                } catch {
                    NSLog("Error while deleting all slots: \(error)")
                }
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
                readDistributorState(from: model, using: selectedAppKey!)
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
                        readDistributorState(from: model, using: applicationKey)
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
    
    func readDistributorState(from model: Model, using applicationKey: ApplicationKey) {
        Task {
            do {
                let status = try await readDistributionStatus(from: model, using: applicationKey)
                let capabilities = try await readCapabilities(from: model, using: applicationKey)
                let slots = try await readFirmwareImagesListSize(from: model, using: applicationKey)
                
                proxyDetails?.phase = status.phase
                if let ttl = status.ttl, let timeoutBase = status.timeoutBase,
                let transferMode = status.transferMode, let updatePolicy = status.updatePolicy {
                    proxyDetails?.parameters = DFUParameters(
                        ttl: ttl, timeoutBase: timeoutBase,
                        transferMode: transferMode, updatePolicy: updatePolicy,
                        multicastAddress: status.multicastAddress.map { MeshAddress($0) }
                    )
                } else {
                    proxyDetails?.parameters = nil
                }
                proxyDetails?.capabilities = capabilities
                proxyDetails?.storedFirmwareImagesListSize = slots
                
                if let statusIndex = sections.firstIndex(of: .status),
                   let capabilitiesIndex = sections.firstIndex(of: .capabilities) {
                    tableView.reloadSections(IndexSet(arrayLiteral: statusIndex, capabilitiesIndex), with: .automatic)
                }
                nextButton.isEnabled = proxyDetails?.isSupported ?? false
            } catch {
                NSLog("Error while reading distributor state: \(error)")
            }
        }
    }
    
    func readDistributionStatus(from model: Model, using applicationKey: ApplicationKey) async throws -> FirmwareDistributionStatus {
        let response = try await MeshNetworkManager.instance.send(FirmwareDistributionGet(), to: model, using: applicationKey)
        return response as! FirmwareDistributionStatus
    }
    
    func cancelDistribution(from model: Model, using applicationKey: ApplicationKey) async throws -> FirmwareDistributionPhase {
        let response = try await MeshNetworkManager.instance.send(FirmwareDistributionCancel(), to: model, using: applicationKey)
        let status = response as! FirmwareDistributionStatus
        return status.phase
    }
    
    func readCapabilities(from model: Model, using applicationKey: ApplicationKey) async throws -> ProxyDetails.Capabilities {
        let response = try await MeshNetworkManager.instance.send(FirmwareDistributionCapabilitiesGet(), to: model, using: applicationKey)
        let capabilities = response as! FirmwareDistributionCapabilitiesStatus
        return ProxyDetails.Capabilities(
            maxReceiversListSize: capabilities.maxReceiversCount,
            maxFirmwareImagesListSize: capabilities.maxFirmwareImagesListSize,
            maxFirmwareImageSize: capabilities.maxFirmwareImageSize,
            maxUploadSpace: capabilities.maxUploadSpace,
            remainingUploadSpace: capabilities.remainingUploadSpace
        )
    }
    
    enum FirmwareSlotError: LocalizedError {
        case error(status: FirmwareDistributionMessageStatus)
    }
    
    func readFirmwareImagesListSize(from model: Model, using applicationKey: ApplicationKey) async throws -> UInt16 {
        // We need to read slots one by one.
        let response = try await MeshNetworkManager.instance.send(FirmwareDistributionFirmwareGetByIndex(0), to: model, using: applicationKey)
        let status = response as! FirmwareDistributionFirmwareStatus
        guard status.status == .success else {
            switch status.status {
            case .firmwareNotFound:
                // No firmware slots available.
                return 0
            default:
                throw FirmwareSlotError.error(status: status.status)
            }
        }
        return status.entryCount
    }
    
    func deleteStoredFirmwareImages(from model: Model, using applicationKey: ApplicationKey) async throws -> UInt16 {
        let response = try await MeshNetworkManager.instance.send(FirmwareDistributionFirmwareDeleteAll(), to: model, using: applicationKey)
        let status = response as! FirmwareDistributionFirmwareStatus
        guard status.status == .success else {
            throw FirmwareSlotError.error(status: status.status)
        }
        return status.entryCount
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
                nextButton.isEnabled = proxyDetails?.isSupported ?? false
                if let index = sections.firstIndex(of: .smp) {
                    tableView.reloadSections(IndexSet(integer: index), with: .automatic)
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

