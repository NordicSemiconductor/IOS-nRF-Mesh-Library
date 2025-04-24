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

// Useful links:
// https://docs.nordicsemi.com/bundle/ncs-latest/page/nrf/protocols/bt/bt_mesh/dfu_over_bt_mesh.html
// Source code for DFU Metadata:
// https://github.com/nrfconnect/sdk-zephyr/blob/main/include/zephyr/bluetooth/mesh/dfu_metadata.h
private struct Metadata: Codable {
    
    struct Version: Codable, CustomStringConvertible {
        let major: UInt8
        let minor: UInt8
        let revision: UInt16
        let build: UInt32
        
        enum CodingKeys: String, CodingKey {
            case major
            case minor
            case revision
            case build = "build_number"
        }
        
        var description: String {
            return "\(major).\(minor).\(revision)+\(build)"
        }
    }
    
    let signVersion: Version
    let binarySize: UInt32 // 24 bit
    let coreType: UInt8
    let compositionDataHash: UInt32
    let metadataString: String
    let firmwareIdString: String
    
    var metadata: Data {
        return Data(hex: metadataString)
    }
    var firmwareId: FirmwareId? {
        let data = Data(hex: firmwareIdString)
        return FirmwareId(data: data)
    }
    
    enum CodingKeys: String, CodingKey {
        case signVersion = "sign_version"
        case binarySize = "binary_size"
        case coreType = "core_type"
        case compositionDataHash = "composition_hash"
        case metadataString = "encoded_metadata"
        case firmwareIdString = "firmware_id"
    }
    
    static func decode(from url: URL) throws -> Metadata {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let metadata = try decoder.decode(Metadata.self, from: data)
        return metadata
    }
}

private struct Target {
    let node: Node
    var images: FirmwareEntries = .none
}

private enum FirmwareEntries {
    case none
    case downloading
    case error(Error)
    case ready([FirmwareEntry])
    
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
}

private struct FirmwareEntry {
    let firmware: FirmwareInformation
    var status: Status = .unselected
}

private enum Status {
    case unselected
    case checkingMetadata
    case supported(additionalInformation: FirmwareUpdateAdditionalInformation)
    case notSupported
}

class FirmwareSelectionViewController: UITableViewController {
    // MARK: - Properties
    
    var node: Node!
    var bearer: GattBearer!
    
    /// Selected file name.
    private var fileName: String?
    /// Mesh DFU Metadata of the selected firmware.
    private var metadata: Metadata?
    /// MCU Manager Manifest of the selected firmware.
    private var manifest: McuMgrManifest?
    /// Firmware images.
    private var images: [ImageManager.Image]?
    /// List of available targets.
    private var targets: [Target] = []
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.sectionFooterHeight = 0
        tableView.sectionHeaderHeight = 4
        
