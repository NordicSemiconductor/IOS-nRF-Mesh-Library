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

class FirmwareInformationViewController: ProgressViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    var model: Model!
    var index: UInt8!
    var firmwareInformation: FirmwareInformation!
    
    private var metadataCheckStatus: FirmwareUpdateFirmwareMetadataStatus?
    private var updatedFirmwareInformation: UpdatedFirmwareInformation?
    
    private var previousMetadata: String?

    // MARK: - Table view data source
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Image \(index!)"
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3 + (metadataCheckStatus != nil ? 1 : 0)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Firmware Information"
        case 1: return "Firmware Update"
        case 2: return "Firmware Compatibility"
        case 3: return nil
        default: fatalError("Invalid section")
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2 // Company, Version
        case 1: return updatedFirmwareInformation != nil ? 5 : 1
        case 2: return 1 // Check Metadata action
        case 3: return 2 // Status, Additional Information
        default: fatalError("Invalid section")
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            // The first section contains the firmware information.
            let cell = tableView.dequeueReusableCell(withIdentifier: "value", for: indexPath)
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Company"
                cell.detailTextLabel?.text = CompanyIdentifier.name(for: firmwareInformation.currentFirmwareId.companyIdentifier) ?? "Unknown"
            case 1:
                cell.textLabel?.text = "Version"
                if firmwareInformation.currentFirmwareId.version.isEmpty {
                    cell.detailTextLabel?.text = "N/A"
                } else {
                    cell.detailTextLabel?.text = firmwareInformation.currentFirmwareId.versionString
                }
            default:
                fatalError("Invalid index")
            }
            return cell
        case 1:
            if updatedFirmwareInformation == nil {
                // The firmware update information is not available yet.
                let cell = tableView.dequeueReusableCell(withIdentifier: "updateUri", for: indexPath)
                if let updateUri = firmwareInformation.updateUri {
                    cell.detailTextLabel?.text = updateUri.absoluteString + "/check?cfwid=\(firmwareInformation.currentFirmwareId.bytes.hex)"
                } else {
                    cell.detailTextLabel?.text = "URI not provided"
                    cell.isEnabled = false
                }
                return cell
            }
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "value", for: indexPath)
                cell.textLabel?.text = "Company"
                let companyIdentifier = updatedFirmwareInformation?.manifest.firmware.firmwareId?.companyIdentifier
                cell.detailTextLabel?.text = companyIdentifier.map { CompanyIdentifier.name(for: $0) } ?? "Unknown"
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "value", for: indexPath)
                cell.textLabel?.text = "Version"
                if let version = updatedFirmwareInformation?.manifest.firmware.firmwareId?.versionString {
                    cell.detailTextLabel?.text = version
                } else {
                    cell.detailTextLabel?.text = "N/A"
                }
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "value", for: indexPath)
                cell.textLabel?.text = "DFU Chain Size"
                cell.detailTextLabel?.text = "\(updatedFirmwareInformation!.manifest.firmware.dfuChainSize)"
                return cell
            case 3:
                let cell = tableView.dequeueReusableCell(withIdentifier: "value", for: indexPath)
                cell.textLabel?.text = "Image Size"
                cell.detailTextLabel?.text = "\(updatedFirmwareInformation!.manifest.firmware.firmwareImageFileSize) bytes"
                return cell
            case 4:
                let cell = tableView.dequeueReusableCell(withIdentifier: "updateUri", for: indexPath)
                cell.textLabel?.text = "Download"
                cell.detailTextLabel?.text = firmwareInformation.updateUri!.absoluteString + "/get?cfwid=\(firmwareInformation.currentFirmwareId.bytes.hex)"
                return cell
            default: fatalError("Invalid section")
            }
        case 2:
            // The Check / Select button
            return tableView.dequeueReusableCell(withIdentifier: "check", for: indexPath)
        default: fatalError("Invalid section")
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 1:
            if indexPath.row == 0 {
                checkForUpdates()
            } else {
                downloadUpdate()
            }
        case 2:
            // Check / Select button
            presentTextAlert(title: "Compatibility Check",
                             message: "Provide Firmware Metadata.\nThe Metadata are usually generated together with the update package.",
                             text: previousMetadata,
                             placeHolder: "Hexadecimal string",
                             type: .hexRequired,
                             cancelHandler: nil) { [weak self] text in
                self?.previousMetadata = text
                let metadata = Data(hex: text)
                self?.check(metadata: metadata)
            }
        default: fatalError("Invalid section")
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return !activityIndicator.isAnimating
    }
}

private extension FirmwareInformationViewController {
    
