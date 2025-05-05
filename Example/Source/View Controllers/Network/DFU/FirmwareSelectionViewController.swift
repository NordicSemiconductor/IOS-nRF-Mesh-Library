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
import iOSMcuManagerLibrary

private struct Target {
    let node: Node
    var entries: FirmwareEntries
    
    var firstReceiver: FirmwareDistributionReceiversAdd.Receiver? {
        guard let address = node.models(withSigModelId: .firmwareUpdateServerModelId).first?.parentElement?.unicastAddress,
              case .ready(let entries) = entries else {
            return nil
        }
        let selectedIndex = entries.first { $0.isSelected }?.index
        return selectedIndex.map { .init(address: address, imageIndex: $0 ) }
    }
}

private enum FirmwareEntries {
    /// Model needs configuration.
    ///
    /// Application Key is not bound to the Model.
    case configurationRequired
    /// Firmware Image entries can be dowloaded.
    case configured
    /// The app is downloading Firmware Image entries and checks available updates.
    case downloading
    /// The Firmware Image entries are ready to be displayed.
    case ready(entries: [FirmwareEntry])
    /// Operation resulted with an error.
    case error(message: String)
    
    var count: Int {
        switch self {
        case .ready(let array):
            return array.count
        case .error:
            return 1
        default:
            return 0
        }
    }
    
    subscript(index: Int) -> FirmwareEntry? {
        get {
            guard case .ready(let entries) = self else {
                return nil
            }
            guard index < entries.count else {
                return nil
            }
            return entries[index]
        }
        set {
            guard case .ready(var entries) = self else {
                return
            }
            guard index < entries.count else {
                return
            }
            if let newValue = newValue {
                entries[index] = newValue
            } else {
                entries.remove(at: index)
            }
            self = .ready(entries: entries)
        }
    }
}

private struct FirmwareEntry {
    let index: UInt8
    let firmware: FirmwareInformation
    var status: Status = .unselected
    var availableUpdate: UpdatedFirmwareInformation?
    
    var isSelected: Bool {
        switch status {
        case .selected:
            return true
        default:
            return false
        }
    }
}

private enum Status: Equatable {
    case unselected
    case checkingMetadata
    case selected(additionalInformation: FirmwareUpdateAdditionalInformation)
    case notSupported
    case error(message: String)
}

class FirmwareSelectionViewController: UITableViewController {
    // MARK: - Properties
    
    var node: Node!
    var bearer: GattBearer!
    var applicationKey: ApplicationKey!
    
    /// Parsed content of the selected file.
    private var file: UpdatePackage?
    /// List of available targets.
    private var targets: [Target] = []
    
    // MARK: - Outlets
    
    @IBOutlet weak var nextButton: UIBarButtonItem!
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.sectionFooterHeight = 0
        tableView.sectionHeaderHeight = 4
        
        if let meshNetwork = MeshNetworkManager.instance.meshNetwork {
            // List only nodes that support the firmware update and blob transfer models.
            // The list may include the Distributor node itself.
            targets = meshNetwork.nodes
                .filter { node in
                    node.contains(modelWithSigModelId: .firmwareUpdateServerModelId) &&
                    node.contains(modelWithSigModelId: .blobTransferServerModelId)
                }
                .compactMap { node in
                    if let model = node.models(withSigModelId: .firmwareUpdateServerModelId).first {
                        if applicationKey.isBound(to: model) {
                            return Target(node: node, entries: .configured)
                        } else {
                            return Target(node: node, entries: .configurationRequired)
                        }
                    } else {
                        return nil
                    }
                }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Remove the PasskeyViewController from the navigation stack.
        // This is important if user wants to go "back", to skip that view..
        navigationController?.viewControllers.removeAll { $0 is PasskeyViewController }
    }
    