        if let meshNetwork = MeshNetworkManager.instance.meshNetwork {
            // List only nodes that support the firmware update and blob transfer models.
            // The list may include the Distributor node itself.
            targets = meshNetwork.nodes
                .filter {
                    $0.contains(modelWithSigModelId: .firmwareUpdateServerModelId) &&
                    $0.contains(modelWithSigModelId: .blobTransferServerModelId)
                }
                .map { Target(node: $0) }
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
        case IndexPath.firstTargetSection: return "Available Target Nodes"
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case IndexPath.infoSection: return "Select a ZIP file generated when building the firmware update."
        case IndexPath.firmwareSection:
            return "The firmware can be also downloaded automatically from nodes that provide a URI pointing to it. " +
                   "If an update is available a button will appear below.\n\n" +
                   "Tap a node below to get its firmware information. " +
                   "Tap an image to check its compatibility and select for update."
        case tableView.numberOfSections - 1:
            return "The list contains nodes with Firmware Update Server and BLOB Transfer Server models."
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case IndexPath.infoSection: return 0
        case IndexPath.firmwareSection:
            guard let images = images else {
                return 1 // Select File
            }
            return 5 + images.count // File Name, image details per image, Metadata, Company Name, Version, Select File
        default:
            return 1 + targets[section - IndexPath.firstTargetSection].images.count // Node + list of images or an error message
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
            guard let images = images, indexPath.row <= images.count + 3 else {
                return tableView.dequeueReusableCell(withIdentifier: "selectFile", for: indexPath)
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: "value", for: indexPath)
            cell.imageView?.image = nil
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "File Name"
                cell.detailTextLabel?.text = fileName
            case let index where index < images.count + 1:
                let image = images[index - 1]
                cell.textLabel?.text = image.content.description
                cell.detailTextLabel?.text = "\(image.data.count) bytes"
                cell.imageView?.image = UIImage(systemName: "arrow.turn.down.right")
            case images.count + 1:
                cell.textLabel?.text = "Company"
                let companyIdentifier = metadata?.firmwareId?.companyIdentifier
                cell.detailTextLabel?.text = companyIdentifier.map { CompanyIdentifier.name(for: $0) } ?? "Unknown"
            case images.count + 2:
                cell.textLabel?.text = "Version"
                cell.detailTextLabel?.text = metadata?.signVersion.description ?? "Unknown"
            case images.count + 3:
                cell.textLabel?.text = "Metadata"
                cell.detailTextLabel?.text = metadata.map { "0x\($0.metadataString.capitalized)" } ?? "None"
            default:
                fatalError("Invalid row")
            }
            return cell
        default:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "node", for: indexPath) as! NodeViewCell
                cell.node = targets[indexPath.targetSection].node
                switch targets[indexPath.targetSection].images {
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
            switch targets[indexPath.targetSection].images {
            case .error(let error):
                let cell = tableView.dequeueReusableCell(withIdentifier: "error", for: indexPath)
                cell.textLabel?.text = error.localizedDescription
                return cell
            case .ready(let entries):
                let entry = entries[indexPath.row - 1]
                let cell = tableView.dequeueReusableCell(withIdentifier: "image", for: indexPath)
                cell.textLabel?.text = "Image \(indexPath.row - 1)"
                let version = entry.firmware.currentFirmwareId.versionString ?? "Unknown version"
                let entryCompanyIdentifier = entry.firmware.currentFirmwareId.companyIdentifier
                let nodeCompanyIdentifier = targets[indexPath.targetSection].node.companyIdentifier
                let company = entryCompanyIdentifier == nodeCompanyIdentifier ? "" : " (\(CompanyIdentifier.name(for: entryCompanyIdentifier) ?? "Unknown manufacturer"))"
                cell.detailTextLabel?.text = "Version: \(version)\(company)"
                switch entry.status {
                case .unselected:
                    cell.accessoryType = .none
                    cell.accessoryView = nil
                case .checkingMetadata:
                    cell.accessoryType = .none
                    let indicator = UIActivityIndicatorView(style: .medium)
                    indicator.startAnimating()
                    cell.accessoryView = indicator
                case .supported(additionalInformation: let additionalInformation):
                    cell.accessoryType = .checkmark
                    cell.tintColor = .dynamicColor(light: .nordicLake, dark: .nordicBlue)
                    cell.accessoryView = nil
                case .notSupported:
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
            guard let images = images else {
                return true // Select File
            }
            return indexPath.row >= images.count + 3 // Copy Metadata, Select File
        default:
            switch targets[indexPath.targetSection].images {
            case .ready, .downloading:
                return false
            case .none, .error:
                return indexPath.row == 0
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("AAA Selected row: \(indexPath)")
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case IndexPath.firmwareSection:
            if images == nil || indexPath.row - 4 == images?.count { // Select File
                let supportedDocumentTypes = ["public.zip-archive", "com.pkware.zip-archive"]
                let picker = UIDocumentPickerViewController(documentTypes: supportedDocumentTypes,
                                                            in: .import)
                picker.delegate = self
                present(picker, animated: true, completion: nil)
            } else { // Copy metadata to Clipboard
                UIPasteboard.general.string = metadata?.metadataString
                showToast("Metadata copied to Clipboard.", delay: .shortDelay)
            }
        default:
            switch targets[indexPath.targetSection].images {
            case .error:
                targets[indexPath.targetSection].images = .none
                tableView.deleteRows(at: [IndexPath(row: 1, section: indexPath.section)], with: .fade)
                fallthrough
            case .none:
                targets[indexPath.targetSection].images = .downloading
                tableView.reloadRows(at: [indexPath], with: .none)
                Task { [indexPath] in
                    var result: FirmwareEntries
                    do {
                        let images = try await downloadFirmwareInformation(from: targets[indexPath.targetSection].node)
                        result = .ready(images.map { FirmwareEntry(firmware: $0) })
                    } catch {
                        result = .error(error)
                    }
                    Task { @MainActor [indexPath, result, weak self] in
                        self?.targets[indexPath.targetSection].images = result
                        
                        self?.tableView.beginUpdates()
                        self?.tableView.reloadRows(at: [IndexPath(row: 0, section: indexPath.section)], with: .none)
                        self?.tableView.insertRows(at: (1...result.count).map { IndexPath(row: $0, section: indexPath.section) }, with: .fade)
                        self?.tableView.endUpdates()
                    }
                }
            case .ready, .downloading:
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

}

// MARK: - Document Picker Delegate -

extension FirmwareSelectionViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt url: [URL]) {
        
        do {
            guard let url = url.first else {
                throw McuMgrPackage.Error.notAValidDocument
            }
            fileName = url.lastPathComponent
            try extractImageFromZipFile(from: url)
        } catch {
            metadata = nil
            manifest = nil
            images = nil
            showToast("Selected file is no valid.", delay: .shortDelay)
        }
        tableView.reloadData()
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Cancelled")
    }
    
}

private extension FirmwareSelectionViewController {
    private static let manifestFileName = "manifest.json"
    private static let metadataFileName = "ble_mesh_metadata.json"
    
    func extractImageFromZipFile(from url: URL) throws {
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
        
        guard let dfuManifestURL = unzippedURLs.first(where: { $0.absoluteString.hasSuffix(FirmwareSelectionViewController.manifestFileName) }) else {
            throw McuMgrPackage.Error.manifestFileNotFound
        }
        manifest = try McuMgrManifest(from: dfuManifestURL)
        images = try manifest!.files.compactMap { manifestFile -> ImageManager.Image in
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
        metadata = try Metadata.decode(from: metadataURL)
        
        // Clean up.
        try unzippedURLs.forEach { url in
            try fileManager.removeItem(at: url)
        }
    }
    
    enum ValidationError: Error {
        case invalidMetadata
        case serverUpdateModelNotFound
        case fail(status: FirmwareUpdateMessageStatus)
        case wrongPhase(phase: FirmwareUpdatePhase)
        case notCompatible
    }
    
    func downloadFirmwareInformation(from node: Node) async throws -> [FirmwareInformation] {
//        guard let metadata = metadata?.metadata else {
//            throw ValidationError.invalidMetadata
//        }
        guard let firmwareUpdateServerModel = node.models(withSigModelId: .firmwareUpdateServerModelId).first else {
            throw ValidationError.serverUpdateModelNotFound
        }
        let manager = MeshNetworkManager.instance
        
        // Get the firmware information.
        let firmwareStatus = try await manager.send(FirmwareUpdateInformationGet(from: 0, limit: 10), to: firmwareUpdateServerModel) as! FirmwareUpdateInformationStatus
        return firmwareStatus.list
        
        // Check if the Node is ready to receive a firmware update.
//        let status = try await manager.send(FirmwareUpdateGet(), to: firmwareUpdateServerModel) as! FirmwareUpdateStatus
//        guard status.status == .success else {
//            throw ValidationError.fail(status: status.status)
//        }
//        guard status.updatePhase.canStart else {
//            throw ValidationError.wrongPhase(phase: status.updatePhase)
//        }
//        
//        // Check firmware information.
//        let firmwareStatus = try await manager.send(FirmwareUpdateInformationGet(), to: firmwareUpdateServerModel) as! FirmwareUpdateInformationStatus
//        for i in 0..<firmwareStatus.totalCount {
//            let checkStatus = try await manager.send(FirmwareUpdateFirmwareMetadataCheck(imageIndex: i, metadata: metadata), to: firmwareUpdateServerModel) as! FirmwareUpdateFirmwareMetadataStatus
//            if checkStatus.status == .success {
//                return (checkStatus.imageIndex, checkStatus.additionalInformation)
//            }
//        }
//        throw ValidationError.notCompatible
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
