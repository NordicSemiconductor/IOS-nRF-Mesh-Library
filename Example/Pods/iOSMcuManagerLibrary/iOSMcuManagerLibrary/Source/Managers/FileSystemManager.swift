/*
 * Copyright (c) 2017-2018 Runtime Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import CoreBluetooth
import SwiftCBOR

// MARK: - FileSystemManager

public class FileSystemManager: McuManager {
    
    override class var TAG: McuMgrLogCategory { .filesystemManager }
    
    // MARK: IDs
    
    enum FilesystemID: UInt8 {
        case file = 0
        case status = 1
        case hashChecksum = 2
        case supportedHashChecksum = 3
        case closeFile = 4
    }
    
    // MARK: init
    
    public init(transport: McuMgrTransport) {
        super.init(group: McuMgrGroup.filesystem, transport: transport)
    }
    
    // MARK: Download
    
    /// Requests the next packet of data from given offset.
    /// To download a complete file, use download(name:delegate) method instead.
    ///
    /// - parameter name: The file name.
    /// - parameter offset: The offset from this data will be requested.
    /// - parameter callback: The callback.
    public func download(name: String, offset: UInt,
                         callback: @escaping McuMgrCallback<McuMgrFsDownloadResponse>) {
        // Build the request payload.
        let payload: [String: CBOR] = ["name": CBOR.utf8String(name),
                                       "off": CBOR.unsignedInt(UInt64(offset))]
        // Build request and send.
        send(op: .read, commandId: FilesystemID.file, payload: payload, callback: callback)
    }
    
    // MARK: Upload
    
    /// **NOTE**: To send a complete file, use **upload(name:data:using:delegate)** API instead.
    ///
    /// Sends the next packet of data from given offset. It is part of the original API surface, hence
    /// why it has been kept. However, it is not recommended to use. Please use
    /// **upload(name:data:using:delegate)** instead. If you must use it, the aforementioned recommended
    /// API does use this, so it is maintained and in use. But keep in mind it might be a bit rough.
    ///
    /// - parameter name: The file name.
    /// - parameter data: The file data.
    /// - parameter offset: The offset from this data will be sent.
    /// - parameter configuration: The `FirmwareUpgradeConfiguration` to set if none was set previously. If no configuration is provided, and none was set previously, an error status will be declared.
    /// - parameter delegate: The `FileUploadDelegate` to set if none was set previously. Unlike the `configuration` parameter, no error will be retported if no delegate is set.
    /// - parameter callback: The callback.
    ///
    public func upload(name: String, data: Data, offset: UInt,
                       using configuration: FirmwareUpgradeConfiguration? = nil,
                       delegate uploadDelegate: FileUploadDelegate? = nil,
                       callback: @escaping McuMgrCallback<McuMgrFsUploadResponse>) {
        objc_sync_enter(self)
        if transferState != .uploading {
            transferState = .uploading
        }
        objc_sync_exit(self)
        
        self.uploadDelegate = self.uploadDelegate ?? uploadDelegate
        uploadConfiguration = uploadConfiguration ?? configuration
        guard uploadConfiguration != nil else {
            log(msg: "Missing Upload Configuration.", atLevel: .error)
            let error = FileTransferError.missingUploadConfiguration
            callback(nil, error)
            cancelTransfer(error: error)
            return
        }
        
        // Calculate the number of remaining bytes.
        let remainingBytes = UInt(data.count) - offset
        
        // Data length to end is the minimum of the max data length and the
        // number of remaining bytes.
        let packetOverhead = calculatePacketOverhead(for: name, data: data, offset: UInt64(offset))
        
        // Get the length of file data to send.
        let maxReassemblySize = min(uploadConfiguration.reassemblyBufferSize, UInt64(UInt16.max))
        let maxPacketSize = max(maxReassemblySize, UInt64(transport.mtu))
        var maxDataLength = maxPacketSize - UInt64(packetOverhead)
        if uploadConfiguration.byteAlignment != .disabled {
            maxDataLength = (maxDataLength / uploadConfiguration.byteAlignment.rawValue) * uploadConfiguration.byteAlignment.rawValue
        }
        let dataLength = min(UInt(maxDataLength), remainingBytes)
        
        // Build the request payload.
        var payload: [String: CBOR] = ["name": CBOR.utf8String(name),
                                       "data": CBOR.byteString([UInt8](data[offset..<(offset+dataLength)])),
                                       "off": CBOR.unsignedInt(UInt64(offset))]
        // If this is the initial packet, send the file data length.
        if offset == 0 {
            payload.updateValue(CBOR.unsignedInt(UInt64(data.count)), forKey: "len")
        }
        // Build request and send.
        send(op: .write, commandId: FilesystemID.file, payload: payload, callback: callback)
    }
    
    // MARK: download(name:delegate:)
    
    /// Begins the file download from a peripheral.
    ///
    /// An instance of FileSystemManager can only have one transfer in progress
    /// at a time. Therefore, if this method is called multiple times on the same
    /// FileSystemManager instance, all calls after the first will return false.
    /// Download progress is reported asynchronously to the delegate provided in
    /// this method.
    ///
    /// - parameter name: The file name to download.
    /// - parameter delegate: The delegate to receive progress callbacks.
    ///
    /// - returns: True if the upload has started successfully, false otherwise.
    public func download(name: String, delegate: FileDownloadDelegate?) -> Bool {
        // Make sure two uploads cant start at once.
        objc_sync_enter(self)
        // If upload is already in progress or paused, do not continue.
        if transferState == .none {
            // Set downloading flag to true.
            transferState = .downloading
        } else {
            log(msg: "A file transfer is already in progress", atLevel: .warning)
            objc_sync_exit(self)
            return false
        }
        objc_sync_exit(self)
        
        verifyOnMainThread()
        
        // Set download delegate.
        downloadDelegate = delegate
        
        // Set file data.
        fileName = name
        fileData = nil
        
        // Grab a strong reference to something holding a strong reference to self.
        cyclicReferenceHolder = { return self }
        
        log(msg: "Downloading \(name)...", atLevel: .application)
        download(name: name, offset: 0, callback: downloadCallback)
        return true
    }
    
    // MARK: upload(name:data:using:delegate:)
    
    /// Begins the file upload to a peripheral.
    ///
    /// An instance of FileSystemManager can only have one upload in progress at a
    /// time. Therefore, if this method is called multiple times on the same
    /// FileSystemManager instance, all calls after the first will return false.
    /// Upload progress is reported asynchronously to the delegate provided in
    /// this method.
    ///
    /// - parameter name: The file name.
    /// - parameter data: The file data to be sent to the peripheral.
    /// - parameter configuration: Settings to be used  when sending Data, such as enabling SMP Pipelining, Byte-Alignment, etc. Works as seen in `ImageManager`0s `upload(images:using:delegate)` function.
    /// - parameter delegate: The delegate to receive progress callbacks.
    ///
    /// - returns: True if the upload has started successfully, false otherwise.
    public func upload(name: String, data: Data,
                       using configuration: FirmwareUpgradeConfiguration = FirmwareUpgradeConfiguration(),
                       delegate: FileUploadDelegate) -> Bool {
        // Make sure two uploads cant start at once.
        objc_sync_enter(self)
        // If upload is already in progress or paused, do not continue.
        if transferState != .none {
            log(msg: "A file transfer is already in progress", atLevel: .warning)
            objc_sync_exit(self)
            return false
        }
        objc_sync_exit(self)
        
        verifyOnMainThread()
        
        // Set upload delegate.
        uploadDelegate = delegate
        
        // Set file data.
        fileName = name
        fileData = data
        fileSize = nil
        
        // Note that pipelining requires the use of byte-alignment, otherwise we
        // can't predict how many bytes the firmware will accept in each chunk.
        uploadConfiguration = configuration
        uploadConfiguration.reassemblyBufferSize = min(uploadConfiguration.reassemblyBufferSize, UInt64(UInt16.max))
        uploadPipeline = McuMgrUploadPipeline(adopting: uploadConfiguration, over: transport)
        if let bleTransport = transport as? McuMgrBleTransport {
            bleTransport.numberOfParallelWrites = uploadPipeline.depth
            bleTransport.chunkSendDataToMtuSize = uploadConfiguration.reassemblyBufferSize > bleTransport.mtu
        }
        
        // Grab a strong reference to something holding a strong reference to self.
        cyclicReferenceHolder = { return self }
        
        requestMcuMgrParameters()
        return true
    }
    
    // MARK: Status
    
    /// Retrieve status of an existing file from specified path of a target device.
    ///
    /// - parameter name: The file name.
    /// - parameter callback: The callback.
    public func status(name: String, callback: @escaping McuMgrCallback<McuMgrFilesystemStatusResponse>) {
        let payload: [String: CBOR] = ["name": CBOR.utf8String(name)]
        send(op: .read, commandId: FilesystemID.status, payload: payload, callback: callback)
    }
    
    // MARK: CRC32
    
    /// Generate a checksum of an existing file at a specified path on a target.
    ///
    /// - parameter name: The file name.
    /// - parameter offset: The offset to start checksum calculation at.
    /// - parameter length: The maximum length of data to read from file to generate checksum.
    /// - parameter callback: The callback.
    public func crc32(name: String, offset: UInt64, length: UInt64, callback: @escaping McuMgrCallback<McuMgrFilesystemCrc32Response>) {
        var payload: [String: CBOR] = [
            "name": CBOR.utf8String(name),
            "type": CBOR.utf8String("crc32")
        ]
        if offset > 0 {
            payload["offset"] = CBOR.unsignedInt(offset)
        }
        if length > 0 {
            payload["length"] = CBOR.unsignedInt(length)
        }
        send(op: .read, commandId: FilesystemID.hashChecksum, payload: payload, callback: callback)
    }
    
    // MARK: SHA256
    
    /// Generate a checksum of an existing file at a specified path on a target.
    ///
    /// - parameter name: The file name.
    /// - parameter offset: The offset to start checksum calculation at.
    /// - parameter length: The maximum length of data to read from file to generate checksum.
    /// - parameter callback: The callback.
    public func sha256(name: String, offset: UInt64, length: UInt64, callback: @escaping McuMgrCallback<McuMgrFilesystemSha256Response>) {
        var payload: [String: CBOR] = [
            "name": CBOR.utf8String(name),
            "type": CBOR.utf8String("sha256")
        ]
        if offset > 0 {
            payload["offset"] = CBOR.unsignedInt(offset)
        }
        if length > 0 {
            payload["length"] = CBOR.unsignedInt(length)
        }
        send(op: .read, commandId: FilesystemID.hashChecksum, payload: payload, callback: callback)
    }
    
    // MARK: closeAll
    
    /// Close any open file handles held by `fs_mgmt` upload/download requests that might have stalled or be incomplete.
    ///
    /// - parameter callback: The callback.
    public func closeAll(name: String, callback: @escaping McuMgrCallback<McuMgrResponse>) {
        send(op: .write, commandId: FilesystemID.closeFile, payload: nil, callback: callback)
    }
    
    // MARK: State
    
    /// Image upload states
    public enum UploadState: UInt8 {
        case none             = 0
        case mcuMgrParameters = 1
        case uploading        = 2
        case downloading      = 3
        case paused           = 4
    }
    
    // MARK: Private Properties
    
    /// State of the file upload.
    private var transferState: UploadState = .none
    /// Current file byte offset to send from.
    private var offset: UInt64 = 0
    
    /// The file name.
    private var fileName: String?
    /// Contains the file data to send to the device.
    private var fileData: Data?
    /// Expected file length.
    private var fileSize: Int?
    /// Delegate to send file upload updates to.
    private weak var uploadDelegate: FileUploadDelegate?
    /**
     Groups multiple Settings regarding Upload, such as enabling Pipelining, Byte Alignment and/or SMP Reassembly.
     
     This is not applied for Download, since it's up to the Sender to package/format the Data according to SMP specification.
     */
    private var uploadConfiguration: FirmwareUpgradeConfiguration!
    
    private var uploadPipeline: McuMgrUploadPipeline!
    
    /// Delegate to send file download updates to.
    private weak var downloadDelegate: FileDownloadDelegate?
    /**
     Used internally to perform McuMgr Parameters request.
     */
    private var defaultManager: DefaultManager!
    /**
     Used to store McuMgrParameters Response until after the first succesful
     packet is sent. This is to delay sending multiple sequence numbers + reassembly
     packets unless we can start uploading. So we wait until after first successful
     packet upload.
     */
    private var storedMcuMgrParametersResponse: McuMgrParametersResponse?
    
    /// Cyclic reference is used to prevent from releasing the manager
    /// in the middle of an update. The reference cycle will be set
    /// when upload or download was started and released on success, error
    /// or cancel.
    private var cyclicReferenceHolder: (() -> FileSystemManager)?
    
    // MARK: Cancel
    
    /// Cancels the current transfer.
    ///
    /// If an error is supplied, the delegate's didFailUpload method will be
    /// called with the Upload Error provided.
    ///
    /// - parameter error: The optional upload error which caused the
    ///   cancellation. This error (if supplied) is used as the argument for the
    ///   delegate's didFailUpload/Download method.
    public func cancelTransfer(error: Error? = nil) {
        objc_sync_enter(self)
        if transferState == .none {
            log(msg: "Transfer is not in progress", atLevel: .warning)
        } else {
            if let error = error {
                log(msg: "Transfer cancelled due to error: \(error)", atLevel: .error)
                resetTransfer()
                uploadDelegate?.uploadDidFail(with: error)
                uploadDelegate = nil
                downloadDelegate?.downloadDidFail(with: error)
                downloadDelegate = nil
                // Release cyclic reference.
                cyclicReferenceHolder = nil
            } else {
                if transferState == .paused {
                    log(msg: "Transfer cancelled", atLevel: .application)
                    resetTransfer()
                    uploadDelegate?.uploadDidCancel()
                    downloadDelegate?.downloadDidCancel()
                    uploadDelegate = nil
                    downloadDelegate = nil
                    // Release cyclic reference.
                    cyclicReferenceHolder = nil
                }
                // else
                // Transfer will be cancelled after the next notification is received.
            }
            transferState = .none
        }
        objc_sync_exit(self)
    }
    
    // MARK: Pause
    
    /// Pauses the current transfer. If there is no transfer in progress, nothing
    /// happens.
    public func pauseTransfer() {
        objc_sync_enter(self)
        if transferState == .none {
            log(msg: "Transfer is not in progress and therefore cannot be paused",
                atLevel: .warning)
        } else {
            log(msg: "Transfer paused", atLevel: .application)
            transferState = .paused
        }
        objc_sync_exit(self)
    }
    
    // MARK: Continue
    
    /// Continues a paused transfer. If the transfer is not paused or not uploading,
    /// nothing happens.
    public func continueTransfer() {
        objc_sync_enter(self)
        if transferState == .paused {
            log(msg: "Continuing transfer", atLevel: .application)
            if let _ = downloadDelegate {
                transferState = .downloading
                download(name: fileName!, offset: UInt(offset), callback: downloadCallback)
            } else {
                transferState = .uploading
                upload(name: fileName!, data: fileData!, offset: UInt(offset), callback: uploadCallback)
            }
        } else {
            log(msg: "Transfer is not paused", atLevel: .warning)
        }
        objc_sync_exit(self)
    }
    
    // MARK: mcuMgrParameters Callback
    
    private lazy var mcuManagerParametersCallback: McuMgrCallback<McuMgrParametersResponse> = { [weak self] response, error in
        guard let self else { return }
        
        guard error == nil, let response, response.rc.isSupported() else {
            self.log(msg: "Mcu Manager parameters not supported.", atLevel: .warning)
            self.finishedMcuMgrParametersRequest() // Proceed to upload.
            return
        }
        
        self.receivedMcuMgrParametersResponse(response)
        self.finishedMcuMgrParametersRequest()
    }
    
    // MARK: uploadCallback
    
    private lazy var uploadCallback: McuMgrCallback<McuMgrFsUploadResponse> = {
        [weak self] (response: McuMgrFsUploadResponse?, error: Error?) in
        // Ensure the manager is not released.
        guard let self else {
            return
        }
        // Check for an error.
        if let error {
            if case let McuMgrTransportError.insufficientMtu(newMtu) = error {
                do {
                    try self.setMtu(newMtu)
                    self.restartTransfer()
                } catch let mtuResetError {
                    self.cancelTransfer(error: mtuResetError)
                }
                return
            }
            self.cancelTransfer(error: error)
            return
        }
        
        // Make sure the file data is set.
        guard let fileName, let fileData else {
            self.cancelTransfer(error: FileTransferError.invalidData)
            return
        }
        
        // Make sure the response is not nil.
        guard let response else {
            self.cancelTransfer(error: FileTransferError.invalidPayload)
            return
        }
        
        // Check for an error return code.
        if let error = response.getError() {
            guard let groupError = response.groupRC?.groupError() as? FileSystemManagerError else {
                self.cancelTransfer(error: error)
                return
            }
            self.cancelTransfer(error: groupError)
            return
        }
        
        // Get the offset from the response.
        if let offset = response.off {
            // if 'first successful sequenceNumber upload'
            if self.offset == 0 && offset > 0, let response = self.storedMcuMgrParametersResponse {
                self.patchReassemblyAndPipeliningSetup(using: response)
                self.storedMcuMgrParametersResponse = nil
            }
            // Set the file upload offset.
            self.offset = offset
            self.uploadPipeline?.receivedData(with: offset)
            self.uploadDelegate?.uploadProgressDidChange(bytesSent: Int(offset),
                                                         fileSize: fileData.count,
                                                         timestamp: Date())
            
            if self.transferState == .none {
                self.log(msg: "Upload cancelled", atLevel: .application)
                self.resetTransfer()
                self.uploadDelegate?.uploadDidCancel()
                self.uploadDelegate = nil
                // Release cyclic reference.
                self.cyclicReferenceHolder = nil
                return
            }
            
            // Check if the upload has completed.
            if offset >= fileData.count {
                self.log(msg: "Upload finished", atLevel: .application)
                self.resetTransfer()
                self.uploadDelegate?.uploadDidFinish()
                self.uploadDelegate = nil
                // Release cyclic reference.
                self.cyclicReferenceHolder = nil
            } else {
                // Send the next packet of data.
                self.uploadPipeline.pipelinedSend(ofSize: fileData.count) { [unowned self] offset in
                    let packetOverhead = self.calculatePacketOverhead(for: fileName, data: fileData, offset: offset)
                    let payloadLength = self.maxDataPacketLengthFor(data: fileData, at: offset, with: packetOverhead, and: self.uploadConfiguration)
                    self.sendNext(from: UInt(offset))
                    return offset + payloadLength
                }
            }
        } else {
            self.cancelTransfer(error: ImageUploadError.invalidPayload)
        }
    }
    
    // MARK: downloadCallback
    
    private lazy var downloadCallback: McuMgrCallback<McuMgrFsDownloadResponse> = {
        [weak self] (response: McuMgrFsDownloadResponse?, error: Error?) in
        // Ensure the manager is not released.
        guard let self else {
            return
        }
        // Check for an error.
        if let error {
            if case let McuMgrTransportError.insufficientMtu(newMtu) = error {
                do {
                    try self.setMtu(newMtu)
                    self.restartTransfer()
                } catch let mtuResetError {
                    self.cancelTransfer(error: mtuResetError)
                }
                return
            }
            self.cancelTransfer(error: error)
            return
        }
        // Make sure the response is not nil.
        guard let response = response else {
            self.cancelTransfer(error: FileTransferError.invalidPayload)
            return
        }
        // Check for an error return code.
        if let error = response.getError() {
            guard let groupError = response.groupRC?.groupError() as? FileSystemManagerError else {
                self.cancelTransfer(error: error)
                return
            }
            self.cancelTransfer(error: groupError)
            return
        }
        // Get the offset from the response.
        if let offset = response.off, let data = response.data {
            // The first packet contains the file length.
            if offset == 0 {
                if let len = response.len {
                    self.fileSize = Int(len)
                    self.fileData = Data(capacity: Int(len))
                } else {
                    self.cancelTransfer(error: FileTransferError.invalidPayload)
                    return
                }
            }
            // Set the file upload offset.
            self.offset = offset + UInt64(data.count)
            self.fileData!.append(contentsOf: data)
            self.downloadDelegate?.downloadProgressDidChange(bytesDownloaded: Int(self.offset),
                                                             fileSize: self.fileSize!,
                                                             timestamp: Date())
            
            if self.transferState == .none {
                self.log(msg: "Download cancelled", atLevel: .application)
                self.resetTransfer()
                self.downloadDelegate?.downloadDidCancel()
                self.downloadDelegate = nil
                // Release cyclic reference.
                self.cyclicReferenceHolder = nil
                return
            }
            
            // Check if the upload has completed.
            if self.offset >= self.fileSize! {
                self.log(msg: "Download finished", atLevel: .application)
                self.downloadDelegate?.download(of: self.fileName!, didFinish: self.fileData!)
                self.resetTransfer()
                self.downloadDelegate = nil
                // Release cyclic reference.
                self.cyclicReferenceHolder = nil
                return
            }
            
            // Send the next packet of data.
            self.requestNext(from: UInt(self.offset))
        } else {
            self.cancelTransfer(error: FileTransferError.invalidPayload)
        }
    }
}
 
