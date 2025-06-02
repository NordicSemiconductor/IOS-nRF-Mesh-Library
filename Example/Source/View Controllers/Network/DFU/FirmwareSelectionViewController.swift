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
    
    var isSelected: Bool {
        switch entries {
        case .ready(let entries):
            return entries.contains { $0.isSelected }
        default:
            return false
        }
    }
    
    var selectedReceiver: Receiver? {
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
    case error(message: String)
}

class FirmwareSelectionViewController: UITableViewController {
    static private let lastFileKey = "dfu_last_url"
    
    // MARK: - Properties
    
    var node: Node!
    var bearer: GattBearer!
    var applicationKey: ApplicationKey!
    var maxReceiversListSize: UInt16!
    var availableSpace: UInt32!
    
    /// Parsed content of the selected file.
    private var file: UpdatePackage?
    /// List of available targets.
    private var targets: [Target] = []
    private var canDistributorBeUpdated: Bool = false
    
    // MARK: - Outlets
    
    @IBOutlet weak var nextButton: UIBarButtonItem!
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedSectionFooterHeight = 150 // Anything non-zero works?
        tableView.sectionFooterHeight = 0
        tableView.sectionHeaderHeight = 4
        tableView.register(TargetNodesHeader.self, forHeaderFooterViewReuseIdentifier: TargetNodesHeader.reuseIdentifier)

        if let meshNetwork = MeshNetworkManager.instance.meshNetwork {
            targets = meshNetwork.nodes
                // List only nodes that support the firmware update and blob transfer models.
                .filter { node in
                    node.contains(modelWithSigModelId: .firmwareUpdateServerModelId) &&
                    node.contains(modelWithSigModelId: .blobTransferServerModelId)
                }
                // Set the initial state to .configured or .configurationRequired,
                // depending on whether the Application Key is bound to the Firmware Update Server model.
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
                // Distributor Node is the last one in the list.
                .sorted { n1, n2 in n1.node.uuid != node.uuid && n2.node.uuid != node.uuid }
            
            // The list may include the Distributor Node itself.
            // We look for it, as it gets its own header and footer.
            canDistributorBeUpdated = targets.contains { $0.node.uuid == node.uuid }
        }
        
        // To accelerate DFU process, restore the last selected file.
        if let lastUrl = UserDefaults.standard.url(forKey: Self.lastFileKey) {
            do {
                file = try Self.extractImageFromZipFile(from: lastUrl, named: lastUrl.lastPathComponent)
            } catch {
                NSLog("Error extracting image from zip file: \(error.localizedDescription)")
                UserDefaults.standard.removeObject(forKey: Self.lastFileKey)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Remove the PasskeyViewController from the navigation stack.
        // This is important if user wants to go "back", to skip that view..
        navigationController?.viewControllers.removeAll { $0 is PasskeyViewController }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "next":
            let destination = segue.destination as! DFUParametersViewController
            destination.distributor = node
            destination.bearer = bearer
            destination.applicationKey = applicationKey
            destination.receivers = targets.selectedReceivers
            destination.updatePackage = file
        default:
            break
        }
    }
    
