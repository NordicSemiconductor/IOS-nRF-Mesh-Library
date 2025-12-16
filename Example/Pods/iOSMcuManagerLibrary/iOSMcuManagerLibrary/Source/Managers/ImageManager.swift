/*
 * Copyright (c) 2017-2018 Runtime Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import CoreBluetooth
import SwiftCBOR

// MARK: - ImageManager

public class ImageManager: McuManager {
    
    // MARK: Image
    
    public struct Image {
        public let name: String?
        public let image: Int
        public let slot: Int
        public let content: McuMgrManifest.File.ContentType
        public let hash: Data
        public let data: Data
        
        /**
         Convenience initialiser.
         
         Please see ``init(name:image:slot:content:hash:data:)`` for more information.
         */
        public init(_ manifest: McuMgrManifest.File, hash: Data, data: Data) {
            self.init(name: manifest.file, image: manifest.image, slot: manifest.slot, content: manifest.content, hash: hash, data: data)
        }
        
        /**
         Default Initialiser.
         
         - Important:
         McuMgr firmware commands expect slot numbers limited to 0 (Primary) and 1 (Secondary). However, newer DFU package generation backends have began to adopt an ever-increasing slot number. So for example, whereas previously Image 1, Slot 1 would represent the Secondary slot for the Secondary core, a newer DFU package might list the same combination as Image 1, Slot 3. This can lead to errors being returned when sending McuMgr commands, so we patch the slot number in the initialiser back to Image 1, Slot 1 for maximum compatibility.
         
         - Parameters:
            - slot: set by default to `slot` 1 (Secondary). Other than for DirectXIP, this conforms to the user-expected behaviour of representing a slice of memory in the target Core (i.e. `image`) that is not currently running. See ``Discussion`` for important details.
            - content: This is a necessary aid for complex SUIT updates involving `suitCache` resources. It defaults to `.unknown` so as to not alter the behavior of unrelated DFU operations. It can be set to other, more descriptive values, but improper use might cause erratic upload behavior.
         */
        public init(name: String? = nil, image: Int, slot: Int = 1,
                    content: McuMgrManifest.File.ContentType = .unknown, hash: Data, data: Data) {
            self.name = name
            self.image = image
            self.slot = slot % 2
            self.content = content
            self.hash = hash
            self.data = data
        }
        
        internal init(_ image: FirmwareUpgradeImage) {
            self.name = image.content.description
            self.image = image.image
            // Note that FirmwareUpgradeImage is itself derived from ImageManager.Image, so
            // there's no need to repeat the fix for the slot.
            self.slot = image.slot
            self.content = image.content
            self.hash = image.hash
            self.data = image.data
        }
        
        // MARK: imageName()
        
        public func imageName() -> String {
            if let name {
                return name
            }
            
            guard !hash.isEmpty else {
                return "Partition \(image)"
            }
            
            switch content {
            case .suitEnvelope:
                return "SUIT Envelope"
            default:
                let coreName: String
                switch image {
                case 0:
                    coreName = "App Core"
                case 1:
                    coreName = "Net Core"
                default:
                    coreName = "Image \(image)"
                }
                return "\(coreName) Slot \(slot)"
            }
        }
    }
    
    override class var TAG: McuMgrLogCategory { .image }
    
    private static let PIPELINED_WRITES_TIMEOUT_SECONDS = 10
    
    // MARK: - IDs

    enum ImageID: UInt8 {
        case state = 0
        case upload = 1
        case file = 2
        case coreList = 3
        case coreLoad = 4
        case erase = 5
        case slotInfo = 6
    }
    
    //**************************************************************************
    // MARK: Initializers
    //**************************************************************************

    public init(transport: McuMgrTransport) {
        super.init(group: McuMgrGroup.image, transport: transport)
    }
    
    //**************************************************************************
    // MARK: Commands
    //**************************************************************************

    /// List the images on the device.
    ///
    /// - parameter callback: The response callback.
    public func list(callback: @escaping McuMgrCallback<McuMgrImageStateResponse>) {
        send(op: .read, commandId: ImageID.state, payload: nil, callback: callback)
    }
    
    /// Sends the next packet of data from given offset.
    /// To send a complete image, use upload(data:image:delegate) method instead.
    ///
    /// - parameter data: The image data.
    /// - parameter image: The image number / slot number for DFU.
    /// - parameter offset: The offset from which this data will be sent.
    /// - parameter alignment: The byte alignment to apply to the data (if any).
    /// - parameter callback: The callback.
    public func upload(data: Data, image: Int, offset: UInt64, alignment: ImageUploadAlignment,
                       callback: @escaping McuMgrCallback<McuMgrUploadResponse>) {
        let packetOverhead = calculatePacketOverhead(data: data, image: image, offset: UInt64(offset))
        let payloadLength = maxDataPacketLengthFor(data: data, at: offset, with: packetOverhead, and: uploadConfiguration)
        
        let chunkOffset = offset
        let chunkEnd = min(chunkOffset + payloadLength, UInt64(data.count))
        var payload: [String:CBOR] = ["data": CBOR.byteString([UInt8](data[chunkOffset..<chunkEnd])),
                                      "off": CBOR.unsignedInt(chunkOffset)]
        let uploadTimeoutInSeconds: Int
        if chunkOffset == 0 {
            // 0 is Default behavior, so we can ignore adding it and
            // the firmware will do the right thing.
            if image > 0 {
                payload.updateValue(CBOR.unsignedInt(UInt64(image)), forKey: "image")
            }
            
            payload.updateValue(CBOR.unsignedInt(UInt64(data.count)), forKey: "len")
            payload.updateValue(CBOR.byteString([UInt8](data.sha256())), forKey: "sha")
            
            // When uploading offset 0, we might trigger an erase on the firmware's end.
            // Hence, the longer timeout.
            uploadTimeoutInSeconds = McuManager.DEFAULT_SEND_TIMEOUT_SECONDS
        } else {
            uploadTimeoutInSeconds = McuManager.FAST_TIMEOUT
        }
        send(op: .write, commandId: ImageID.upload, payload: payload, timeout: uploadTimeoutInSeconds,
             callback: callback)
    }
    
    /// Test the image with the provided hash.
    ///
    /// A successful test will put the image in a pending state. A pending image
    /// will be booted upon once upon reset, but not again unless confirmed.
    ///
    /// - parameter hash: The hash of the image to test.
    /// - parameter callback: The response callback.
    public func test(hash: [UInt8], callback: @escaping McuMgrCallback<McuMgrImageStateResponse>) {
        let payload: [String:CBOR] = ["hash": CBOR.byteString(hash),
                                      "confirm": CBOR.boolean(false)]
        send(op: .write, commandId: ImageID.state, payload: payload, callback: callback)
    }
    
    /// Confirm the image with the provided hash.
    ///
    /// A successful confirm will make the image permanent (i.e. the image will
    /// be booted upon reset).
    ///
    /// - parameter hash: The hash of the image to confirm. If not provided, the
    ///   current image running on the device will be made permanent.
    /// - parameter callback: The response callback.
    public func confirm(hash: [UInt8]? = nil, callback: @escaping McuMgrCallback<McuMgrImageStateResponse>) {
        var payload: [String:CBOR] = ["confirm": CBOR.boolean(true)]
        if let hash = hash {
            payload.updateValue(CBOR.byteString(hash), forKey: "hash")
        }
        send(op: .write, commandId: ImageID.state, payload: payload, callback: callback)
    }
    
    /// Begins the image upload to a peripheral.
    ///
    /// An instance of ImageManager can only have one upload in progress at a
    /// time, but we support uploading multiple images in a single call. If
    /// this method is called multiple times on the same ImageManager instance,
    /// all calls after the first will return false. Upload progress is reported
    /// asynchronously to the delegate provided in this method.
    ///
    /// - parameter images: The images to upload.
    /// - parameter configuration: The parameters used during the upgrade process. Set with defaults if not provided.
    /// - parameter delegate: The delegate to receive progress callbacks.
    ///
    /// - returns: True if the upload has started successfully, false otherwise.
    public func upload(images: [Image], using configuration: FirmwareUpgradeConfiguration = FirmwareUpgradeConfiguration(),
                       delegate: ImageUploadDelegate?) -> Bool {
        // Make sure two uploads cant start at once.
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        // If upload is already in progress or paused, do not continue.
        if uploadState == .none {
            // Set upload flag to true.
            uploadState = .uploading
        } else {
            log(msg: "An image upload is already in progress", atLevel: .warning)
            return false
        }
        
        guard let firstImage = images.first else {
            log(msg: "Nothing to upload", atLevel: .warning)
            return false
        }
        
        // Set upload delegate.
        uploadDelegate = delegate
        
        uploadImages = images
        
        // Set image data.
        imageData = firstImage.data
        
        // Set the slot we're uploading the image to.
        // Grab a strong reference to something holding a strong reference to self.
        cyclicReferenceHolder = { return self }
        uploadIndex = 0
        uploadLastOffset = 0
        // Note that pipelining requires the use of byte-alignment, otherwise we
        // can't predict how many bytes the firmware will accept in each chunk.
        uploadConfiguration = configuration
        // Don't exceed UInt16.max payload size.
        uploadConfiguration.reassemblyBufferSize = min(uploadConfiguration.reassemblyBufferSize, UInt64(UInt16.max))
        uploadPipeline = McuMgrUploadPipeline(adopting: uploadConfiguration, over: transport)
        
        log(msg: "Uploading Image \(firstImage.image) with Target Slot \(firstImage.slot) (\(firstImage.data.count) bytes)...", atLevel: .verbose)
        upload(data: firstImage.data, image: firstImage.image, offset: 0,
               alignment: configuration.byteAlignment,
               callback: uploadCallback)
        return true
    }

    // MARK: erase
    
    /**
     Erases an unconfirmed image slot from the target device.
     
     There will be errors if the target slot is confirmed, marked for test on next reboot, or is an active image for a split image (perhaps DirectXiP?) setup.
     
     - parameter image: By default, if set to `nil`, McuMgr will erase the slot that is not currently active. See `Discussion` section for more.
     - parameter slot: By default, if set to `nil`, McuMgr will erase the slot that is not currently active. See `Discussion` section for more.
     - parameter callback: The response callback.
     
     - note: We are aware that other APIs, such as ``test(hash:callback:)`` and ``confirm(hash:callback:)`` use the slot's `hash` as a parameter. This API does not, because we're mirroring Zephyr / McuMgr's own API. So yes, we too, wish it were consistent.
     - important: Both `image` and `slot` parameters are needed for a targetted (`image`, `slot`) combination to be sent with this API call. Otherwise, the target firmware will revert to its default behaviour which, is to erase the secondary slot that is not marked as active (i.e. booted / running from). This is as [per Zephyr Documentation](https://github.com/nrfconnect/sdk-zephyr/blob/f7859899ec7dbb21e0580eef25b229bda727f04a/subsys/mgmt/mcumgr/grp/img_mgmt/src/img_mgmt.c#L450).
     */
    public func erase(image: Int? = nil, slot: Int? = nil, callback: @escaping McuMgrCallback<McuMgrResponse>) {
        var payload: [String: CBOR]?
        if let image, let slot {
            let convertedSlotParameter = 2 * image + slot
            payload = ["slot": CBOR.unsignedInt(UInt64(convertedSlotParameter))]
        }
        send(op: .write, commandId: ImageID.erase, payload: payload, callback: callback)
    }
    
    /// Request core dump on the device. The data will be stored in the dump
    /// area.
    ///
    /// - parameter callback: The response callback.
    public func coreList(callback: @escaping McuMgrCallback<McuMgrResponse>) {
        send(op: .read, commandId: ImageID.coreList, payload: nil, callback: callback)
    }
    
    /// Read core dump from the given offset.
    ///
    /// - parameter offset: The offset to load from, in bytes.
    /// - parameter callback: The response callback.
    public func coreLoad(offset: UInt, callback: @escaping McuMgrCallback<McuMgrCoreLoadResponse>) {
        let payload: [String:CBOR] = ["off": CBOR.unsignedInt(UInt64(offset))]
        send(op: .read, commandId: ImageID.coreLoad, payload: payload, callback: callback)
    }

    /// Erase the area if it has a core dump, or the header is empty.
    ///
    /// - parameter callback: The response callback.
    public func coreErase(callback: @escaping McuMgrCallback<McuMgrResponse>) {
        send(op: .write, commandId: ImageID.coreLoad, payload: nil, callback: callback)
    }
    
    /**
     The command is used for fetching information on slots that are available.
     
     - parameter callback: The response callback.
     */
    public func slotInfo(callback: @escaping McuMgrCallback<McuMgrSlotInfoResponse>) {
        send(op: .read, commandId: ImageID.slotInfo, payload: nil, callback: callback)
    }
    
    //**************************************************************************
    // MARK: Image Upload
    //**************************************************************************

    /// Image upload states
    public enum UploadState: UInt8 {
        case none      = 0
        case uploading = 1
        case paused    = 2
    }
    
    /// State of the image upload.
    private var uploadState: UploadState = .none
    
    /// Contains the current Image's data to send to the device.
    private var imageData: Data?
    /// Image 'slot' or core of the device we're sending data to.
    /// Default value, will be secondary slot of core 0.
    private var uploadIndex: Int = 0
    /// Current image byte offset to send from.
    private var uploadLastOffset: UInt64!
    
    private var uploadPipeline: McuMgrUploadPipeline!
    
    /// The sequence of images we want to send to the device.
    private var uploadImages: [Image]?
    /// Delegate to send image upload updates to.
    private weak var uploadDelegate: ImageUploadDelegate?
    /// Groups multiple Settings regarding DFU Upload, such as enabling Pipelining,
    /// Byte Alignment and/or SMP Reassembly.
    private var uploadConfiguration: FirmwareUpgradeConfiguration!
    
    /// Cyclic reference is used to prevent from releasing the manager
    /// in the middle of an update. The reference cycle will be set
    /// when upload was started and released on success, error or cancel.
    private var cyclicReferenceHolder: (() -> ImageManager)?
    
    /// Cancels the current upload.
    ///
    /// If an error is supplied, the delegate's didFailUpload method will be
    /// called with the Upload Error provided.
    ///
    /// - parameter error: The optional upload error which caused the
    ///   cancellation. This error (if supplied) is used as the argument for the
    ///   delegate's didFailUpload method.
    public func cancelUpload(error: Error? = nil) {
        objc_sync_enter(self)
        if uploadState == .none {
            log(msg: "Image upload is not in progress", atLevel: .warning)
        } else {
            if let error {
                resetUploadVariables()
                uploadDelegate?.uploadDidFail(with: error)
                uploadDelegate = nil
                log(msg: "Upload cancelled due to error: \(error)", atLevel: .error)
                // Release cyclic reference.
                cyclicReferenceHolder = nil
            } else {
                if uploadState == .paused {
                    log(msg: "Upload paused", atLevel: .application)
                } else {
                    resetUploadVariables()
                    uploadDelegate?.uploadDidCancel()
                    log(msg: "Upload cancelled", atLevel: .application)
                }
                uploadDelegate = nil
                // Release cyclic reference.
                cyclicReferenceHolder = nil
            }
            uploadState = .none
        }
        objc_sync_exit(self)
    }
    
    /// Pauses the current upload. If there is no upload in progress, nothing
    /// happens.
    public func pauseUpload() {
        objc_sync_enter(self)
        if uploadState == .none {
            log(msg: "Upload is not in progress and therefore cannot be paused", atLevel: .warning)
        } else {
            uploadState = .paused
            log(msg: "Upload paused", atLevel: .application)
        }
        objc_sync_exit(self)
    }

    /// Continues a paused upload. If the upload is not paused or not uploading,
    /// nothing happens.
    public func continueUpload() {
        objc_sync_enter(self)
        guard let imageData = imageData else {
            objc_sync_exit(self)
            if uploadState != .none {
                cancelUpload(error: ImageUploadError.invalidData)
            }
            return
        }
        if uploadState == .paused {
            let image: Int! = self.uploadImages?[uploadIndex].image
            uploadState = .uploading
            let offset = uploadLastOffset ?? 0
            log(msg: "Resuming uploading image \(image) from \(offset)/\(imageData.count)...", atLevel: .application)
            upload(data: imageData, image: image, offset: offset, alignment: uploadConfiguration.byteAlignment,
                   callback: uploadCallback)
        } else {
            log(msg: "Upload has not been previously paused", atLevel: .warning)
        }
        objc_sync_exit(self)
    }
    
    // MARK: - Image Upload Private Methods
    
    private lazy var uploadCallback: McuMgrCallback<McuMgrUploadResponse> = {
        [weak self] (response: McuMgrUploadResponse?, error: Error?) in
        // Ensure the manager is not released.
        guard let self else { return }
        dispatchPrecondition(condition: .onQueue(.main))
        
        // Check for an error.
        if let error {
            if case let McuMgrTransportError.insufficientMtu(newMtu) = error {
                do {
                    try self.setMtu(newMtu)
                    self.restartUpload()
                } catch let mtuResetError {
                    self.cancelUpload(error: mtuResetError)
                }
                return
            }
            self.cancelUpload(error: error)
            return
        }
        
        // If response includes 'match' value, it should be true.
        // Else, we assume everything is OK.
        guard response?.match ?? true else {
            self.cancelUpload(error: ImageUploadError.offsetMismatch)
            return
        }
        
        // Make sure the image data is set.
        guard let currentImageData = self.imageData, let images = self.uploadImages else {
            self.cancelUpload(error: ImageUploadError.invalidData)
            return
        }
        // Make sure the response is not nil.
        guard let response else {
            self.cancelUpload(error: ImageUploadError.invalidPayload)
            return
        }
        
        if let error = response.getError() {
            self.cancelUpload(error: error)
            return
        }
        
        if let offset = response.off {
            self.uploadLastOffset = offset
            self.uploadPipeline.receivedData(with: offset)
            
            self.uploadDelegate?.uploadProgressDidChange(bytesSent: Int(self.uploadLastOffset), imageSize: currentImageData.count, timestamp: Date())
            
            if self.uploadState == .none {
                self.log(msg: "Upload cancelled", atLevel: .application)
                self.resetUploadVariables()
                self.uploadDelegate?.uploadDidCancel()
                self.uploadDelegate = nil
                // Release cyclic reference.
                self.cyclicReferenceHolder = nil
                return
            }
            
            guard self.uploadState == .uploading else { return }
            
            // Check if the upload has completed.
            if offset == currentImageData.count {
                if self.uploadIndex == images.count - 1 {
                    self.log(msg: "Upload finished (\(self.uploadIndex + 1) of \(images.count))", atLevel: .application)
                    self.resetUploadVariables()
                    self.uploadDelegate?.uploadDidFinish()
                    self.uploadDelegate = nil
                    // Release cyclic reference.
                    self.cyclicReferenceHolder = nil
                } else {
                    self.uploadDelegate?.uploadProgressDidChange(
                        bytesSent: images[self.uploadIndex].data.count,
                        imageSize: images[self.uploadIndex].data.count,
                        timestamp: Date())
                    self.log(msg: "Uploaded image \(images[self.uploadIndex].image) (\(self.uploadIndex + 1) of \(images.count))", atLevel: .application)
                    
                    // Don't trigger writes to another image unless all write(s) have returned for
                    // the current one.
                    guard self.uploadPipeline.allPacketsReceived() else {
                        return
                    }
                    
                    // Move on to the next image.
                    self.uploadIndex += 1
                    self.uploadLastOffset = 0
                    self.imageData = images[self.uploadIndex].data
                    let imageSize = images[self.uploadIndex].data.count
                    self.log(msg: "Uploading image \(images[self.uploadIndex].image) with Target Slot \(images[self.uploadIndex].slot) (\(imageSize) bytes)...", atLevel: .application)
                    self.uploadDelegate?.uploadProgressDidChange(bytesSent: 0, imageSize: imageSize, timestamp: Date())
                    self.sendNext(from: UInt64(0))
                }
                return
            }
            
            let imageData: Data! = self.uploadImages?[self.uploadIndex].data
            let imageSlot: Int! = self.uploadImages?[self.uploadIndex].image
            self.uploadPipeline.pipelinedSend(ofSize: imageData.count) { [unowned self] offset in
                let packetOverhead = self.calculatePacketOverhead(data: imageData, image: imageSlot, offset: UInt64(offset))
                let payloadLength = self.maxDataPacketLengthFor(data: imageData, at: offset, with: packetOverhead, and: self.uploadConfiguration)
                self.sendNext(from: offset)
                return offset + payloadLength
            }
        } else {
            self.cancelUpload(error: ImageUploadError.invalidPayload)
        }
    }
    
    private func sendNext(from offset: UInt64) {
        let imageData: Data! = uploadImages?[uploadIndex].data
        let imageSlot: Int! = uploadImages?[uploadIndex].image
        upload(data: imageData, image: imageSlot, offset: offset,
               alignment: uploadConfiguration.byteAlignment,
               callback: uploadCallback)
    }
    
    private func resetUploadVariables() {
        objc_sync_enter(self)
        // Reset upload state.
        uploadState = .none
        
        // Deallocate and nil image data pointers.
        imageData = nil
        uploadImages = nil
        uploadPipeline = nil
        
        // Reset upload vars.
        uploadIndex = 0
        objc_sync_exit(self)
    }
    
    private func restartUpload() {
        objc_sync_enter(self)
        guard let uploadImages = uploadImages, let uploadDelegate = uploadDelegate else {
            log(msg: "Could not restart upload: image data or callback is null", atLevel: .error)
            return
        }
        let tempUploadImages = uploadImages
        let tempUploadIndex = uploadIndex
        let tempDelegate = uploadDelegate
        resetUploadVariables()
        let remainingImages = tempUploadImages.filter({ $0.image >= tempUploadIndex })
        _ = upload(images: remainingImages, using: uploadConfiguration, delegate: tempDelegate)
        objc_sync_exit(self)
    }
    
    private func calculatePacketOverhead(data: Data, image: Int, offset: UInt64) -> Int {
        // Get the Mcu Manager header.
        var payload: [String:CBOR] = ["data": CBOR.byteString([UInt8]([0])),
                                      "off":  CBOR.unsignedInt(offset)]
        // If this is the initial packet we have to include the length of the
        // entire image.
        if offset == 0 {
            if image > 0 {
                payload.updateValue(CBOR.unsignedInt(UInt64(image)), forKey: "image")
            }
            
            payload.updateValue(CBOR.unsignedInt(UInt64(data.count)), forKey: "len")
            payload.updateValue(CBOR.byteString([UInt8](data.sha256())), forKey: "sha")
        }
        // Build the packet and return the size.
        let packet = McuManager.buildPacket(scheme: transport.getScheme(), version: .SMPv2,
                                            op: .write, flags: 0, group: group.rawValue,
                                            sequenceNumber: 0, commandId: ImageID.upload,
                                            payload: payload)
        var packetOverhead = packet.count + 5
        if transport.getScheme().isCoap() {
            // Add 25 bytes to packet overhead estimate for the CoAP header.
            packetOverhead = packetOverhead + 25
        }
        return packetOverhead
    }
}