// MARK: - Private

private extension FileSystemManager {
    
    // MARK: mcuMgrParameters
    
    func requestMcuMgrParameters() {
        objc_sync_enter(self)
        log(msg: "Requesting McuMgr Parameters...", atLevel: .application)
        storedMcuMgrParametersResponse = nil
        transferState = .mcuMgrParameters
        defaultManager = DefaultManager(transport: transport)
        defaultManager.params(callback: mcuManagerParametersCallback)
        objc_sync_exit(self)
    }
    
    func receivedMcuMgrParametersResponse(_ response: McuMgrParametersResponse) {
        log(msg: "Processing McuMgr Parameters Response.", atLevel: .debug)
        guard let bleTransport = transport as? McuMgrBleTransport else {
            log(msg: "Ignoring McuMgr Parameters Response due to unsupported (non-BLE) Transport.", atLevel: .debug)
            return
        }
        
        guard let bufferCount = response.bufferCount, var bufferSize = response.bufferSize else {
            self.log(msg: "Invalid McuMgr Parameters response received.", atLevel: .warning)
            storedMcuMgrParametersResponse = nil // just in case
            return
        }
        log(msg: "Mcu Manager parameters received (\(bufferCount) x \(bufferSize))", atLevel: .application)
        storedMcuMgrParametersResponse = response
        bufferSize = min(response.bufferSize, UInt64(UInt16.max))
        
        // Guard against soft-lock on first sequenceNumber upload
        if bufferSize < transport.mtu {
            do {
                log(msg: "SAR Buffer Size of \(bufferSize) is smaller than MTU Size of \(transport.mtu). Setting MTU Size to \(bufferSize).", atLevel: .debug)
                try setMtu(Int(bufferSize))
                if bleTransport.chunkSendDataToMtuSize {
                    log(msg: "Disabling Reassembly due to low Buffer Size of \(bufferSize) bytes.", atLevel: .debug)
                    bleTransport.chunkSendDataToMtuSize = false
                }
            } catch let mtuResetError {
                cancelTransfer(error: mtuResetError)
            }
        }
    }
    
