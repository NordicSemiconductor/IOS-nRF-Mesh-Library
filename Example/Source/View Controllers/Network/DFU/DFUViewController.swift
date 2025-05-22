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


private enum ReceiverStatus {
    case idle
    case distribution(progress: Int, speedBytesPerSecond: Float)
    case verified
    case applied
    case failure
    
    var progress: Int {
        switch self {
        case .idle: return -1
        case .distribution(let progress, _): return progress
        case .verified: return 100
        case .applied: return 100
        case .failure: return 0
        }
    }
}

/// Upload progress structure.
private struct UploadProgress {
    /// Upload progress, in range 0-1.
    let progress: Float
    /// Upload speed in bytes per second.
    let speedBytesPerSecond: Float
}

class DFUViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var statusView: UILabel!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var remainingTime: UILabel!
    
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        // If upload is in progress, tapping Done button
        // will just close the view controller.
        // Distribution will be continued in the background.
        inProgress = false // Stops the timer
        navigationController?.dismiss(animated: true)
    }
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        // If the upload or distribution is in progress, cancel the task.
        if let dfuTask = dfuTask {
            dfuTask.cancel()
            return
        }
        // If the upload has completed, but Distributor awaits Apply command, send Cancel command.
        if !inProgress{
            Task {
                let status = try await distributor.cancelDistribution()
                if status.status == .success {
                    navigationController?.dismiss(animated: true)
                } else {
                    statusView.text = "\(status.status)"
                }
            }
            return
        }
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
    
    private var dfuTask: Task<Void, Error>?
    private var uploadProgress: UploadProgress? {
        didSet {
            estimateTime()
        }
    }
    private var distributionProgress: [ReceiverStatus]!
    private var estimatedTotalTime: TimeInterval!
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make the dialog modal (non-dismissible) if update is in progress.
        navigationController?.presentationController?.delegate = self
        // Disable Done button until the image is sent to the Distributor.
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
        
        // Initialize the distribution progress list.
        // The list will be updated with the progress of each receiver.
        distributionProgress = receivers.map { _ in .idle }
        
        // Calculate the estimated time for the upload.
        estimateTime()
        
        // Start the timer.
        Task {
            let start = Date()
            while inProgress {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                // Make sure the upload is still in progress.
                guard inProgress else { break }
                
                // Update the timer for the elapsed time.
                let elapsedTime = -start.timeIntervalSinceNow
                let minutes = floor(elapsedTime / 60)
                let seconds = floor(elapsedTime - minutes * 60)
                time.text = String(format: "%02d:%02d", Int(minutes), Int(seconds))
                
                // Update the remaining time.
                let eta = estimatedTotalTime - elapsedTime
                if eta > 0 {
                    let remainingMinutes = floor(eta / 60)
                    let remainingSeconds = floor(eta - remainingMinutes * 60)
                    remainingTime.text = String(format: "%02d:%02d", Int(remainingMinutes), Int(remainingSeconds))
                    
                    let currentProgress = elapsedTime / estimatedTotalTime
                    progress.setProgress(Float(currentProgress), animated: true)
                } else {
                    // Hehe, we're not actually recalculating anything.
                    // The Distributor got stuck and retry in a bit.
                    // We should be getting a new progress report eventually
                    // which will recalculate the speed and remaining time.
                    remainingTime.text = "Recalculating..."
                }
            }
        }
        
        // And finally, start the upload.
        dfuTask = Task {
            do {
                // First, create a new slot for the image.
                statusView.text = "Creating slot..."
                let slot = try await createSlot(for: image, with: firmwareId, and: metadata, over: transport)
                
                // Read MCU Manager parameters to get the buffer size and count.
                statusView.text = "Reading parameters..."
                let config = try await readParameters(over: transport)
                
                // Upload the image using Mcu Manager.
                statusView.text = "Uploading image..."
                try await uploadImage(image, using: config, over: transport) { [weak self] progress in
                    self?.uploadProgress = progress
                    self?.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                }
                
                // We no longer need the transport.
                transport.close()
                
                // Start the distribution.
                statusView.text = "Distributing image..."
                let response = try await distributor.startDfu(of: slot, with: parameters)
                guard response.status == .success else {
                    throw DFUError.distributionFailed(response.status)
                }
                
                // Allow closing the view controller.
                // Distribution will be continued in the background.
                navigationItem.rightBarButtonItem?.isEnabled = true
                
                // Initialize the distribution progress.
                distributionProgress = receivers.map { _ in .distribution(progress: 0, speedBytesPerSecond: 0) }
                tableView.reloadSections(IndexSet(integer: 1), with: .none)
                
                let start = Date()
                var atLeastOneTransfer = true
                
                while atLeastOneTransfer {
                    // Mesh DFU is slow. Let's poll progress every 10 seconds.
                    try await Task.sleep(nanoseconds: 10_000_000_000)
                    
                    // Reset the flag.
                    atLeastOneTransfer = false
                    
                    // Read the distribution progress. The request allows for paging.
                    // Let's read 10 records at a time.
                    let limit = 10
                    var index = 0
                    
                    var lowestSpeed: Float?
                    while true {
                        let list = try await distributor.getDistributionProgress(from: index, limit: limit)
                        var i = 0
                        for receiver in list.receivers {
                            switch receiver.phase {
                            case .transferActive:
                                atLeastOneTransfer = true
                                let progress = receiver.transferProgress
                                
                                if distributionProgress[index + i].progress < progress {
                                    // Calculate transfer speed. This is very approximate,
                                    // as we don't know the exact number of received bytes.
                                    // But the higher the percentage, the more accurate it is.
                                    // The 1.13 coefficient was calculated during tests and is applied
                                    // to take into account that the received progress reports are updated
                                    // only after a page (4096 bytes) is received, not continuously.
                                    let bytesReceived = Int(Float(image.data.count) * Float(progress) / 100.0)
                                    let elapsed = -start.timeIntervalSinceNow
                                    let speed = 1.13 * Float(bytesReceived) / Float(elapsed)
                                    // print("AAA: progress: \(progress)%, bytes received: \(bytesReceived) in \(elapsed) sec -> speed: \(speed) bps")
                                    lowestSpeed = min(lowestSpeed ?? 100000, speed)
                                    distributionProgress[index + i] = .distribution(progress: progress, speedBytesPerSecond: speed)
                                }
                            case .verificationSucceeded:
                                distributionProgress?[index + i] = .verified
                            case .applyingUpdate, .applySuccess:
                                distributionProgress?[index + i] = .applied
                            case .verificationFailed, .applyFailed, .transferCanceled:
                                distributionProgress?[index + i] = .failure
                            case .idle:
                                distributionProgress?[index + i] = .idle
                            // Ignore other phases.
                            default:
                                break // switch, not for-loop
                            }
                            i += 1
                        }
                        
                        index += limit
                        if list.totalCount < index {
                            break
                        }
                    }
                    
                    // Do your best to re-estimate remaining time.
                    if let lowestSpeed = lowestSpeed {
                        estimateTime(withDistributionSpeed: lowestSpeed)
                    }
                    
                    tableView.reloadSections(IndexSet(integer: 1), with: .none)
                    let allVerified = distributionProgress.allSatisfy { if case .verified = $0 { true } else { false } }
                    if allVerified {
                        tableView.reloadSections(IndexSet(integer: 2), with: .none)
                    }
                    
                    // Check if the new firmware have been delivered to all receivers.
                    let allApplied = distributionProgress.allSatisfy { if case .applied = $0 { true } else { false } }
                    if allApplied || allVerified {
                        statusView.text = "Completed"
                        inProgress = false
                        progress.setProgress(1.0, animated: true)
                        // Allow cancelling instead of Applying.
                        navigationItem.leftBarButtonItem?.isEnabled = !allApplied
                    }
                }
            } catch {
                inProgress = false
                
                switch error {
                case DFUError.cancelled:
                    statusView.text = "Cancelling upload..."
                    transport.close()
                    navigationController?.dismiss(animated: true)
                    
                case is CancellationError:
                    statusView.text = "Cancelling distribution..."
                    let status = try await distributor.cancelDistribution()
                    if status.status == .success {
                        navigationController?.dismiss(animated: true)
                    } else {
                        statusView.text = "\(status.status)"
                    }
                default:
                    statusView.text = "\(error.localizedDescription)"
                }
            }
            dfuTask = nil
        }
    }
    
    private func estimateTime(withDistributionSpeed speedBytesPerSecond: Float = 130.0) {
        let imageSize = updatePackage.images[0].data.count
        
        // First, the image is uploaded to the Distributor
        // using SMP protocol over GATT.
        // This is fairly fast, depending on the connection parameters it may
        // be done with speed 5 - 40 kB/s.
        // The speed is updated during the upload with the actual calculated speed,
        // but initially we assume 5.5 kB/s.
        let timeToDistributor = Float(imageSize) / (uploadProgress?.speedBytesPerSecond ?? 5500.0)
        
        // After the image is uploaded, the Distributor will send the image to all receivers
        // using BLOB messages. The speed of the distribution is much lower.
        // When Unicast distribution is used, the speed is 130 B/s for a single receiver,
        // but gets slower with more receivers. With multicast distribution,
        // the speed is lower, but the same for all receivers.
        let timeToNodes = Float(imageSize) / speedBytesPerSecond
        
        estimatedTotalTime = TimeInterval(timeToDistributor + timeToNodes)
    }
}