    // MARK: - Table View Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2 + targets.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case IndexPath.firmwareSection: return "Firmware"
        case targets.count + 1 where canDistributorBeUpdated: return "Distributor"
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case IndexPath.infoSection:
            return "Select a ZIP file generated when building the new firmware. " +
                   "The file can also be downloaded automatically by tapping a target node that provide a URI to an online resource with the latest version."
        case targets.count where canDistributorBeUpdated,
             targets.count + 1 where !canDistributorBeUpdated:
            return "Note: The list contains nodes with Firmware Update Server and BLOB Transfer Server models."
        case targets.count + 1 where canDistributorBeUpdated:
            return "Updating firmware on the distributor is instantaneous. When selected, no other nodes will be updated."
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
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == IndexPath.firmwareSection {
            let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: TargetNodesHeader.reuseIdentifier) as! TargetNodesHeader
            footer.availableSpace = Int(availableSpace!)
            footer.button.isEnabled = file?.images.first?.data.count ?? Int.max <= availableSpace
            footer.button.addTarget(self, action: #selector(selectAllTargets), for: .touchUpInside)
            return footer
        }
        return nil
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
                let cell = tableView.dequeueReusableCell(withIdentifier: "selectFile", for: indexPath)
                cell.textLabel?.text = file == nil ? "Select File" : "Change file"
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "value", for: indexPath)
            cell.imageView?.image = nil
            cell.accessoryView = nil
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "File Name"
                cell.detailTextLabel?.text = file?.name
            case let index where index < images.count + 1:
                let image = images[index - 1]
                cell.textLabel?.text = image.content.description
                cell.detailTextLabel?.text = "\(image.data.count) bytes"
                cell.imageView?.image = UIImage(systemName: "arrow.turn.down.right")
                // Add X symbol if the image size is larger than available space.
                // The "Next" button will be disabled in this case.
                if image.data.count > availableSpace {
                    let x = UIImageView(image: UIImage(systemName: "xmark"))
                    x.tintColor = .systemRed
                    cell.accessoryView = x
                }
            // TODO: Currently we support only one image, with one FirmwareID and one Metadata. This will change in the future.
            case images.count + 1:
                cell.textLabel?.text = "Company"
                let companyIdentifier = file?.metadata.firmwareId?.companyIdentifier
                cell.detailTextLabel?.text = companyIdentifier.map { CompanyIdentifier.name(for: $0) } ?? "Unknown"
            case images.count + 2:
                cell.textLabel?.text = "Version"
                cell.detailTextLabel?.text = file?.metadata.signVersion.description ?? "Unknown"
            case images.count + 3:
                cell.textLabel?.text = "Metadata"
                cell.detailTextLabel?.text = file?.metadata.metadataString.map { "0x\($0.capitalized)" } ?? "None"
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
                case .error:
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
                case .error:
                    return entry.availableUpdate != nil && entry.availableUpdate?.manifest.firmware.firmwareId != file?.metadata.firmwareId
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
                    targets[indexPath.targetSection].entries = result
                        
                    tableView.beginUpdates()
                    tableView.reloadRows(at: [IndexPath(row: 0, section: indexPath.section)], with: .none)
                    tableView.insertRows(at: (1...result.count).map { IndexPath(row: $0, section: indexPath.section) }, with: .fade)
                    tableView.endUpdates()
                }
            case .ready(let entries):
                let entry = entries[indexPath.row - 1]
                switch entry.status {
                case .unselected, .error:
                    let download = { [weak self] in
                        guard let self else { return }
                        do {
                            let package = try await self.downloadFirmware(entry.firmware)
                            // It may happen, that the downloaded image has different metadata than what we got during "check".
                            // To avoid downloading the image in a loop, we need to update the metadata.
                            self.targets[indexPath.targetSection].entries[indexPath.row - 1]?.availableUpdate?.manifest.firmware.firmwareIdString = package.metadata.firmwareIdString
                            // Clear all selections, as we have a new image.
                            self.targets.clearSelections()
                            self.nextButton.isEnabled = false
                            // Update the file information.
                            self.file = package
                            self.tableView.beginUpdates()
                            self.tableView.reloadSections(IndexSet(integer: IndexPath.firmwareSection), with: .automatic)
                            self.tableView.reloadSections(IndexSet(integersIn: IndexPath.firstTargetSection..<self.targets.count + IndexPath.firstTargetSection), with: .none)
                            self.tableView.endUpdates()
                            self.tableView(tableView, didSelectRowAt: indexPath)
                        } catch {
                            self.targets[indexPath.targetSection].entries[indexPath.row - 1]?.status = .unselected
                            self.presentAlert(title: "Error",
                                               message: "Downloading file failed.\n\n\(error.localizedDescription)")
                        }
                    }
                    
                    // Does the Image provide a URI to a new version?
                    if let updateInformation = entry.availableUpdate,
                       let newFirmwareId = updateInformation.manifest.firmware.firmwareId {
                        targets[indexPath.targetSection].entries[indexPath.row - 1]?.status = .checkingMetadata
                        tableView.reloadRows(at: [indexPath], with: .automatic)
                        
                        // Check if the provided firmwareId is different than the one we already have.
                        if let selectedFirmwareId = file?.metadata.firmwareId {
                            if selectedFirmwareId != newFirmwareId {
                                let downloadAction = UIAlertAction(title: "Override", style: .destructive) { _ in
                                    Task {
                                        await download()
                                    }
                                }
                                presentAlert(title: "Override selected firmware?",
                                             message: "This image provides a URI to a new firmware version.\n\nDo you want to try to download it and replace the selected one?",
                                             cancelable: true,
                                             option: downloadAction) { [weak self] _ in
                                    self?.tableView(tableView, didSelectRowAt: indexPath)
                                }
                                return
                            }
                        } else {
                            // No file was selected, so we can safely download the new version.
                            Task {
                                await download()
                            }
                            return
                        }
                    }
                    fallthrough
                case .checkingMetadata:
                    guard let metadata = file?.metadata.metadata else {
                        presentAlert(title: "File not provided",
                                     message: "Before selecting an image, provide a firmware file. The image must be checked for compatibility with the embedded metadata.")
                        return
                    }
                    guard targets.selectedReceivers.count < maxReceiversListSize else {
                        presentAlert(title: "Limit reached",
                                     message: "The distributor can update a maximum of \(maxReceiversListSize!) targets in a single operation.")
                        return
                    }
                    targets[indexPath.targetSection].entries[indexPath.row - 1]?.status = .checkingMetadata
                    tableView.reloadRows(at: [indexPath], with: .none)
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
                        targets[indexPath.targetSection].entries[indexPath.row - 1]?.status = status
                        updateNextButtonState()
                        tableView.reloadRows(at: [indexPath], with: .none)
                    }
                case .selected:
                    targets[indexPath.targetSection].entries[indexPath.row - 1]?.status = .unselected
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                    updateNextButtonState()
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
        nextButton.isEnabled = !targets.selectedReceivers.isEmpty &&
                               file?.images.first?.data.count ?? Int.max <= availableSpace
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
            
            // Clear all selections, as we have a new image.
            targets.clearSelections()
            nextButton.isEnabled = false
        } catch {
            file = nil
            showToast("Selected file is not valid. \(error.localizedDescription)", delay: .shortDelay)
        }
        tableView.beginUpdates()
        tableView.reloadSections(IndexSet(integer: IndexPath.firmwareSection), with: .automatic)
        tableView.reloadSections(IndexSet(integersIn: IndexPath.firstTargetSection..<targets.count + IndexPath.firstTargetSection), with: .none)
        tableView.endUpdates()
    }
    
}