    func patchReassemblyAndPipeliningSetup(using response: McuMgrParametersResponse) {
        guard let bleTransport = transport as? McuMgrBleTransport else {
            log(msg: "Skipping \(#function) due to unsupported (non-Bluetooth LE) Transport.", atLevel: .debug)
            return
        }
        
        let bufferSize: UInt64! = min(response.bufferSize, UInt64(UInt16.max))
        log(msg: "Setting SAR Buffer Size to \(bufferSize) bytes.", atLevel: .debug)
        uploadConfiguration.reassemblyBufferSize = bufferSize
        
        if let bufferCount = response.bufferCount, uploadConfiguration.pipelineDepth >= bufferCount {
            log(msg: "Target pipeline depth of \(bufferCount - 1) is smaller than upload configuration of \(uploadConfiguration.pipelineDepth).", atLevel: .warning)
            uploadConfiguration.pipelineDepth = Int(bufferCount - 1)
            uploadPipeline = McuMgrUploadPipeline(adopting: uploadConfiguration, over: transport)
            bleTransport.numberOfParallelWrites = uploadPipeline.depth
            log(msg: "Pipeline depth set to \(uploadPipeline.depth).", atLevel: .debug)
        }
        
        if bufferSize > bleTransport.mtu, !bleTransport.chunkSendDataToMtuSize {
            log(msg: "Enabling SMP Reassembly.", atLevel: .debug)
            bleTransport.chunkSendDataToMtuSize = true
        }
    }
    