extension DFUViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // Allow dismiss only when all tasks are complete.
        return !inProgress
    }
    
}

extension DFUViewController: UITableViewDataSource {
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard updatePackage != nil && updatePackage.images.count > 0 && receivers.count > 0 else {
            return 0
        }
        return 2 + (parameters.updatePolicy == .verifyOnly ? 1 : 0)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1 // Upload cell
        case 1:
            return receivers.count // A row per Receiver
        case 2:
            return 1 // Apply button
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
            cell.progress = uploadProgress?.progress
            cell.speedBytesPerSecond = uploadProgress?.speedBytesPerSecond
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "node", for: indexPath) as! NodeProgressViewCell
            
            let node = MeshNetworkManager.instance.meshNetwork?.node(withAddress: receivers[indexPath.row].address)
            cell.node = node
            switch distributionProgress[indexPath.row] {
            case .idle:
                cell.progress = nil
                cell.speedBytesPerSecond = nil
            case .distribution(let progress, let speedBytesPerSecond):
                cell.progress = Float(progress) / 100.0
                cell.speedBytesPerSecond = speedBytesPerSecond
            case .verified, .applied:
                cell.success = true
            case .failure:
                cell.failure = true
            }
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "apply", for: indexPath)
            cell.textLabel?.isEnabled = inProgress && distributionProgress.allSatisfy { if case .verified = $0 { true } else { false } }
            return cell
        default:
            fatalError("Invalid section")
        }
    }
    
}

