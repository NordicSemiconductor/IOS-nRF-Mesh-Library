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
import os.log
import NordicMesh
import iOSMcuManagerLibrary

class DFUViewController: UIViewController,
                         UIAdaptivePresentationControllerDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var statusView: UILabel!
    @IBOutlet weak var progress: UIProgressView!
    
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var remainingTime: UILabel!
    
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true)
    }
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        // TODO: Cancel distribution
        imageManager?.cancelUpload()
    }
    
    // MARK: - Properties
    
    var distributor: Node!
    var bearer: GattBearer!
    var receivers: [Receiver]!
    var updatePackage: UpdatePackage!
    var parameters: DFUParameters!
    
    // MARK: - Private Properties
    
    private var inProgress: Bool = true {
        didSet {
            if !inProgress {
                navigationItem.rightBarButtonItem?.isEnabled = true
                navigationItem.leftBarButtonItem?.isEnabled = false
                remainingTime.isHidden = true
            }
        }
    }
    
    private var shellManager: ShellManager?
    private var osManager: DefaultManager?
    private var imageManager: ImageManager?
    private var uploadProgress = 0
    private var uploadSpeed: Float = 0
    private var uploadStartTime: Date?
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make the dialog modal (non-dismissible).
        navigationController?.presentationController?.delegate = self
        // Disable Done button until the upload is complete.
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        tableView.delegate = self
        tableView.dataSource = self
        
        guard let image = updatePackage?.images.first else {
            statusView.text = "No images available"
            inProgress = false
            return
        }
        
        let firmwareId = updatePackage.metadata.firmwareIdString
        let metadata = updatePackage.metadata.metadataString.map { " \($0)" } ?? ""
        
        // To upload the image for the Distributor, we will use McuManager
        // from nRF Connect Device Manager library.
        // Comparing to BLOB upload, this is much faster.
        // Uploaded image will be distributed to the Target Nodes using BLOB messages
        // by the Distributor.
        let transport = McuMgrBleTransport(bearer.identifier)
        
        // First, create a new slot for the image.
        statusView.text = "Creating slot..."
        shellManager = ShellManager(transport: transport)
        shellManager!.logDelegate = self
        shellManager!.execute(command: "mesh models dfu slot add \(image.data.count) \(firmwareId)\(metadata)") { [weak self] response, error in
            // Returned response has the following format:
            //
            //    Adding slot (size: <Size>)
            //
            //    Slot added. Index: <Index>
            //
            // We need to get the Image Index from the response.
            if let text = response?.output,
               let match = text.range(of: #"Index:\s*(\d+)"#, options: .regularExpression),
               let number = Int(String(text[match]).components(separatedBy: ":").last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") {
                print("Extracted index: \(number)")
                
                // Read MCU Manager parameters to get the buffer size and count.
                // These can be used to speed up the upload.
                self?.statusView.text = "Reading parameters..."
                self?.osManager = DefaultManager(transport: transport)
                self?.osManager!.logDelegate = self
                self?.osManager!.params { [weak self] response, error in
                    let config = response.map { params in
                        FirmwareUpgradeConfiguration(
                            pipelineDepth: params.bufferCount.map { Int($0) - 1 } ?? 0,
                            byteAlignment: .disabled,
                            reassemblyBufferSize: params.bufferSize
                        )
                    } ?? FirmwareUpgradeConfiguration(
                            pipelineDepth: 3,
                            byteAlignment: .disabled
                         )
                    
                    self?.statusView.text = "Uploading image..."
                    self?.imageManager = ImageManager(transport: transport)
                    self?.imageManager!.logDelegate = self
                    _ = self?.imageManager!.upload(images: [image], using: config, delegate: self)
                }
            } else {
                self?.statusView.text = "Failed to add slot"
                self?.inProgress = false
                return
            }
        }
    }
}

extension DFUViewController: UITableViewDataSource, UITableViewDelegate {
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // Allow dismiss only when all tasks are complete.
        return !inProgress
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        guard updatePackage != nil && updatePackage.images.count > 0 && receivers.count > 0 else {
            return 0
        }
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1 // Upload cell
        case 1:
            return receivers.count // A row per Receiver
        default:
            fatalError("Invalid section")
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Upload Progress"
        case 1:
            return "Distribution Progress"
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "upload", for: indexPath) as! UploadProgressViewCell
            cell.percentage = uploadProgress
            cell.speedBytesPerSecond = uploadSpeed
            cell.accessoryType = uploadProgress == 100 ? .checkmark : .none
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "node", for: indexPath) as! NodeProgressViewCell
            
            let node = MeshNetworkManager.instance.meshNetwork?.node(withAddress: receivers[indexPath.row].address)
            cell.node = node
            cell.percentage = (indexPath.row + 1) * 50
            cell.speedBytesPerSecond = Float(indexPath.row + 2) * 2.3
            return cell
        default:
            fatalError("Invalid section")
        }
    }

}

extension DFUViewController: McuMgrLogDelegate {
    
    func log(_ message: String, ofCategory category: McuMgrLogCategory, atLevel level: McuMgrLogLevel) {
        os_log("%{public}@", log: category.log, type: level.type, message)
    }
    
    func minLogLevel() -> McuMgrLogLevel {
        return .verbose
    }
    
}

extension McuMgrLogLevel {
    
    /// Mapping from mesh log levels to system log types.
    var type: OSLogType {
        switch self {
        case .debug:       return .debug
        case .verbose:     return .debug
        case .info:        return .info
        case .application: return .default
        case .warning:     return .error
        case .error:       return .fault
        }
    }
    
}

extension McuMgrLogCategory {
    
    var log: OSLog {
        return OSLog(subsystem: Bundle.main.bundleIdentifier!, category: rawValue)
    }
    
}

extension DFUViewController: ImageUploadDelegate {
    
    func uploadProgressDidChange(bytesSent: Int, imageSize: Int, timestamp: Date) {
        uploadProgress = bytesSent * 100 / imageSize // percentage
        uploadStartTime = uploadStartTime ?? timestamp
        if bytesSent > 0 {
            uploadSpeed = Float(bytesSent) / Float(timestamp.timeIntervalSince(uploadStartTime!))
        }
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
    }
    
    func uploadDidFail(with error: any Error) {
        statusView.text = error.localizedDescription
        inProgress = false
    }
    
    func uploadDidCancel() {
        navigationController?.dismiss(animated: true)
    }
    
    func uploadDidFinish() {
        uploadProgress = 100
        statusView.text = "Starting distribution..."
        imageManager?.transport.close()
        imageManager = nil
        osManager = nil
        shellManager = nil
    }
    
}