    func finishedMcuMgrParametersRequest() {
        defaultManager = nil
        let fileName: String! = fileName
        let fileData: Data! = fileData
        log(msg: "Uploading \(fileName) (\(fileData.count) bytes)...", atLevel: .application)
        upload(name: fileName, data: fileData, offset: 0, callback: uploadCallback)
    }
    
    // MARK: sendNext(from:)
    
    func sendNext(from offset: UInt) {
        if transferState != .uploading {
            return
        }
        upload(name: fileName!, data: fileData!, offset: offset, callback: uploadCallback)
    }
    
    // MARK: requestNext(from:)
    
    func requestNext(from offset: UInt) {
        if transferState != .downloading {
            return
        }
        download(name: fileName!, offset: offset, callback: downloadCallback)
    }
    
    // MARK: resetTransfer
    
    private func resetTransfer() {
        objc_sync_enter(self)
        // Reset upload state.
        transferState = .none
        
        // Deallocate and nil file data pointers.
        fileData = nil
        fileName = nil
        fileSize = nil
        
        // Reset upload vars.
        offset = 0
        objc_sync_exit(self)
    }
    
    // MARK: restartTransfer
    
    private func restartTransfer() {
        objc_sync_enter(self)
        transferState = .none
        if let uploadDelegate = uploadDelegate {
            _ = upload(name: fileName!, data: fileData!,
                       using: uploadConfiguration, delegate: uploadDelegate)
        } else if let downloadDelegate = downloadDelegate {
            _ = download(name: fileName!, delegate: downloadDelegate)
        }
        objc_sync_exit(self)
    }
    