// MARK: - ImageUploadAlignment

public enum ImageUploadAlignment: UInt64, Codable, CaseIterable, CustomStringConvertible, CustomDebugStringConvertible {
    
    case disabled = 0
    case twoByte = 2
    case fourByte = 4
    case eightByte = 8
    case sixteenByte = 16
    
    public var description: String {
        guard self != .disabled else { return "Disabled" }
        return "\(rawValue)-byte"
    }
    
    public var debugDescription: String { description }
}

// MARK: - ImageUploadError

public enum ImageUploadError: Error, LocalizedError {
    /// Response payload values do not exist.
    case invalidPayload
    /// Image Data is nil.
    case invalidData
    /// Response payload reports package offset does not match expected value.
    case offsetMismatch
    
    case invalidUploadSequenceNumber(McuSequenceNumber)
    
    public var errorDescription: String? {
        switch self {
        case .invalidPayload:
            return "Response payload values do not exist"
        case .invalidData:
            return "Image data is nil"
        case .offsetMismatch:
            return "Response payload reports package offset does not match expected value"
        case .invalidUploadSequenceNumber(let sequenceNumber):
            return "Received Response for unknown Sequence Number \(sequenceNumber)"
        }
    }
}

// MARK: - ImageManagerError

public enum ImageManagerError: UInt64, Error, LocalizedError {
    case noError = 0
    case unknown = 1
    case flashConfigurationQueryFailure = 2
    case noImage = 3
    case noTLVs = 4
    case invalidTLV = 5
    case tlvHashCollision = 6
    case tlvInvalidSize = 7
    case hashNotFound = 8
    case fullSlots = 9
    case flashOpenFailed = 10
    case flashReadFailed = 11
    case flashWriteFailed = 12
    case flashEraseFailed = 13
    case invalidSlot = 14
    case mallocFailed = 15
    case flashContextAlreadySet = 16
    case flashContextNotSet = 17
    case flashAreaNull = 18
    case invalidPageOffset = 19
    case missingOffset = 20
    case missingLength = 21
    case invalidImageHeader = 22
    case invalidImageHeaderMagic = 23
    case invalidHash = 24
    case invalidFlashAddress = 25
    case versionGetFailed = 26
    case newerCurrentVersion = 27
    case imageAlreadyPending = 28
    case invalidImageVectorTable = 29
    case invalidImageTooLarge = 30
    case invalidImageDataOverrun = 31
    case imageConfirmationDenied = 32
    case imageSettingTestToActiveDenied = 33
    case activeSlotNotKnown = 34