    // MARK: - Table View Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2 + targets.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case IndexPath.firmwareSection: return "Firmware"
        //case IndexPath.firstTargetSection: return "Available Target Nodes"
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case IndexPath.infoSection:
            return "Select a ZIP file generated when building the new firmware. " +
                   "The file can also be downloaded automatically by tapping a target node that provide a URI to an online resource with the latest version."
        case IndexPath.firmwareSection:
            return "\n\nAVAILABLE TARGET NODES\n\n" +
                   "Tap a node to view its firmware details. " +
                   "Tap an image to check firmware compatibility and select it for the update."
        case tableView.numberOfSections - 1:
            return "Note: The list contains nodes with Firmware Update Server and BLOB Transfer Server models."
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case IndexPath.infoSection: return 0
        case IndexPath.firmwareSection:
            guard let images = file?.images else {
                return 1 // Select File
            }
            return 5 + images.count // File Name, image details per image, Metadata, Company Name, Version, Select File
        default:
            return 1 + targets[section - IndexPath.firstTargetSection].entries.count // Node + list of images or an error message
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case IndexPath.firmwareSection:
            // Rows are shown in the following order:
            // If a valid file is selected:
            //   - File Name
            //   - List of images (1+)
            //   - Company Name
            //   - Version
            //   - Metadata
            // - Select File button
            guard let images = file?.images, indexPath.row <= images.count + 3 else {
                return tableView.dequeueReusableCell(withIdentifier: "selectFile", for: indexPath)
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "value", for: indexPath)
            cell.imageView?.image = nil
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "File Name"
                cell.detailTextLabel?.text = file?.name
            case let index where index < images.count + 1:
                let image = images[index - 1]
                cell.textLabel?.text = image.content.description
                cell.detailTextLabel?.text = "\(image.data.count) bytes"
                cell.imageView?.image = UIImage(systemName: "arrow.turn.down.right")
            case images.count + 1:
                cell.textLabel?.text = "Company"
                let companyIdentifier = file?.metadata.firmwareId?.companyIdentifier
                cell.detailTextLabel?.text = companyIdentifier.map { CompanyIdentifier.name(for: $0) } ?? "Unknown"
            case images.count + 2:
                cell.textLabel?.text = "Version"
                cell.detailTextLabel?.text = file?.metadata.signVersion.description ?? "Unknown"
            case images.count + 3:
                cell.textLabel?.text = "Metadata"
                cell.detailTextLabel?.text = file.map { "0x\($0.metadata.metadataString.capitalized)" } ?? "None"
            default:
                fatalError("Invalid row")
            }
            return cell
        default:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "node", for: indexPath) as! NodeViewCell
                cell.node = targets[indexPath.targetSection].node
                switch targets[indexPath.targetSection].entries {
                case .configurationRequired:
                    cell.tintColor = .systemOrange
                    cell.accessoryView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle"))
                case .downloading:
                    cell.accessoryType = .none
                    let indicator = UIActivityIndicatorView(style: .medium)
                    indicator.startAnimating()
                    cell.accessoryView = indicator
                default:
                    cell.accessoryType = .none
                    cell.accessoryView = nil
                }
                return cell
            }
            switch targets[indexPath.targetSection].entries {
            case .error(let message):
                let cell = tableView.dequeueReusableCell(withIdentifier: "error", for: indexPath)
                cell.textLabel?.text = message
                return cell
            case .ready(let entries):
                let entry = entries[indexPath.row - 1]
                let cell = tableView.dequeueReusableCell(withIdentifier: "image", for: indexPath)
                cell.textLabel?.text = "Image \(indexPath.row - 1)"
                
                let version = entry.firmware.currentFirmwareId.versionString ?? "Unknown version"
                let entryCompanyIdentifier = entry.firmware.currentFirmwareId.companyIdentifier
                let nodeCompanyIdentifier = targets[indexPath.targetSection].node.companyIdentifier
                let company = entryCompanyIdentifier == nodeCompanyIdentifier ? "" : " (\(CompanyIdentifier.name(for: entryCompanyIdentifier) ?? "Unknown manufacturer"))"
                let update = entry.availableUpdate?.manifest.firmware.firmwareId?.versionString.map { " (\($0) available)" } ?? ""
                
                let attributedText = NSMutableAttributedString(string: "Version: \(version)\(company)")
                let updateAttributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: UIColor.dynamicColor(light: .nordicLake, dark: .nordicBlue),
                ]
                let updateAttributedString = NSAttributedString(string: update, attributes: updateAttributes)
                attributedText.append(updateAttributedString)
                cell.detailTextLabel?.attributedText = attributedText
                
                switch entry.status {
                case .unselected:
                    cell.accessoryType = .none
                    cell.accessoryView = nil
                case .checkingMetadata:
                    cell.accessoryType = .none
                    let indicator = UIActivityIndicatorView(style: .medium)
                    indicator.startAnimating()
                    cell.accessoryView = indicator
                case .selected:
                    cell.accessoryType = .checkmark
                    cell.tintColor = .dynamicColor(light: .nordicLake, dark: .nordicBlue)
                    cell.accessoryView = nil
                case .notSupported, .error:
                    cell.accessoryType = .none
                    cell.tintColor = .systemRed
                    cell.accessoryView = UIImageView(image: UIImage(systemName: "xmark"))
                }
                return cell
            default:
                fatalError("Invalid target state")
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        switch indexPath.section {
        case IndexPath.infoSection:
            return false // No action
        case IndexPath.firmwareSection:
            guard let images = file?.images else {
                return true // Select File
            }
            return indexPath.row >= images.count + 3 // Copy Metadata, Select File
        default:
            switch targets[indexPath.targetSection].entries {
            case .downloading:
                return false
            case .ready(let entries):
                guard indexPath.row > 0 else {
                    return false
                }
                let entry = entries[indexPath.row - 1]
                switch entry.status {
                case .unselected:
                    // Allow selecting the image only if the Firmware ID is different.
                    return entry.firmware.currentFirmwareId != file?.metadata.firmwareId
                case .selected:
                    // Allow to unselect.
                    return true
                default:
                    // Disable when not supported, in progress or error.
                    // When error, the device row is clickable.
                    return false
                }
            case .configured, .configurationRequired, .error:
                return indexPath.row == 0
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case IndexPath.firmwareSection:
            if file?.images == nil || indexPath.row - 4 == file?.images.count { // Select File
                let supportedDocumentTypes = ["public.zip-archive", "com.pkware.zip-archive"]
                let picker = UIDocumentPickerViewController(documentTypes: supportedDocumentTypes,
                                                            in: .import)
                picker.delegate = self
                present(picker, animated: true, completion: nil)
            } else { // Copy metadata to Clipboard
                UIPasteboard.general.string = file?.metadata.metadataString
                showToast("Metadata copied to Clipboard.", delay: .shortDelay)
            }
        default:
            switch targets[indexPath.targetSection].entries {
            case .configurationRequired:
                confirm(title: "Configuration required",
                        message: "\(applicationKey!) is not bound to the Firmware Update Server model.\n\nDo you want to configure the node automatically?",
                        onCancel: nil) { _ in
                    self.targets[indexPath.targetSection].entries = .configured
                    self.tableView(tableView, didSelectRowAt: indexPath)
                }
                break
            case .error:
                targets[indexPath.targetSection].entries = .configured
                tableView.deleteRows(at: [IndexPath(row: 1, section: indexPath.section)], with: .fade)
                fallthrough
            case .configured:
                targets[indexPath.targetSection].entries = .downloading
                tableView.reloadRows(at: [indexPath], with: .none)
                Task { [indexPath] in
                    var result: FirmwareEntries
                    do {
                        let images = try await downloadFirmwareInformation(from: targets[indexPath.targetSection].node)
                        let entries = try await images.asyncMapEnumerated { [weak self] index, image in
                            let updatedFirmwareInformation = try await self?.checkForUpdates(image)
                            return FirmwareEntry(index: UInt8(index), firmware: image, availableUpdate: updatedFirmwareInformation)
                        }
                        result = .ready(entries: entries)
                    } catch {
                        result = .error(message: error.localizedDescription)
                    }
                    Task { @MainActor [indexPath, result, weak self] in
                        self?.targets[indexPath.targetSection].entries = result
                        
                        self?.tableView.beginUpdates()
                        self?.tableView.reloadRows(at: [IndexPath(row: 0, section: indexPath.section)], with: .none)
                        self?.tableView.insertRows(at: (1...result.count).map { IndexPath(row: $0, section: indexPath.section) }, with: .fade)
                        self?.tableView.endUpdates()
                    }
                }
            case .ready(let entries):
                let entry = entries[indexPath.row - 1]
                switch entry.status {
                case .unselected:
                    if let updateInformation = entry.availableUpdate,
                       let newFirmwareId = updateInformation.manifest.firmware.firmwareId,
                       file?.metadata.firmwareId != newFirmwareId {
                        targets[indexPath.targetSection].entries[indexPath.row - 1]?.status = .checkingMetadata
                        tableView.reloadRows(at: [indexPath], with: .automatic)
                        Task {
                            do {
                                let package = try await self.downloadFirmware(entry.firmware)
                                Task { @MainActor [package, weak self] in
                                    self?.targets[indexPath.targetSection].entries[indexPath.row - 1]?.status = .unselected
                                    self?.file = package
                                    self?.tableView.reloadData()
                                    self?.tableView(tableView, didSelectRowAt: indexPath)
                                }
                            } catch {
                                Task { @MainActor [weak self] in
                                    self?.targets[indexPath.targetSection].entries[indexPath.row - 1]?.status = .unselected
                                    self?.presentAlert(title: "Error",
                                                       message: "Downloading file failed.\n\n\(error.localizedDescription)")
                                }
                            }
                        }
                        return
                    }
                    guard let metadata = file?.metadata.metadata else {
                        presentAlert(title: "File not provided", message: "Before selecting an image, provide a firmware file. The image must be checked for compatibility with the embedded metadata.")
                        return
                    }
                    targets[indexPath.targetSection].entries[indexPath.row - 1]?.status = .checkingMetadata
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                    Task {
                        let imageIndex = UInt8(indexPath.row - 1)
                        var status: Status
                        do {
                            let result = try await checkCompatibility(of: imageIndex, on: targets[indexPath.targetSection].node, with: metadata)
                            let additionalInformation = try result.get()
                            status = .selected(additionalInformation: additionalInformation)
                        } catch {
                            status = .error(message: error.localizedDescription)
                        }
                        Task { @MainActor [indexPath, status, weak self] in
                            guard let self else { return }
                            self.targets[indexPath.targetSection].entries[indexPath.row - 1]?.status = status
                            self.updateNextButtonState()
                            self.tableView.reloadRows(at: [indexPath], with: .automatic)
                        }
                    }
                case .selected:
                    targets[indexPath.targetSection].entries[indexPath.row - 1]?.status = .unselected
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                    updateNextButtonState()
                default:
                    break
                }
            case .downloading:
                break
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        switch indexPath.section {
        case IndexPath.firmwareSection:
            presentAlert(title: "Firmware Information", message: "The ZIP file must contain binaries together with the 'manifest.json' and 'ble_mesh_metadata.json' files.")
        default:
            break
        }
    }
    
    private func updateNextButtonState() {
        nextButton.isEnabled = self.targets.contains { target in
            switch target.entries {
            case .ready(entries: let entries):
                return entries.contains { $0.isSelected }
            default:
                return false
            }
        }
    }

}

// MARK: - Document Picker Delegate -

extension FirmwareSelectionViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt url: [URL]) {
        