    func checkForUpdates() {
        guard updatedFirmwareInformation == nil else { return }
        let firmwareId = firmwareInformation.currentFirmwareId.bytes
        guard let url = firmwareInformation.updateUri?
            .appending(endpoint: "check", queryItems: [URLQueryItem(name: "cfwid", value: firmwareId.hex)]) else {
            return
        }
        activityIndicator.startAnimating()
        
        let urlRequest = URLRequest(url: url)
        let session = URLSession(configuration: .default, delegate: IgnoreCertificateDelegate(), delegateQueue: nil)
        session.dataTask(with: urlRequest) { [weak self] data, response, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }
            if let error = error {
                presentAlert(title: "Error",
                             message: "Fetching firmware information failed with error:\n\(error.localizedDescription)")
                return
            }
            guard let status = response as? HTTPURLResponse else {
                presentAlert(title: "Error",
                             message: "Unexpected response received: \(String(describing: response))")
                return
            }
            guard (200..<299).contains(status.statusCode),
                  let data = data else {
                switch status.statusCode {
                case 404:
                    presentAlert(title: "Success", message: "You have the latest firmware.")
                default:
                    presentAlert(title: "Error", message: "Request returned error \(status.statusCode).")
                }
                return
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
                self.updatedFirmwareInformation = try JSONDecoder().decode(UpdatedFirmwareInformation.self, from: data)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } catch {
                presentAlert(title: "Error",
                             message: "Decoding firmware information failed with error: \(error.localizedDescription). Make sure the response is a valid JSON file.")
            }
        }.resume()
    }
 
    func downloadUpdate() {
        guard updatedFirmwareInformation != nil else { return }
        let firmwareId = firmwareInformation.currentFirmwareId.bytes
        guard let url = firmwareInformation.updateUri?
            .appending(endpoint: "get", queryItems: [URLQueryItem(name: "cfwid", value: firmwareId.hex)]) else {
            return
        }
        activityIndicator.startAnimating()
        
        let urlRequest = URLRequest(url: url)
        let session = URLSession(configuration: .default, delegate: IgnoreCertificateDelegate(), delegateQueue: nil)
        session.downloadTask(with: urlRequest) { [weak self] url, response, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }
            if let error = error {
                presentAlert(title: "Error",
                             message: "Fetching file failed with error:\n\(error.localizedDescription)")
                return
            }
            guard let status = response as? HTTPURLResponse else {
                presentAlert(title: "Error",
                             message: "Unexpected response received: \(String(describing: response))")
                return
            }
            guard (200..<299).contains(status.statusCode),
                  let url = url else {
                presentAlert(title: "Error", message: "File could not be downloaded.")
                return
            }
            do {
                let documentsURL = try FileManager.default.url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: false
                )
                let savedURL = documentsURL.appendingPathComponent(status.suggestedFilename ?? "file.zip")
                try? FileManager.default.removeItem(at: savedURL)
                try FileManager.default.moveItem(at: url, to: savedURL)
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let controller = UIActivityViewController(activityItems: [savedURL], applicationActivities: nil)
                    let rect = tableView.rectForRow(at: IndexPath(row: 4, section: 1))
                    controller.popoverPresentationController?.sourceRect = rect
                    controller.completionWithItemsHandler = { [weak self] type, success, items, error in
                        guard let self = self else { return }
                        if success {
                            self.dismiss(animated: true)
                        } else {
                            if let error = error {
                                print("Export failed: \(error)")
                                self.presentAlert(title: "Error",
                                                  message: "Saving file failed with error: \(error.localizedDescription).")
                            }
                        }
                    }
                    self.present(controller, animated: true)
                }
            } catch {
                presentAlert(title: "Error",
                             message: "Copying file failed with error: \(error.localizedDescription).")
            }
        }.resume()
    }
    
    func check(metadata: Data) {
        let message = FirmwareUpdateFirmwareMetadataCheck(imageIndex: index, metadata: metadata)
        
        start("Checking metadata...") { [model] in
            return try! MeshNetworkManager.instance.send(message, to: model!) { [weak self] result in
                self?.done { [weak self] in
                    do {
                        let status = try result.get() as! FirmwareUpdateFirmwareMetadataStatus
                        if status.status == .success {
                            var ai: String
                            switch status.additionalInformation {
                            case .deviceUnprovisioned:                     ai = "device will be unprovisioned and will need to be provisioned again."
                            case .compositionDataUnchanged:                ai = "Composition data will not change."
                            case .compositionDataChangedAndRPRSupported:   ai = "Composition data will change and Remote Provisioning will be supported."
                            case .compositionDataChangedAndRPRUnsupported: ai = "Composition data will change.\nRemote Provisioning will not be supported."
                            }
                            self?.presentAlert(title: "Success", message: "Firmware is compatible.\n\nAfter a successful update the \(ai)")
                        } else {
                            self?.presentAlert(title: "\(status.status)", message: "Firmware compatibility check failed.")
                        }
                    } catch {
                        self?.presentAlert(title: "Error", message: "\(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
}