    public var errorDescription: String? {
        switch self {
        case .noError:
            return "Success"
        case .unknown:
            return "Unknown error"
        case .flashConfigurationQueryFailure:
            return "Failed to query flash area configuration"
        case .noImage:
            return "There's no image in the slot"
        case .noTLVs:
            return "Slot image is missing TLV information"
        case .invalidTLV:
            return "Slot image has an invalid TLV type and/or length"
        case .tlvHashCollision:
            return "Slot image has multiple hash TLVs, which is invalid"
        case .tlvInvalidSize:
            return "Slot image has an invalid TLV size"
        case .hashNotFound:
            return "Slot image has no hash TLV"
        case .fullSlots:
            return "There is no free slot to place the image"
        case .flashOpenFailed:
            return "Flash area opening failed"
        case .flashReadFailed:
            return "Flash area reading failed"
        case .flashWriteFailed:
            return "Flash area writing failed"
        case .flashEraseFailed:
            return "Flash area erasing failed"
        case .invalidSlot:
            return "Given slot is not valid"
        case .mallocFailed:
            return "Insufficient heap memory (malloc failed)"
        case .flashContextAlreadySet:
            return "Flash context is already set"
        case .flashContextNotSet:
            return "Flash context is not set"
        case .flashAreaNull:
            return "device for the flash area is null"
        case .invalidPageOffset:
            return "Invalid page number offset"
        case .missingOffset:
            return "Required offset parameter not found"
        case .missingLength:
            return "Required length parameter not found"
        case .invalidImageHeader:
            return "Image length is smaller than the size of an image header"
        case .invalidImageHeaderMagic:
            return "Image header magic value does not match the expected value"
        case .invalidHash:
            return "Invalid hash parameter"
        case .invalidFlashAddress:
            return "Image load address does not match the address of the flash area"
        case .versionGetFailed:
            return "Failed to get version of currently running application"
        case .newerCurrentVersion:
            return "Currently running application is newer than uploading version"
        case .imageAlreadyPending:
            return "Image operation already pending"
        case .invalidImageVectorTable:
            return "Image vector table is invalid"
        case .invalidImageTooLarge:
            return "Image is too large to fit"
        case .invalidImageDataOverrun:
            return "Data sent is larger than the provided image size"
        case .imageConfirmationDenied:
            return "Image confirmation denied"
        case .imageSettingTestToActiveDenied:
            return "Setting active slot to test is not allowed"
        case .activeSlotNotKnown:
            return "Unable to determine current Image's active slot"
        }
    }
}

//******************************************************************************
// MARK: Image Upload Delegate
//******************************************************************************

public protocol ImageUploadDelegate: AnyObject {
    
    /// Called when a packet of image data has been sent successfully.
    ///
    /// - parameter bytesSent: The total number of image bytes sent so far.
    /// - parameter imageSize: The overall size of the image being uploaded.
    /// - parameter timestamp: The time this response packet was received.
    func uploadProgressDidChange(bytesSent: Int, imageSize: Int, timestamp: Date)

    /// Called when an image upload has failed.
    ///
    /// - parameter error: The error that caused the upload to fail.
    func uploadDidFail(with error: Error)
    
    /// Called when the upload has been cancelled.
    func uploadDidCancel()

    /// Called when the upload has finished successfully.
    func uploadDidFinish()
}