    // MARK: Packet Calculation
    
    private func calculatePacketOverhead(for name: String, data: Data, offset: UInt64) -> Int {
        let dataLength = UInt64(data.count)
        let payload = buildPayload(for: name, data: data, at: offset, with: dataLength)
        
        // Build the packet and return the size.
        let packet = McuManager.buildPacket(scheme: transport.getScheme(), version: .SMPv2,
                                            op: .write, flags: 0, group: group.rawValue,
                                            sequenceNumber: 0, commandId: FilesystemID.file,
                                            payload: payload)
        var packetOverhead = packet.count + 5
        if transport.getScheme().isCoap() {
            // Add 25 bytes to packet overhead estimate for the CoAP header.
            packetOverhead = packetOverhead + 25
        }
        return packetOverhead
    }
    
    // MARK: buildPayload(for:at:)
    
    private func buildPayload(for name: String, data: Data, at offset: UInt64, with length: UInt64) -> [String: CBOR] {
        // Get the Mcu Manager header.
        var payload: [String: CBOR] = ["name": CBOR.utf8String(name),
                                       "data": CBOR.byteString([UInt8]([0])),
                                       "off":  CBOR.unsignedInt(offset)]
        // If this is the initial packet we have to include the length of the
        // entire file.
        if offset == 0 {
            payload.updateValue(CBOR.unsignedInt(UInt64(data.count)), forKey: "len")
        }
        return payload
    }
}