        do {
            guard let url = url.first else {
                throw McuMgrPackage.Error.notAValidDocument
            }
            let name = url.lastPathComponent
            file = try Self.extractImageFromZipFile(from: url, named: name)
        } catch {
            file = nil
            showToast("Selected file is no valid.", delay: .shortDelay)
        }
        tableView.reloadData()
    }
    
}

private extension FirmwareSelectionViewController {
    private static let manifestFileName = "manifest.json"
    private static let metadataFileName = "ble_mesh_metadata.json"
    
    static func extractImageFromZipFile(from url: URL, named name: String) throws -> UpdatePackage {
        guard let cacheDirectoryPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
            throw McuMgrPackage.Error.unableToAccessCacheDirectory
        }
        
        let unzipLocationPath = cacheDirectoryPath + "/" + UUID().uuidString + "/"
        let unzipLocationURL = URL(fileURLWithPath: unzipLocationPath, isDirectory: true)
        
        let fileManager = FileManager()
        try fileManager.createDirectory(atPath: unzipLocationPath,
                                        withIntermediateDirectories: false)
        try fileManager.unzipItem(at: url, to: unzipLocationURL)
        let unzippedURLs = try fileManager.contentsOfDirectory(at: unzipLocationURL, includingPropertiesForKeys: nil, options: [])
        defer {
            unzippedURLs.forEach { url in
                try? fileManager.removeItem(at: url)
            }
        }
        