// MARK: - Implementation

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
        guard metadata.binarySize == images.first?.data.count else {
            throw McuMgrPackage.Error.notAValidDocument
        }
        
        // Store the last successful URL in UserDefaults.
        UserDefaults.standard.set(url, forKey: lastFileKey)
        
        return UpdatePackage(name: name, metadata: metadata, manifest: manifest, images: images)
    }
    
    /// This method goes through all targets and selects first image entry that passes the checks.
    @objc func selectAllTargets() {
        guard let metadata = file?.metadata.metadata else {
            return
        }
        Task {
            /// Number of selected receivers. This must be less or equal to `maxReceiversListSize`.
            var selectedCount = targets.selectedReceivers.count
            /// Target index.
            var i = -1
            
            // Go through all targets and select first image that passes the checks.
            for target in targets {
                i += 1
                // Abort if the maximum number of selected receivers is reached.
                guard selectedCount < maxReceiversListSize else {
                    break
                }
                // Skip the Distributor Node.
                guard target.node.uuid != node.uuid else {
                    continue
                }
                // Skip already selected Nodes.
                guard !target.isSelected else {
                    continue
                }
                switch target.entries {
                // Target Nodes will be automatically configured.
                case .configurationRequired, .configured:
                    targets[i].entries = .downloading
                    tableView.reloadRows(at: [IndexPath(row: 0, section: IndexPath.firstTargetSection + i)], with: .none)
                    do {
                        let images = try await downloadFirmwareInformation(from: target.node)
                        let entries = try await images.asyncMapEnumerated { [weak self] index, image in
                            let updatedFirmwareInformation = try await self?.checkForUpdates(image)
                            return FirmwareEntry(index: UInt8(index), firmware: image, availableUpdate: updatedFirmwareInformation)
                        }
                        targets[i].entries = .ready(entries: entries)
                    } catch {
                        targets[i].entries = .error(message: error.localizedDescription)
                    }
                    tableView.beginUpdates()
                    tableView.reloadRows(at: [IndexPath(row: 0, section: IndexPath.firstTargetSection + i)], with: .none)
                    tableView.insertRows(at: (1...targets[i].entries.count).map { IndexPath(row: $0, section: IndexPath.firstTargetSection + i) }, with: .fade)
                    tableView.endUpdates()
                    fallthrough
                case .ready:
                    // Note, that we might have ended up here from the previous case (fall through).
                    // We can't use 'let' in the case statement. Also, the 'entries' can be .error,
                    // so check it and continue only if entries are ready.
                    guard case .ready(let entries) = targets[i].entries else {
                        continue
                    }
                    var imageIndex = -1
                    for entry in entries {
                        imageIndex += 1
                        // Skip images that have the same version as the selected one.
                        if entry.firmware.currentFirmwareId == file?.metadata.firmwareId {
                            continue
                        }
                        /// A flag to indicate if the image was selected.
                        var selected = false
                        targets[i].entries[imageIndex]?.status = .checkingMetadata
                        tableView.reloadRows(at: [IndexPath(row: imageIndex + 1, section: IndexPath.firstTargetSection + i)], with: .none)
                        do {
                            let result = try await checkCompatibility(of: entry.index, on: target.node, with: metadata)
                            let additionalInformation = try result.get()
                            targets[i].entries[imageIndex]?.status = .selected(additionalInformation: additionalInformation)
                            selectedCount += 1
                            selected = true
                            updateNextButtonState()
                        } catch {
                            targets[i].entries[imageIndex]?.status = .error(message: error.localizedDescription)
                        }
                        tableView.reloadRows(at: [IndexPath(row: imageIndex + 1, section: IndexPath.firstTargetSection + i)], with: .none)
                        
                        // Only one image per Node can be selected.
                        if selected { break }
                    }
                case .error, .downloading:
                    // Ignore.
                    continue
                }
            }
        }
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
        
        do {
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

// MARK: - Utils

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

private extension Array where Element == Target {
    
    var selectedReceivers: [Receiver] {
        return compactMap { target in target.selectedReceiver }
    }
    
    mutating func clearSelections() {
        for index in 0..<count {
            switch self[index].entries {
            case .ready(var entries):
                for i in 0..<entries.count {
                    entries[i].status = .unselected
                }
                self[index].entries = .ready(entries: entries)
            default:
                break
            }
        }
    }
                
}

class TargetNodesHeader: UITableViewHeaderFooterView {
    static let reuseIdentifier = "FirmwareHeaderView"
        
    private let spaceLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "AVAILABLE TARGET NODES"
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    let button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Select All", for: .normal)
        button.isEnabled = false
        return button
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.text = """
        Tap a node to view its firmware details.
        Tap an image to check firmware compatibility and select it for the update.
        """
        return label
    }()
    
    var availableSpace: Int? {
        didSet {
            spaceLabel.text = "Maximum available space is \(availableSpace ?? 0) bytes."
        }
    }

    // MARK: - Initializer
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - View Setup
    
    private func setupView() {
        contentView.backgroundColor = .systemGroupedBackground
        
        let titleRow = UIStackView(arrangedSubviews: [titleLabel, button])
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.distribution = .equalSpacing

        let mainStack = UIStackView(arrangedSubviews: [spaceLabel, titleRow, descriptionLabel])
        mainStack.axis = .vertical
        mainStack.spacing = 16
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
}