extension DFUViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 2 {
            return distributionProgress.allSatisfy { if case .verified = $0 { true } else { false } }
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Apply button tapped.
        if indexPath.section == 2 {
            statusView.text = "Applying firmware..."
            Task {
                do {
                    let response = try await distributor.applyFirmware()
                    guard response.status == .success else {
                        throw DFUError.distributionFailed(response.status)
                    }
                    statusView.text = "Completed"
                    progress.progress = 1.0
                    inProgress = false
                    tableView.reloadSections(IndexSet(integer: 2), with: .none)
                } catch {
                    statusView.text = "\(error.localizedDescription)"
                    // Allow to Apply again.
                }
            }
        }
    }

}

private extension DFUViewController {
    
    enum DFUError: LocalizedError {
        case invalidResponse(String)
        case distributionFailed(FirmwareDistributionMessageStatus)
        case cancelled
        
        var errorDescription: String? {
            switch self {
            case .invalidResponse(let response):  return NSLocalizedString("Adding slot failed. Invalid response: \(response)", comment: "dfu")
            case .distributionFailed(let status): return NSLocalizedString("Distribution failed: \(status)", comment: "dfu")
            case .cancelled:                      return NSLocalizedString("Cancelled", comment: "dfu")
            }
        }
    }
    
    /// Creates a new slot for the image.
    ///
    /// - parameters:
    ///   - image: The image to upload.
    ///   - firmwareId: The firmware ID, as hexadecimal String
    ///   - metadata: Optional metadata, as hexadecimal String.
    ///   - transport: The transport to use.
    /// - returns: The index of the newly created slot.
    func createSlot(for image: ImageManager.Image, with firmwareId: String, and metadata: String?, over transport: McuMgrTransport) async throws -> UInt16 {
        let metadata = metadata.map { " \($0)" } ?? ""
        
        return try await withCheckedThrowingContinuation { continuation in
            let shellManager = ShellManager(transport: transport)
            shellManager.logDelegate = self
            shellManager.execute(command: "mesh models dfu slot add \(image.data.count) \(firmwareId)\(metadata)") { response, error in
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
                    // The slot index is used to identify the image in the Distributor.
                    // Keep it for later use.
                    let slot = UInt16(truncatingIfNeeded: number)
                    continuation.resume(returning: slot)
                } else {
                    continuation.resume(throwing: DFUError.invalidResponse(response?.output ?? "Empty"))
                }
            }
        }
    }
    
    /// Reads MCU Manager parameters to get the buffer size and count.
    ///
    /// - parameter transport: The transport to use.
    /// - returns: The upload configuration.
    func readParameters(over transport: McuMgrTransport) async throws -> FirmwareUpgradeConfiguration {
        return try await withCheckedThrowingContinuation { continuation in
            let osManager = DefaultManager(transport: transport)
            osManager.logDelegate = self
            osManager.params { response, error in
                // Set the upload parameters based on the response.
                let config = response.map { params in
                    FirmwareUpgradeConfiguration(
                        // Note, that number of buffers is decreased by 1.
                        pipelineDepth: params.bufferCount.map { max(1, Int($0) - 1) } ?? 0,
                        // Increased buffer size decreases number of bytes used for sending metadata.
                        reassemblyBufferSize: params.bufferSize
                    )
                } ?? FirmwareUpgradeConfiguration()
                
                continuation.resume(returning: config)
            }
        }
    }
    
    /// Uploads the image using McuManager using SMP protocol.
    ///
    /// - parameters:
    ///   - image: The image to upload.
    ///   - config: The upload configuration.
    ///   - transport: The transport to use for the upload.
    ///   - onProgress: The progress callback.
    func uploadImage(_ image: ImageManager.Image,
                     using config: FirmwareUpgradeConfiguration,
                     over transport: McuMgrTransport,
                     onProgress: @escaping @Sendable (UploadProgress) -> Void) async throws {
        /// This callback will be used to report the upload progress.
        class UploadCallback: ImageUploadDelegate {
            var continuation: CheckedContinuation<Void, Error>!
            
            private let onProgress: @Sendable (UploadProgress) -> Void
            private var uploadStartTime: Date
            
            init(onProgress: @escaping @Sendable (UploadProgress) -> Void) {
                self.onProgress = onProgress
                self.uploadStartTime = Date()
            }
                
            func uploadProgressDidChange(bytesSent: Int, imageSize: Int, timestamp: Date) {
                if bytesSent > 0 {
                    let progress = Float(bytesSent) / Float(imageSize)
                    let speed = Float(bytesSent) / Float(timestamp.timeIntervalSince(uploadStartTime))
                    onProgress(UploadProgress(progress: progress, speedBytesPerSecond: speed))
                }
            }
            
            func uploadDidFail(with error: any Error) {
                continuation.resume(throwing: error)
            }
            
            func uploadDidCancel() {
                continuation.resume(throwing: DFUError.cancelled)
            }
            
            func uploadDidFinish() {
                continuation.resume()
            }
        }
        
        // Store the reference to the callback to prevent it from being deallocated.
        let callback = UploadCallback(onProgress: onProgress)
        let imageManager = ImageManager(transport: transport)
        imageManager.logDelegate = self
        
        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation { continuation in
                callback.continuation = continuation
                _ = imageManager.upload(images: [image], using: config, delegate: callback)
            }
        } onCancel: {
            imageManager.cancelUpload()
        }
    }
    
}