// MARK: - FileTransferError

public enum FileTransferError: Error, LocalizedError {
    case missingUploadConfiguration
    case invalidPayload
    case invalidData
    
    public var errorDescription: String? {
        switch self {
        case .missingUploadConfiguration:
            return "No valid (FirmwareUpgrade) Configuration was set for upload."
        case .invalidPayload:
            return "Response Payload Values Do Not Exist"
        case .invalidData:
            return "File Data Is Nil"
        }
    }
}

// MARK: - FileSystemManagerError

public enum FileSystemManagerError: UInt64, Error, LocalizedError {
    case noError = 0
    case unknown = 1
    case invalidName = 2
    case notFound = 3
    case isDirectory = 4
    case openFailed = 5
    case seekFailed = 6
    case readFailed = 7
    case truncateFailed = 8
    case deleteFailed = 9
    case writeFailed = 10
    case invalidOffset = 11
    case offsetLargerThanFile = 12
    case checksumHashNotFound = 13
    case mountingPointNotFound = 14
    case readOnlyFilesystem = 15
    case emptyFile = 16
    
    public var errorDescription: String? {
        switch self {
        case .noError:
            return "Success"
        case .unknown:
            return "Unknown error"
        case .invalidName:
            return "Specified file name is not valid"
        case .notFound:
            return "Specified file name does not exist"
        case .isDirectory:
            return "Specified file name is a directory, not a file"
        case .openFailed:
            return "Error occurred whilst attempting to open file"
        case .seekFailed:
            return "Error occurred whilst attempting to seek to an offset in a file"
        case .readFailed:
            return "Error occurred whilst attempting to read data from a file"
        case .truncateFailed:
            return "Error occurred whilst attempting to truncate a file"
        case .deleteFailed:
            return "Error occurred whilst attempting to delete a file"
        case .writeFailed:
            return "Error occurred whilst attempting to write data to a file"
        case .invalidOffset:
            return "Specified data offset within a file is invalid"
        case .offsetLargerThanFile:
            return "Requested offset is larger than the size of the file on the device"
        case .checksumHashNotFound:
            return "Requested hash or checksum was not found or is not supported"
        case .mountingPointNotFound:
            return "Requested mounting point was not found or is not mounted"
        case .readOnlyFilesystem:
            return "Specified mount point only supports read-only operations"
        case .emptyFile:
            return "Requested operation cannot be performed due to file being empty with no contents"
        }
    }
}