        guard let dfuManifestURL = unzippedURLs.first(where: { $0.absoluteString.hasSuffix(FirmwareSelectionViewController.manifestFileName) }) else {
            throw McuMgrPackage.Error.manifestFileNotFound
        }
        let manifest = try McuMgrManifest(from: dfuManifestURL)
        let images = try manifest.files.compactMap { manifestFile -> ImageManager.Image in
            guard let imageURL = unzippedURLs.first(where: { $0.absoluteString.hasSuffix(manifestFile.file) }) else {
                throw McuMgrPackage.Error.manifestImageNotFound
            }
            let imageData = try Data(contentsOf: imageURL)
            let imageHash = try McuMgrImage(data: imageData).hash
            return ImageManager.Image(manifestFile, hash: imageHash, data: imageData)
        }
        
        guard let metadataURL = unzippedURLs.first(where: { $0.absoluteString.hasSuffix(FirmwareSelectionViewController.metadataFileName) }) else {
            throw McuMgrPackage.Error.manifestFileNotFound
        }
        let metadata = try Metadata.decode(from: metadataURL)
        return UpdatePackage(name: name, metadata: metadata, manifest: manifest, images: images)
    }
    
    enum ConfigurationError: LocalizedError {
        case configurationFailed(status: ConfigMessageStatus)
        
        var errorDescription: String? {
            switch self {
            case .configurationFailed(let status):
                return NSLocalizedString("Configuration failed: \(status).\nUse an Application Key that is already configured on the Target node.", comment: "dfu")
            }
        }
    }
    
    func downloadFirmwareInformation(from node: Node) async throws -> [FirmwareInformation] {
        guard let firmwareUpdateServerModel = node.models(withSigModelId: .firmwareUpdateServerModelId).first else {
            throw AccessError.invalidDestination
        }
        let manager = MeshNetworkManager.instance
        
        // Make sure the Target Node knows the selected App Key.
        if !node.knows(networkKey: applicationKey.boundNetworkKey) {
            let status = try await manager.send(ConfigNetKeyAdd(networkKey: applicationKey.boundNetworkKey), to: node) as! ConfigStatusMessage
            guard status.isSuccess else {
                throw ConfigurationError.configurationFailed(status: status.status)
            }
        }
        
        // Make sure the Target Node knows the selected App Key.
        if !node.knows(applicationKey: applicationKey) {
            let status = try await manager.send(ConfigAppKeyAdd(applicationKey: applicationKey), to: node) as! ConfigStatusMessage
            guard status.isSuccess else {
                throw ConfigurationError.configurationFailed(status: status.status)
            }
        }
        
        // Make sure the selected App Key is bound to the Firmware Update Server model.
        if !applicationKey.isBound(to: firmwareUpdateServerModel) {
            let status = try await manager.send(ConfigModelAppBind(applicationKey: applicationKey, to: firmwareUpdateServerModel)!, to: node) as! ConfigStatusMessage
            guard status.isSuccess else {
                throw ConfigurationError.configurationFailed(status: status.status)
            }
        }
        
        // Get the firmware information.
        let firmwareStatus = try await manager.send(FirmwareUpdateInformationGet(from: 0, limit: 2),
                                                    to: firmwareUpdateServerModel) as! FirmwareUpdateInformationStatus
        return firmwareStatus.list
    }
    
    enum CompatibilityCheckError: LocalizedError {
        case checkFailed(status: FirmwareUpdateMessageStatus)
        
        var errorDescription: String? {
            switch self {
            case .checkFailed(status: let status): NSLocalizedString("\(status)", comment: "dfu")
            }
        }
    }
     
    func checkCompatibility(of imageIndex: UInt8, on node: Node, with metadata: Data) async throws -> Result<FirmwareUpdateAdditionalInformation, CompatibilityCheckError> {
        guard let firmwareUpdateServerModel = node.models(withSigModelId: .firmwareUpdateServerModelId).first else {
            throw AccessError.invalidDestination
        }
        let manager = MeshNetworkManager.instance
        
        let checkStatus = try await manager.send(FirmwareUpdateFirmwareMetadataCheck(imageIndex: imageIndex, metadata: metadata),
                                                 to: firmwareUpdateServerModel) as! FirmwareUpdateFirmwareMetadataStatus
        guard checkStatus.status == .success else {
            return .failure(.checkFailed(status: checkStatus.status))
        }
        return .success(checkStatus.additionalInformation)
    }

    func checkForUpdates(_ firmwareInformation: FirmwareInformation) async throws -> UpdatedFirmwareInformation? {
        let firmwareId = firmwareInformation.currentFirmwareId.bytes
        guard let url = firmwareInformation.updateUri?
            .appending(endpoint: "check", queryItems: [URLQueryItem(name: "cfwid", value: firmwareId.hex)]) else {
            return nil
        }
        
        let urlRequest = URLRequest(url: url)
        let session = URLSession(configuration: .default, delegate: IgnoreCertificateDelegate(), delegateQueue: nil)
        let (data, response) = try await session.data(for: urlRequest)
        guard let status = response as? HTTPURLResponse else {
            NSLog("Unexpected response: \(String(describing: response))")
            // Return nil, as if no firmware update was available.
            // This will allow setting the file manually.
            return nil
        }
        guard 404 != status.statusCode else {
            // Success - no update available.
            return nil
        }
        guard (200..<299).contains(status.statusCode) else {
            // Latest firmware already present.
            NSLog("Server returned error code: %i", status.statusCode)
            return nil
        }
        // The response format is specified in the Mesh DFU specification.
        // It should be a JSON file similar to the following one:
        // {
        //   "manifest": {
        //     "firmware": {
        //       "firmware_id": "010246573A312E332E35",
        //       "dfu_chain_size": 2,
        //       "firmware_image_file_size": 196160
        //     }
        //   }
        // }
        do {
            return try JSONDecoder().decode(UpdatedFirmwareInformation.self, from: data)
        } catch {
            NSLog("Failed to decode firmware information: %@", error.localizedDescription)
            return nil
        }
    }
    
    enum DownloadError: LocalizedError {
        case unknownResponse(URLResponse?)
        case httpStatus(Int)
        
        var errorDescription: String? {
            switch self {
            case .unknownResponse(let response):
                return NSLocalizedString("Unexpected response: \(String(describing: response))", comment: "error")
            case .httpStatus(let status):
                if status == 404 {
                    return NSLocalizedString("You already have the latest version of the firmware.", comment: "error")
                }
                return NSLocalizedString("Server returned status: \(status)", comment: "error")
            }
        }
    }
    
    func downloadFirmware(_ firmwareInformation: FirmwareInformation) async throws -> UpdatePackage {
        let firmwareId = firmwareInformation.currentFirmwareId.bytes
        guard let url = firmwareInformation.updateUri?
            .appending(endpoint: "get", queryItems: [URLQueryItem(name: "cfwid", value: firmwareId.hex)]) else {
            throw DownloadError.httpStatus(404)
        }
        
        let session = URLSession(configuration: .default, delegate: IgnoreCertificateDelegate(), delegateQueue: nil)
        return try await withCheckedThrowingContinuation { continuation in
            session.downloadTask(with: url) { url, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let status = response as? HTTPURLResponse else {
                    continuation.resume(throwing: DownloadError.unknownResponse(response))
                    return
                }
                guard (200..<299).contains(status.statusCode) else {
                    // Latest firmware already present.
                    continuation.resume(throwing: DownloadError.httpStatus(status.statusCode))
                    return
                }
                do {
                    let name = response?.suggestedFilename ?? url!.lastPathComponent
                    let package = try Self.extractImageFromZipFile(from: url!, named: name)
                    continuation.resume(returning: package)
                } catch {
                    continuation.resume(throwing: error)
                }
            }.resume()
        }
    }
}

private extension IndexPath {
    static let infoSection = 0
    static let firmwareSection = 1
    static let firstTargetSection = 2
    
    var targetSection: Int {
        return section - IndexPath.firstTargetSection
    }
}

private extension Array {
    
    func asyncMapEnumerated<U>(_ transform: @escaping (Int, Element) async throws -> U) async rethrows -> [U] {
        try await withThrowingTaskGroup(of: (Int, U).self) { group in
            for (index, element) in enumerated() {
                group.addTask {
                    let result = try await transform(index, element)
                    return (index, result)
                }
            }
            
            var results = Array<U?>(repeating: nil, count: count)
            
            for try await (index, result) in group {
                results[index] = result
            }
            
            return results.compactMap { $0 }
        }
    }
    
}