extension DFUViewController: McuMgrLogDelegate {
    
    func log(_ message: String, ofCategory category: McuMgrLogCategory, atLevel level: McuMgrLogLevel) {
        os_log("%{public}@", log: category.log, type: level.type, message)
    }
    
    func minLogLevel() -> McuMgrLogLevel {
        return .info
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

private extension Node {
    
    func startDfu(of slotIndex: UInt16, with parameters: DFUParameters) async throws -> FirmwareDistributionStatus {
        let model = models(withSigModelId: .firmwareDistributionServerModelId).first!
        let message = FirmwareDistributionStart(
            firmwareWithImageIndex: slotIndex,
            to: parameters.selectedGroup?.address,
            usingKeyIndex: parameters.applicationKey.index,
            ttl: parameters.ttl,
            mode: parameters.transferMode,
            updatePolicy: parameters.updatePolicy,
            distributionTimeoutBase: parameters.timeoutBase)
        return try await MeshNetworkManager.instance.send(message, to: model) as! FirmwareDistributionStatus
    }
    
    func getDistributionProgress(from index: Int, limit: Int) async throws -> FirmwareDistributionReceiversList {
        let model = models(withSigModelId: .firmwareDistributionServerModelId).first!
        let message = FirmwareDistributionReceiversGet(from: UInt16(index), limit: UInt16(limit))
        return try await MeshNetworkManager.instance.send(message, to: model) as! FirmwareDistributionReceiversList
    }
    
    func cancelDistribution() async throws -> FirmwareDistributionStatus {
        let model = models(withSigModelId: .firmwareDistributionServerModelId).first!
        let message = FirmwareDistributionCancel()
        return try await MeshNetworkManager.instance.send(message, to: model) as! FirmwareDistributionStatus
    }
    
    func applyFirmware() async throws -> FirmwareDistributionStatus {
        let model = models(withSigModelId: .firmwareDistributionServerModelId).first!
        let message = FirmwareDistributionApply()
        return try await MeshNetworkManager.instance.send(message, to: model) as! FirmwareDistributionStatus
    }
    
}
