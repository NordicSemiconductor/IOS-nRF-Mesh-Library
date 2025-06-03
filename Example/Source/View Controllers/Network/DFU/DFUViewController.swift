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
        if !inProgress {
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
    var applicationKey: ApplicationKey!
    /// Distribution parameters.
    var parameters: DFUParameters!
    
    /// List or receivers to update.
    var receivers: [Receiver]?
    /// The selected firmware to be sent to the Distributor and then distributed to the receivers.
    var updatePackage: UpdatePackage?
    /// The estimated size of the firmware image.
    ///
    /// This field is used when user reopens the DFU screen. In that case the update package
    /// is not known and the firmware size is not available, but using the Distributor Capabilities
    /// we can estimate the size of the firmware image based on the used upload space.
    var estimatedFirmwareSize: Int?
    
    // MARK: - Private Properties
    
    private var inProgress: Bool = false {
        didSet {
            remainingTime.isHidden = !inProgress
        }
    }
    
    private var dfuTask: Task<Void, Error>?
    private var uploadProgress: UploadProgress? {
        didSet {
            estimateTotalTime(withDistributionSpeed: estimatedDistributionSpeed)
        }
    }
    private var estimatedTotalTime: TimeInterval!
    private var estimatedDistributionSpeed: Float!
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make the dialog modal (non-dismissible) if update is in progress.
        navigationController?.presentationController?.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // Should we get the status of ongoing distribution?
        if let estimatedFirmwareSize = estimatedFirmwareSize {
            loadUpdate(estimatedFirmwareSize: estimatedFirmwareSize)
        } else {
            // If not, start a new one.
            startUpdate()
        }
    }
    
    /// This method starts a new DFU operation.
    ///
    /// It assumes, that the update package, parameters and receivers are set.
    func startUpdate() {
        guard let image = prepareUpload() else { return }

        dfuTask = Task {
            do {
                // First, create a slot and upload the image.
                let imageIndex = try await performUpload(ofImage: image)
                // Then, start the distribution.
                let startTime = try await startDistribution(fromImageIndex: imageIndex)
                
                // Periodically poll the distribution progress.
                try await Task.sleep(nanoseconds: 10_000_000_000)
                while try await pollDistributionProgress(andUpdateProgressBasedOnImageSize: image.data.count, andStartTime: startTime) {
                    try await Task.sleep(nanoseconds: 10_000_000_000)
                }
            } catch {
                handleError(error)
            }
            dfuTask = nil
        }
    }

    /// This method loads the current state of the DFU operation after user reopens the DFU screen.
    ///
    /// If the distribution is still in progress, the estimated image size is used to
    /// calculate the progress and estimated time remaining.
    ///
    /// - parameter estimatedFirmwareSize: The estimated size of the firmware image.
    func loadUpdate(estimatedFirmwareSize: Int) {
        // When the DFU screen is reopened, list of receivers
        // is not know. It will be build based on the distribution receivers list.
        receivers = []

        dfuTask = Task {
            do {
                // As the firmware was already uploaded, enable Done button.
                navigationItem.rightBarButtonItem?.isEnabled = true
                
                let status = try await distributor.getDistributionStatus()
                estimateDistributionSpeed(forReceivers: receivers!, usingMulticast: status.multicastAddress != nil)
                
                // Note, that the start time is not known.
                // Below we will calculate it based on the progress of the first receiver.
                var start: Date?
                while true {
                    let hasTransfer = try await pollDistributionProgress(andUpdateProgressBasedOnImageSize: estimatedFirmwareSize, andStartTime: start)
                    if hasTransfer {
                        statusView.text = "Distributing image..."
                        inProgress = true
                        if start == nil {
                            let firstReceiver = receivers!.first { $0.status.progress > 0 }
                            if let progress = firstReceiver?.status.progress {
                                let received = Float(estimatedFirmwareSize) * Float(progress) / 100.0
                                let elapsedSeconds = Double(received) / Double(estimatedDistributionSpeed)
                                start = Date().addingTimeInterval(-elapsedSeconds)
                                startTimer(usingStartTime: start!)
                            }
                        }
                    } else {
                        break
                    }
                    try await Task.sleep(nanoseconds: 10_000_000_000)
                }
            } catch {
                handleError(error)
            }
            dfuTask = nil
        }
    }

    // MARK: - Helpers

    private func prepareUpload() -> ImageManager.Image? {
        guard let updatePackage = updatePackage, let image = updatePackage.images.first else {
            statusView.text = "No images available"
            return nil
        }
        guard let parameters = parameters else {
            statusView.text = "Update parameters not set"
            return nil
        }
        inProgress = true
        estimateDistributionSpeed(forReceivers: receivers!, usingMulticast: parameters.multicastAddress != nil)
        estimateTotalTime(withDistributionSpeed: estimatedDistributionSpeed)
        startTimer(usingStartTime: Date())
        return image
    }

    /// Creates a new slot for the image and uploads it to the Distributor.
    ///
    /// - parameter image: The image to be uploaded.
    /// - returns: The index of the created slot.
    private func performUpload(ofImage image: ImageManager.Image) async throws -> UInt16 {
        let firmwareId = updatePackage!.metadata.firmwareIdString
        let metadata = updatePackage!.metadata.metadataString.map { " \($0)" } ?? ""
        let transport = McuMgrBleTransport(bearer.identifier)
        defer {
            transport.close()
        }

        // During upload, the Done button is disabled.
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        uploadProgress = UploadProgress(progress: 0, speedBytesPerSecond: 5500.0)
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        
        statusView.text = "Creating slot..."
        let slot = try await createSlot(for: image, with: firmwareId, and: metadata, over: transport)
        
        statusView.text = "Reading parameters..."
        let config = try await readParameters(over: transport)
        
        statusView.text = "Uploading image..."
        try await uploadImage(image, using: config, over: transport) { [weak self] progress in
            self?.uploadProgress = progress
            self?.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        }
        return slot
    }

    /// Sends Firmware Distribution Start command to the Distributor to start the distribution.
    ///
    /// - parameter imageIndex: Index of the created image on the Firmware Distribution List.
    /// - returns: The start time of the distribution.
    private func startDistribution(fromImageIndex imageIndex: UInt16) async throws -> Date {
        statusView.text = "Distributing image..."
        let response = try await distributor.startDfu(of: imageIndex, with: parameters!, andApplicationKey: applicationKey)
        guard response.status == .success else {
            throw DFUError.distributionFailed(response.status)
        }
        
        // When the distribution starts, it is now possible to close the
        // view controller. Distribution will be continued in the background.
        navigationItem.rightBarButtonItem?.isEnabled = true
        
        // Change the receivers' statuses to distribution.
        for i in 0..<receivers!.count {
            receivers![i].status = .distribution(progress: 0, speedBytesPerSecond: 0)
        }
        tableView.reloadSections(IndexSet(integer: 1), with: .none)
        return Date()
    }

    /// Polls the distribution progress.
    ///
    /// - parameters:
    ///   - imageSize: The size of the image being distributed.
    ///   - startTime: The time when the distribution started, or `nil` if unknown.
    /// - returns: A boolean indicating if at least one transfer is in progress.
    private func pollDistributionProgress(andUpdateProgressBasedOnImageSize imageSize: Int, andStartTime startTime: Date?) async throws -> Bool {
        var atLeastOneTransfer = false
        
        // Read the distribution progress. The request allows for paging.
        // Let's read 10 records at a time.
        var index = 0
        let limit = 10
        
        while true {
            let list = try await distributor.getDistributionProgress(from: index, limit: limit)
            let receiversList = list.receivers

            if receivers!.count < index + receiversList.count {
                for i in 0..<(index + receiversList.count - receivers!.count) {
                    receivers!.append(Receiver(address: receiversList[i].address, imageIndex: receiversList[i].imageIndex))
                }
            }

            updateReceiverStatuses(using: receiversList, imageSize: imageSize, start: startTime)
            
            // During polling we will keep track of the lowest transfer speed
            // and recalculate the estimated time based on it.
            let lowestSpeed = receivers!.compactMap { if case .distribution(_, let speed) = $0.status { return speed } else { return nil } }.min()
            if let speed = lowestSpeed, speed > 0 {
                estimateTotalTime(withDistributionSpeed: speed)
            }

            atLeastOneTransfer = atLeastOneTransfer || receiversList.contains { $0.phase == .transferActive }

            index += limit
            if list.totalCount < index {
                break
            }
        }

        tableView.reloadSections(IndexSet(integer: 1), with: .none)
        checkIfCompleted()
        return atLeastOneTransfer
    }

    /// Updates the receiver statuses based on the distribution progress.
    ///
    /// - parameters:
    ///   - receiversList: The list of receivers with their statuses.
    ///   - imageSize: The size of the image being distributed.
    ///   - start: The time when the distribution started, or `nil` if unknown.
    private func updateReceiverStatuses(using receiversList: [FirmwareDistributionReceiversList.ReceiverStatus],
                                        imageSize: Int, start: Date?) {
        for (i, receiver) in receiversList.enumerated() {
            guard i < receivers!.count else { continue }
            let progress = receiver.transferProgress

            switch receiver.phase {
            case .transferActive:
                if receivers![i].status.progress < progress {
                    // When the start time of the distribution is unknown assume 0.13 kB/s.
                    let speed = start.map { calculateSpeed(basedOnProgress: progress, imageSize: imageSize, start: $0) }
                    receivers![i].status = .distribution(progress: progress, speedBytesPerSecond: speed ?? estimatedDistributionSpeed)
                }
            case .verificationSucceeded:
                receivers![i].status = .verified
            case .applyingUpdate, .applySuccess:
                receivers![i].status = .applied
            case .verificationFailed, .applyFailed, .transferCanceled:
                receivers![i].status = .failure
            case .idle:
                receivers![i].status = .idle
            default: break
            }
        }
    }

    /// Calculates the transfer speed based on the progress and start time.
    ///
    /// - parameters:
    ///   - progress: The current progress of the transfer. The progress is a percentage value, 0-100 in multiples of 2.
    ///   - imageSize: The size of the image being distributed.
    ///   - start: The time when the distribution started.
    /// - returns: The calculated speed in bytes per second.
    private func calculateSpeed(basedOnProgress progress: Int, imageSize: Int, start: Date) -> Float {
        let bytesReceived = Int(Float(imageSize) * Float(progress) / 100.0)
        let elapsed = -start.timeIntervalSinceNow
        
        // The 1.13 coefficient was calculated during tests and is applied
        // to take into account that the received progress reports are updated
        // only after a page (4096 bytes) is received, not continuously.
        let speed = 1.13 * Float(bytesReceived) / Float(elapsed)
        return speed
    }

    /// Checks if the distribution is completed.
    ///
    /// If all receivers are verified or applied, the status is updated
    /// and the progress is set to 1.0.
    private func checkIfCompleted() {
        let allVerified = receivers!.allSatisfy { if case .verified = $0.status { true } else { false } }
        let allApplied = receivers!.allSatisfy { if case .applied = $0.status { true } else { false } }
        let allFailed = receivers!.allSatisfy { if case .failure = $0.status { true } else { false } }
        if allFailed {
            statusView.text = "Distribution failed"
            inProgress = false
            navigationItem.leftBarButtonItem?.isEnabled = false
        }
        if allApplied || allVerified {
            statusView.text = "Completed"
            inProgress = false
            progress.setProgress(1.0, animated: true)
            navigationItem.leftBarButtonItem?.isEnabled = !allApplied
        }
        if allVerified {
            tableView.reloadSections(IndexSet(integer: 2), with: .none)
        }
    }

    /// Handles the error during the DFU process.
    ///
    /// - parameter error: The error that occurred.
    private func handleError(_ error: Error) {
        inProgress = false
        navigationItem.rightBarButtonItem?.isEnabled = false
        switch error {
        case DFUError.cancelled:
            statusView.text = "Cancelling upload..."
            navigationController?.dismiss(animated: true)
        case is CancellationError:
            statusView.text = "Cancelling distribution..."
            Task {
                do {
                    let status = try await distributor.cancelDistribution()
                    if status.status == .success {
                        navigationController?.dismiss(animated: true)
                    } else {
                        statusView.text = "\(status.status)"
                    }
                } catch {
                    statusView.text = error.localizedDescription
                }
            }
        default:
            statusView.text = error.localizedDescription
        }
    }
    
    /// Starts a timer to update the elapsed and remaining time.
    ///
    /// The timer runs until `inProgress` is `true`.
    ///
    /// - parameter start: The time when the upload started.
    private func startTimer(usingStartTime start: Date) {
        Task {
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
                if eta >= 1.0 {
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
    }
    
    /// Estimates the total time for the distribution.
    ///
    /// This method calculates the estimated time based on the upload speed
    /// from `uploadProgress` and given distribution speed.
    ///
    /// - parameter speedBytesPerSecond: The distribution speed in bytes per second.
    private func estimateTotalTime(withDistributionSpeed speedBytesPerSecond: Float) {
        let imageSize = updatePackage?.images[0].data.count ?? Int(estimatedFirmwareSize ?? 0)
        
        // First, the image is uploaded to the Distributor using SMP protocol over GATT.
        // This is fairly fast, depending on the connection parameters it may
        // be done with speed 5 - 40 kB/s.
        // The speed is updated during the upload with the actual calculated speed,
        // but initially we assume 5.5 kB/s.
        let uploadSpeed = uploadProgress?.speedBytesPerSecond ?? 5500.0
        guard uploadSpeed > 0 else {
            return
        }
        let timeToDistributor = Float(imageSize) / uploadSpeed
        
        // After the image is uploaded, the Distributor will send the image to all receivers
        // using BLOB messages. The speed of the distribution is much lower.
        // When Unicast distribution is used, the speed is 130 B/s for a single receiver,
        // but gets slower with more receivers. With multicast distribution,
        // the speed is lower, but the same for all receivers.
        guard speedBytesPerSecond > 0 else {
            return
        }
        let timeToNodes = Float(imageSize) / speedBytesPerSecond
        
        estimatedTotalTime = TimeInterval(timeToDistributor + timeToNodes)
    }
    
    /// Estimates distribution speed for time estimation.
    ///
    /// The speed will be updated during distribution based on the lowest transfer speed.
    private func estimateDistributionSpeed(forReceivers receivers: [Receiver], usingMulticast multicast: Bool) {
        if !multicast {
            estimatedDistributionSpeed = 130.0 / Float(max(1, receivers.count))
        } else {
            estimatedDistributionSpeed = 40.0
        }
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
        return 2 + (parameters.updatePolicy == .verifyOnly ? 1 : 0)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1 // Upload cell
        case 1:
            return receivers?.count ?? 0 // A row per Receiver
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
            cell.progress = uploadProgress?.progress ?? 1.0
            cell.speedBytesPerSecond = uploadProgress?.speedBytesPerSecond ?? 0
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "node", for: indexPath) as! NodeProgressViewCell
            cell.node = MeshNetworkManager.instance.meshNetwork?.node(withAddress: receivers![indexPath.row].address)
            switch receivers![indexPath.row].status {
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
            cell.textLabel?.isEnabled = receivers?.isEmpty == false && receivers!.allSatisfy { if case .verified = $0.status { true } else { false } }
            return cell
        default:
            fatalError("Invalid section")
        }
    }
    
}

extension DFUViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 2 {
            return receivers?.isEmpty == false && receivers!.allSatisfy { if case .verified = $0.status { true } else { false } }
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
    
    func startDfu(of slotIndex: UInt16,
                  with parameters: DFUParameters,
                  andApplicationKey applicationKey: ApplicationKey) async throws -> FirmwareDistributionStatus {
        let model = models(withSigModelId: .firmwareDistributionServerModelId).first!
        let message = FirmwareDistributionStart(
            firmwareWithImageIndex: slotIndex,
            to: parameters.multicastAddress,
            usingKeyIndex: applicationKey.index,
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
    
    func getDistributionStatus() async throws -> FirmwareDistributionStatus {
        let model = models(withSigModelId: .firmwareDistributionServerModelId).first!
        let message = FirmwareDistributionGet()
        return try await MeshNetworkManager.instance.send(message, to: model) as! FirmwareDistributionStatus
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