// MARK: - FileUploadDelegate

public protocol FileUploadDelegate: AnyObject {
    
    /// Called when a packet of file data has been sent successfully.
    ///
    /// - parameter bytesSent: The total number of file bytes sent so far.
    /// - parameter fileSize:  The overall size of the file being uploaded.
    /// - parameter timestamp: The time this response packet was received.
    func uploadProgressDidChange(bytesSent: Int, fileSize: Int, timestamp: Date)
    
    /// Called when an file upload has failed.
    ///
    /// - parameter error: The error that caused the upload to fail.
    func uploadDidFail(with error: Error)
    
    /// Called when the upload has been cancelled.
    func uploadDidCancel()
    
    /// Called when the upload has finished successfully.
    func uploadDidFinish()
}

// MARK: - FileDownloadDelegate

public protocol FileDownloadDelegate: AnyObject {
    
    /// Called when a packet of file data has been sent successfully.
    ///
    /// - parameter bytesDownloaded: The total number of file bytes received so far.
    /// - parameter fileSize:        The overall size of the file being downloaded.
    /// - parameter timestamp:       The time this response packet was received.
    func downloadProgressDidChange(bytesDownloaded: Int, fileSize: Int, timestamp: Date)
    
    /// Called when an file download has failed.
    ///
    /// - parameter error: The error that caused the download to fail.
    func downloadDidFail(with error: Error)
    
    /// Called when the download has been cancelled.
    func downloadDidCancel()
    
    /// Called when the download has finished successfully.
    ///
    /// - parameter name: The file name.
    /// - parameter data: The file content.
    func download(of name: String, didFinish data: Data)
}
