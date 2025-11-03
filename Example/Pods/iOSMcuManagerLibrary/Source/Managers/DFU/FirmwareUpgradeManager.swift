/*
 * Copyright (c) 2017-2018 Runtime Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import CoreBluetooth

// MARK: - FirmwareUpgradeManager

public class FirmwareUpgradeManager: FirmwareUpgradeController, ConnectionObserver {
    
    // MARK: Private Properties
    
    private let imageManager: ImageManager
    private let defaultManager: DefaultManager
    private let basicManager: BasicManager
    private let suitManager: SuitManager
    private weak var delegate: FirmwareUpgradeDelegate?
    
    /// Cyclic reference is used to prevent from releasing the manager
    /// in the middle of an update. The reference cycle will be set
    /// when upgrade was started and released on success, error or cancel.
    private var cyclicReferenceHolder: (() -> FirmwareUpgradeManager)?
    
    private var images: [FirmwareUpgradeImage]!
    private var configuration: FirmwareUpgradeConfiguration!
    private var bootloader: BootloaderInfoResponse.Bootloader!
    
    private var state: FirmwareUpgradeState
    private var paused: Bool
    
    /// Logger delegate may be used to obtain logs.
    public weak var logDelegate: McuMgrLogDelegate? {
        didSet {
            imageManager.logDelegate = logDelegate
            defaultManager.logDelegate = logDelegate
            suitManager.logDelegate = logDelegate
        }
    }
    
    private var resetResponseTime: Date?
    
    // MARK: Init
    
    public init(transport: McuMgrTransport, delegate: FirmwareUpgradeDelegate?) {
        self.imageManager = ImageManager(transport: transport)
        self.defaultManager = DefaultManager(transport: transport)
        self.basicManager = BasicManager(transport: transport)
        self.suitManager = SuitManager(transport: transport)
        self.delegate = delegate
        self.state = .none
        self.paused = false
    }
    
    // MARK: start(package:using:)
    
    /// Start the firmware upgrade.
    ///
    /// This is the full-featured API to start DFU update, including support for Multi-Image uploads, DirectXIP, and SUIT. It is a seamless API.
    /// - parameter package: The (`McrMgrPackage`) to upload.
    /// - parameter configuration: Fine-tuning of details regarding the upgrade process.
    public func start(package: McuMgrPackage,
                      using configuration: FirmwareUpgradeConfiguration = FirmwareUpgradeConfiguration()) {
        guard package.isForSUIT else {
            start(images: package.images, using: configuration)
            return
        }
        
        var suitConfiguration = configuration
        suitConfiguration.upgradeMode = .uploadOnly
        // Erase App Settings is not supported by SUIT Bootloader.
        suitConfiguration.eraseAppSettings = false
        start(images: package.images, using: suitConfiguration)
    }
    
    /// Start the firmware upgrade.
    ///
    /// Use this convenience call of ``start(images:using:)`` if you're only
    /// updating the App Core (i.e. no Multi-Image).
    /// - parameter hash: The hash of the Image to be uploaded, used for comparison with the target firmware.
    /// - parameter data: `Data` to upload to App Core (Image 0).
    /// - parameter configuration: Fine-tuning of details regarding the upgrade process.
    @available(*, deprecated, message: "start(package:using:) is now a far more convenient call. Therefore this API is henceforth marked as deprecated and will be removed in a future release.")
    public func start(hash: Data, data: Data, using configuration: FirmwareUpgradeConfiguration = FirmwareUpgradeConfiguration()) {
        start(images: [ImageManager.Image(image: 0, hash: hash, data: data)],
                  using: configuration)
    }
    
    /// Start the firmware upgrade.
    ///
    /// This is the full-featured API to start DFU update, including support for Multi-Image uploads.
    /// - parameter images: An Array of (`ImageManager.Image`) to upload.
    /// - parameter configuration: Fine-tuning of details regarding the upgrade process.
    public func start(images: [ImageManager.Image], using configuration: FirmwareUpgradeConfiguration = FirmwareUpgradeConfiguration()) {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        self.imageManager.verifyOnMainThread()
        guard state == .none else {
            log(msg: "Firmware upgrade is already in progress", atLevel: .warning)
            return
        }
        
        self.images = images.map { FirmwareUpgradeImage($0) }
        self.configuration = configuration
        self.bootloader = nil
        
        // Grab a strong reference to something holding a strong reference to self.
        cyclicReferenceHolder = { return self }
        
        log(msg: "Upgrade started with \(images.count) image(s) using '\(configuration.upgradeMode)' mode",
            atLevel: .application)
        delegate?.upgradeDidStart(controller: self)
        
        requestMcuMgrParameters()
    }
    
    /**
     For SUIT (Software Update for Internet of Things), the target device might request some resource via the ``SuitFirmwareUpgradeDelegate/uploadRequestsResource(_:)`` callback. After that happens, `FirmwareUpgradeManager` will wait until the requested ``FirmwareUpgradeResource`` is provided via this API.
     
     - parameter resource: The resource being provided ``FirmwareUpgradeResource``.
     - parameter data: The bytes of the resource itself.
     */
    public func uploadResource(_ resource: FirmwareUpgradeResource, data: Data) {
        objc_sync_enter(self)
        suitManager.uploadResource(data)
        objc_sync_exit(self)
    }
    
    public func cancel() {
        objc_sync_enter(self)
        if state == .upload {
            if bootloader == .suit {
                suitManager.cancel()
            } else {
                imageManager.cancelUpload()
            }
            paused = false
        }
        objc_sync_exit(self)
    }
    
    public func pause() {
        objc_sync_enter(self)
        if state.isInProgress() && !paused {
            paused = true
            if state == .upload {
                if bootloader == .suit {
                    suitManager.pause()
                } else {
                    imageManager.pauseUpload()
                }
            }
        }
        objc_sync_exit(self)
    }
    
    public func resume() {
        objc_sync_enter(self)
        if paused {
            paused = false
            resumeFromCurrentState()
        }
        objc_sync_exit(self)
    }
    
    public func isPaused() -> Bool {
        return paused
    }
    
    public func isInProgress() -> Bool {
        return state.isInProgress() && !paused
    }
    
    public func setUploadMtu(mtu: Int) throws {
        try imageManager.setMtu(mtu)
    }
    
    //**************************************************************************
    // MARK: Firmware Upgrade State Machine
    //**************************************************************************
    
    private func objc_sync_setState(_ state: FirmwareUpgradeState) {
        objc_sync_enter(self)
        let previousState = self.state
        self.state = state
        if state != previousState {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.upgradeStateDidChange(from: previousState, to: state)
            }
        }
        objc_sync_exit(self)
    }
    
    private func requestMcuMgrParameters() {
        objc_sync_setState(.requestMcuMgrParameters)
        if !paused {
            log(msg: "Requesting McuMgr Parameters...", atLevel: .verbose)
            defaultManager.params(callback: mcuManagerParametersCallback)
        }
    }
    
    private func bootloaderInfo() {
        objc_sync_setState(.bootloaderInfo)
        if !paused {
            log(msg: "Requesting Bootloader Info...", atLevel: .verbose)
            defaultManager.bootloaderInfo(query: .name, callback: bootloaderInfoCallback)
        }
    }
    
    private func bootloaderMode() {
        objc_sync_setState(.bootloaderInfo)
        if !paused {
            log(msg: "Requesting Bootloader Mode...", atLevel: .verbose)
            defaultManager.bootloaderInfo(query: .mode, callback: bootloaderModeCallback)
        }
    }
    
    private func validate() {
        objc_sync_setState(.validate)
        if !paused {
            log(msg: "Sending Image List command...", atLevel: .verbose)
            imageManager.list(callback: listCallback)
        }
    }
    
    private func upload() {
        objc_sync_setState(.upload)
        if !paused {
            let imagesToUpload = images
                .filter { !$0.uploaded }
                .map { ImageManager.Image($0) }
            guard !imagesToUpload.isEmpty else {
                log(msg: "Nothing to be uploaded", atLevel: .application)
                // Allow Library Apps to show 100% Progress in this case.
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.uploadProgressDidChange(bytesSent: 100, imageSize: 100, 
                                                            timestamp: Date())
                }
                uploadDidFinish()
                return
            }
            for image in imagesToUpload {
                let hash = (try? McuMgrImage(data: image.data).hash)
                let hashString = hash?.hexEncodedString(options: [.prepend0x, .upperCase]) ?? "Unknown"
                log(msg: "Scheduling upload (hash: \(hashString)) for image \(image.image) (slot: \(image.slot))", atLevel: .application)
            }
            _ = imageManager.upload(images: imagesToUpload, using: configuration, delegate: self)
        }
    }
    
    private func test(_ image: FirmwareUpgradeImage) {
        objc_sync_setState(.test)
        if !paused {
            log(msg: "Sending Image Test command for image \(image.image) (slot: \(image.slot))...", atLevel: .verbose)
            imageManager.test(hash: [UInt8](image.hash), callback: testCallback)
        }
    }
    
    private func confirm(_ image: FirmwareUpgradeImage) {
        objc_sync_setState(.confirm)
        if !paused {
            log(msg: "Sending Image Confirm command to image \(image.image) (slot \(image.slot))...", atLevel: .verbose)
            imageManager.confirm(hash: [UInt8](image.hash), callback: confirmCallback)
        }
    }
    
    private func confirmAsSUIT() {
        objc_sync_setState(.confirm)
        if !paused {
            log(msg: "Sending single Confirm command for SUIT upload (no Hash) via McuBoot...", atLevel: .verbose)
            imageManager.confirm(hash: nil, callback: confirmCallback)
        }
    }
    
    private func eraseAppSettings() {
        objc_sync_setState(.eraseAppSettings)
        log(msg: "Erasing app settings...", atLevel: .verbose)
        basicManager.eraseAppSettings(callback: eraseAppSettingsCallback)
    }
    
    private func reset() {
        objc_sync_setState(.reset)
        if !paused {
            log(msg: "Sending Reset command...", atLevel: .verbose)
            defaultManager.transport.addObserver(self)
            defaultManager.reset(callback: resetCallback)
        }
    }
    
    /**
     Called in .test&Confirm mode after uploaded images have been sent 'Test' command, they
     are tested, then Reset, and now we need to Confirm all Images.
     */
    private func testAndConfirmAfterReset() {
        if let untestedImage = images.first(where: { $0.uploaded && !$0.tested }) {
            self.fail(error: FirmwareUpgradeError.untestedImageFound(image: untestedImage.image, slot: untestedImage.slot))
            return
        }
        
        if let firstUnconfirmedImage = images.first(where: {
            $0.uploaded && !$0.confirmed && !$0.confirmSent }
        ) {
            confirm(firstUnconfirmedImage)
            mark(firstUnconfirmedImage, as: \.confirmSent)
        } else {
            // in .testAndConfirm, we test all uploaded images before Reset.
            // So if we're here after Reset and there's nothing to confirm, we're done.
            self.success()
        }
    }
    
    private func success() {
        objc_sync_setState(.success)
        
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        state = .none
        paused = false
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.upgradeDidComplete()
            // Release cyclic reference.
            self?.cyclicReferenceHolder = nil
        }
    }
    
    private func fail(error: Error) {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        var errorOverride = error
        if let mcuMgrError = error as? McuMgrError,
           case let McuMgrError.returnCode(returnCode) = mcuMgrError {
            if configuration.bootloaderMode.isBareMetal, returnCode == .unsupported {
                errorOverride = FirmwareUpgradeError.resetIntoBootloaderModeNeeded
            }
        }
        log(msg: errorOverride.localizedDescription, atLevel: .error)
        let tmp = state
        state = .none
        paused = false
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.upgradeDidFail(inState: tmp, with: errorOverride)
            // Release cyclic reference.
            self?.cyclicReferenceHolder = nil
        }
    }
    
    private func resumeFromCurrentState() {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        if !paused {
            switch state {
            case .requestMcuMgrParameters:
                requestMcuMgrParameters()
            case .validate:
                validate()
            case .upload:
                if bootloader == .suit {
                    suitManager.continueUpload()
                } else {
                    imageManager.continueUpload()
                }
            case .test:
                guard let nextImageToTest = images.first(where: { $0.uploaded && !$0.tested }) else { return }
                test(nextImageToTest)
                mark(nextImageToTest, as: \.testSent)
            case .reset:
                reset()
            case .confirm:
                guard let nextImageToConfirm = images.first(where: { $0.uploaded && !$0.confirmed }) else { return }
                confirm(nextImageToConfirm)
                mark(nextImageToConfirm, as: \.confirmSent)
            default:
                break
            }
        }
    }
    
    /**
     Used to check potential Uploads of SUIT Images via MCUBoot Bootloader, which requires adjustments.
     */
    private func uploadingSUITImages() -> Bool {
        return images.contains(where: {
            $0.content == .suitEnvelope || $0.content == .suitCache
        })
    }
    
    // MARK: McuMgr Parameters Callback
    
    /// Callback for devices running NCS firmware version 2.0 or later, which support McuMgrParameters call.
    ///
    /// Error handling here is not considered important because we don't expect many devices to support this.
    /// If this feature is not supported, the upload will take place with default parameters.
    private lazy var mcuManagerParametersCallback: McuMgrCallback<McuMgrParametersResponse> = { [weak self] response, error in
        guard let self else { return }
        
        guard error == nil, let response, response.rc.isSupported() else {
            self.log(msg: "Mcu Manager parameters not supported", atLevel: .warning)
            self.bootloaderInfo() // Continue to Bootloader Info.
            return
        }
        
        guard let bufferCount = response.bufferCount, var bufferSize = response.bufferSize else {
            self.log(msg: "Mcu Manager parameters did not return an error, but neither did it provide valide bufferCount nor bufferSize values.", atLevel: .warning)
            self.bootloaderInfo() // Continue to Bootloader Info.
            return
        }
        
        self.log(msg: "Mcu Manager parameters received (\(bufferCount) x \(bufferSize))", atLevel: .application)
        if bufferSize > UInt16.max {
            bufferSize = UInt64(UInt16.max)
            self.log(msg: "Parameters SAR Buffer Size is larger than maximum of \(UInt16.max) bytes. Reducing Buffer Size to maximum value.", atLevel: .warning)
        }
        self.log(msg: "Setting SAR Buffer Size to \(bufferSize) bytes.", atLevel: .verbose)
        self.configuration.reassemblyBufferSize = bufferSize
        self.bootloaderInfo() // Continue to Bootloader Mode.
    }
    
    // MARK: Bootloader Info Callback
    
    private lazy var bootloaderInfoCallback: McuMgrCallback<BootloaderInfoResponse> = { [weak self] response, error in
        guard let self else { return }
        
        guard error == nil, let response, response.rc.isSupported() else {
            self.log(msg: "Bootloader Info not supported.", atLevel: .warning)
            self.log(msg: "Assuming MCUBoot Bootloader.", atLevel: .debug)
            self.bootloader = .mcuboot
            // Detect SUIT via MCUBoot and override UpgradeMode
            if self.uploadingSUITImages(), self.configuration.upgradeMode == .uploadOnly {
                self.log(msg: "SUIT over MCUBoot Detected.", atLevel: .info)
                self.log(msg: "Override Upgrade Mode from \(FirmwareUpgradeMode.uploadOnly) to \(FirmwareUpgradeMode.confirmOnly) due to SUIT over MCUBoot.", atLevel: .debug)
                self.configuration.upgradeMode = .confirmOnly
            }
            self.validate() // Continue Upload
            return
        }
        
        self.log(msg: "Bootloader Info received (Name: \(response.bootloader?.description ?? "Unknown"))",
                 atLevel: .application)
        self.bootloader = response.bootloader
        if self.bootloader == .suit {
            self.log(msg: "Detected SUIT Bootloader. Skipping Bootloader Mode request.", atLevel: .debug)
            self.objc_sync_setState(.upload)
            let suitImages = self.images.map { ImageManager.Image($0) }
            self.suitManager.upload(suitImages, using: configuration, delegate: self)
        } else {
            // Query McuBoot Mode since SUIT does not support this request.
            self.bootloaderMode()
        }
    }
    
    // MARK: Bootloader Mode Callback
    
    private lazy var bootloaderModeCallback: McuMgrCallback<BootloaderInfoResponse> = { [weak self] response, error in
        guard let self else { return }
        
        guard error == nil, let response, response.rc.isSupported() else {
            self.log(msg: "Bootloader Mode not supported", atLevel: .warning)
            if self.bootloader == .mcuboot, self.uploadingSUITImages() {
                self.log(msg: "SUIT over MCUBoot Detected.", atLevel: .info)
            }
            // Override UpgradeMode if 'SUIT over MCUBoot'.
            if self.uploadingSUITImages(), self.configuration.upgradeMode == .uploadOnly {
                self.log(msg: "Override of Upgrade Mode from \(FirmwareUpgradeMode.uploadOnly) to \(FirmwareUpgradeMode.confirmOnly) due to SUIT over MCUBoot.", atLevel: .debug)
                self.configuration.upgradeMode = .confirmOnly
            }
            self.validate() // Continue Upload
            return
        }
        
        self.log(msg: "Bootloader Mode received (Mode: \(response.mode?.debugDescription ?? "Unknown"))",
                 atLevel: .application)
        self.configuration.bootloaderMode = response.mode ?? self.configuration.bootloaderMode
        switch self.configuration.bootloaderMode {
        case .directXIPWithRevert:
            // Mark all images as confirmed for DirectXIP No Revert, because there's no need.
            // No Revert means we just Reset and the firmware will handle it.
            for image in self.images {
                self.mark(image, as: \.confirmed)
            }
        case .firmwareLoader: // Bare Metal
            self.log(msg: "Bare Metal SDK Firmware Loader detected. Overriding target image slot to Primary (zero).", atLevel: .debug)
            self.images = self.images.map {
                $0.patchForBareMetal()
            }
        default:
            break
        }
        self.validate() // Continue Upload
    }
    
    // MARK: List Callback
    
    /// Callback for the List (VALIDATE) state.
    ///
    /// This callback will fail the upgrade on error and continue to the next
    /// state on success.
    private lazy var listCallback: McuMgrCallback<McuMgrImageStateResponse> = { [weak self] response, error in
        // Ensure the manager is not released.
        guard let self else { return }
        
        // Check for an error.
        if let error {
            self.fail(error: error)
            return
        }
        guard let response else {
            self.fail(error: FirmwareUpgradeError.unknown("Image List response is nil."))
            return
        }
        self.log(msg: "Image List response: \(response)", atLevel: .application)
        // Check for an error return code.
        if let error = response.getError() {
            self.fail(error: error)
            return
        }
        // Check that the image array exists.
        guard let responseImages = response.images, responseImages.count > 0 else {
            self.fail(error: FirmwareUpgradeError.invalidResponse(response))
            return
        }
        
        var discardedImages: [FirmwareUpgradeImage] = []
        // We need to loop over the indices, because we change the array from within it.
        // So 'for image in self.images' would make each 'image' not reflect changes.
        for i in self.images.indices {
            let image = self.images[i]
            guard !image.uploaded else { continue }
            
            // Look for corresponding image.
            let targetImage = responseImages.first(where: { $0.image == image.image })
            // Regardless of where we'd upload the image (slot), if the hash
            // matches then we don't need to do anything about it.
            if let targetImage, Data(targetImage.hash) == image.hash {
                self.targetSlotMatch(for: targetImage, to: image)
                continue // next Image.
            }
            
            guard !self.configuration.bootloaderMode.isBareMetal else {
                // Nothing to validate for Bare Metal. If hash doesn't match
                // (always targeting primary / slot 0) then we upload it.
                self.log(msg: "Scheduling Upload of Image \(image.image) to Bare Metal Firmware Loader.", atLevel: .debug)
                continue
            }
            
            let imageForAlternativeSlotAvailable = self.images.first(where: {
                $0.image == image.image && $0.slot != image.slot
            })
            
            // if (DirectXIP) basically
            if let imageForAlternativeSlotAvailable {
                // Do we need to upload this image?
                if let alternativeAlreadyUploaded = responseImages.first(where: {
                    $0.image == image.image && $0.slot == imageForAlternativeSlotAvailable.slot
                }), Data(alternativeAlreadyUploaded.hash) == imageForAlternativeSlotAvailable.hash {
                    self.log(msg: "Image \(image.image) has already been uploaded", atLevel: .debug)
                    
                    for skipImage in self.images ?? [] where skipImage.image == image.image {
                        // Remove all Target Slot(s) for this Image.
                        discardedImages.append(skipImage)
                        // Mark as Uploaded so we skip it over in the for-loop.
                        self.mark(skipImage, as: \.uploaded)
                    }
                    continue
                }
                
                // If we have the same Image but targeted for a different slot (DirectXIP),
                // we need to chose one of the two to upload.
                if let activeResponseImage = responseImages.first(where: {
                    $0.image == image.image && $0.active
                }), let activeImage = self.images.first(where: { $0.image == activeResponseImage.image && $0.slot == activeResponseImage.slot }) {
                    discardedImages.append(activeImage)
                    self.log(msg: "Two possible slots available. Image \(image.image) (slot: \(activeResponseImage.slot)) is active, uploading to the secondary slot", atLevel: .debug)
                }
            } else {
                self.validateSecondarySlotUpload(of: image, with: responseImages)
            }
        }
        
        // Remove discarded images.
        self.images = self.images.filter({
            !discardedImages.contains($0)
        })
        
        // If we start upload immediately the first sequence number chunks could be ignored
        // by the firware and upload would not continue until after the first (long) timeout.
        // So we introduce a delay. Ugh... Bluetooth.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            // Validation successful, begin with image upload.
            self?.upload()
        }
    }
    
    private func targetSlotMatch(for responseImage: McuMgrImageStateResponse.ImageSlot,
                                 to uploadImage: FirmwareUpgradeImage) {
        // The image is already active in the desired slot.
        // No need to upload it again.
        mark(uploadImage, as: \.uploaded)
        
        // If the image is already confirmed...
        if responseImage.confirmed {
            // ...there's no need to send any commands for this image.
            log(msg: "Image: \(uploadImage.image) (slot: \(uploadImage.image)) already active", atLevel: .debug)
            mark(uploadImage, as: \.confirmed)
            mark(uploadImage, as: \.tested)
        } else {
            // Otherwise, the image must be in test mode.
            log(msg: "Image \(uploadImage.image) (slot: \(uploadImage.image)) already active in Test Mode", atLevel: .debug)
            mark(uploadImage, as: \.tested)
        }
    }
    
    private func validateSecondarySlotUpload(of image: FirmwareUpgradeImage,
                                             with responseImages: [McuMgrImageStateResponse.ImageSlot]) {
        // Look for the corresponding image in the secondary slot.
        if let secondary = responseImages.first(where: { $0.image == image.image && $0.slot == 1 }) {
            // Check if the firmware has already been uploaded.
            if Data(secondary.hash) == image.hash {
                // Firmware is identical to the one in slot 1.
                // No need to send anything.
                mark(image, as: \.uploaded)

                // If the image was already confirmed...
                if secondary.permanent {
                    // ...check if we can continue.
                    // A confirmed image cannot be un-confirmed and made tested.
                    guard self.configuration.upgradeMode != .testOnly else {
                        fail(error: FirmwareUpgradeError.unknown("Image \(image.image) already confirmed. Can't be tested."))
                        return
                    }
                    log(msg: "Image \(image.image) (slot: \(secondary.slot)) already uploaded and confirmed", atLevel: .debug)
                    mark(image, as: \.confirmed)
                    return
                }
                
                // If the test command was sent to this image...
                if secondary.pending {
                    // ...mark it as tested.
                    log(msg: "Image \(image.image) (slot: \(secondary.slot)) already uploaded and tested", atLevel: .debug)
                    mark(image, as: \.tested)
                    return
                }
                
                // Otherwise, the test or confirm commands will be sent later, depending on the mode.
                log(msg: "Image \(image.image) already uploaded", atLevel: .debug)
            } else {
                // Seems like the secondary slot for this image number is already taken
                // by some other firmware.
                
                // If the image in secondary slot is confirmed, we won't be able to erase or
                // test the slot. Therefore, we confirm the image in the core's primary slot
                // to allow us to modify the image in the secondary slot.
                if secondary.confirmed {
                    guard let primary = responseImages.first(where: {
                        $0.image == image.image && $0.slot == image.slot
                    }) else { return }
                    log(msg: "Secondary slot of image \(image.image) is already confirmed", atLevel: .warning)
                    log(msg: "Confirming image \(primary.image) (slot: \(primary.slot))...", atLevel: .verbose)
                    listConfirm(image: primary)
                    return
                }

                // If the image in secondary slot is pending, we won't be able to
                // erase or test the slot. Therefore, we must reset the device
                // (which will swap and run the test image) and revalidate the new image state.
                if secondary.pending {
                    log(msg: "Image \(image.image) (slot \(secondary.slot)) is already pending", atLevel: .warning)
                    log(msg: "Resetting the device...", atLevel: .verbose)
                    // reset() can't be called here, as it changes the state to RESET.
                    defaultManager.transport.addObserver(self)
                    defaultManager.reset(callback: self.resetCallback)
                    // The validate() method will be called again.
                    return
                }
                // Otherwise, do nothing, as the old firmware will be overwritten by the new one.
                log(msg: "Secondary slot of image \(image.image) will be overwritten", atLevel: .warning)
            }
        }
    }
    
    private func listConfirm(image: McuMgrImageStateResponse.ImageSlot) {
        imageManager.confirm(hash: image.hash) { [weak self] response, error in
            guard let self = self else {
                return
            }
            if let error = error {
                self.fail(error: error)
                return
            }
            guard let response = response else {
                self.fail(error: FirmwareUpgradeError.unknown("Image Confirm response is nil."))
                return
            }
            self.log(msg: "Image Confirm response: \(response)", atLevel: .application)
            if let error = response.getError() {
                self.fail(error: error)
                return
            }
            // Check that the image array exists.
            guard let responseImages = response.images, responseImages.count > 0 else {
                self.fail(error: FirmwareUpgradeError.invalidResponse(response))
                return
            }
            // TODO: Perhaps adding a check to verify if the image was indeed confirmed?
            self.log(msg: "Image \(image.image) confirmed", atLevel: .debug)
            self.listCallback(response, nil)
        }
    }
    
    // MARK: Test Callback
    
    /// Callback for the TEST state.
    ///
    /// This callback will fail the upgrade on error and continue to the next
    /// state on success.
    private lazy var testCallback: McuMgrCallback<McuMgrImageStateResponse> = { [weak self] response, error in
        // Ensure the manager is not released.
        guard let self = self else {
            return
        }
        // Check for an error.
        if let error = error {
            self.fail(error: error)
            return
        }
        guard let response = response else {
            self.fail(error: FirmwareUpgradeError.unknown("Image Test response is nil."))
            return
        }
        self.log(msg: "Image Test response: \(response)", atLevel: .application)
        // Check for McuMgrReturnCode error.
        if let error = response.getError() {
            self.fail(error: error)
            return
        }
        // Check that the image array exists.
        guard let responseImages = response.images else {
            self.fail(error: FirmwareUpgradeError.invalidResponse(response))
            return
        }

        // Check that we have the correct number of images in the responseImages array.
        guard responseImages.count >= self.images.count else {
            self.fail(error: FirmwareUpgradeError.unknown("Expected \(self.images.count) or more images, but received \(responseImages.count) instead."))
            return
        }
        
        for image in self.images where !image.tested {
            guard let targetSlot = responseImages.first(where: {
                $0.image == image.image && Data($0.hash) == image.hash
            }) else {
                self.fail(error: FirmwareUpgradeError.unknown("No image \(image.image) (slot: \(image.slot)) in Test Response."))
                return
            }
            
            // Check the target image is pending (i.e. test succeeded).
            guard targetSlot.pending else {
                // For every image we upload, we need to send it the TEST Command.
                if image.tested && !image.testSent {
                    self.test(image)
                    self.mark(image, as: \.testSent)
                    return
                }
                
                // If we've sent it the TEST Command, the slot must be in pending state to pass test.
                self.fail(error: FirmwareUpgradeError.unknown("Image \(image.image) (slot: \(image.slot)) was tested but it did not switch to a pending state."))
                return
            }
            self.mark(image, as: \.tested)
        }
        
        // Test image succeeded. Begin device reset.
        self.log(msg: "All Test commands sent", atLevel: .debug)
        self.reset()
    }
    
    // MARK: Confirm Callback
    
    /// Callback for the CONFIRM state.
    ///
    /// This callback will fail the upload on error or move to the next state on
    /// success.
    private lazy var confirmCallback: McuMgrCallback<McuMgrImageStateResponse> = { [weak self] response, error in
        // Ensure the manager is not released.
        guard let self else { return }
        
        // Check for an error.
        if let error {
            self.fail(error: error)
            return
        }
        guard let response else {
            self.fail(error: FirmwareUpgradeError.unknown("Image Confirm response is nil."))
            return
        }
        self.log(msg: "Image Confirm response: \(response)", atLevel: .application)
        // Check for McuMgrReturnCode error.
        if let error = response.getError() {
            self.fail(error: error)
            return
        }
        
        let suitThroughMcuBoot = uploadingSUITImages()
        guard !suitThroughMcuBoot else {
            self.log(msg: "Upgrade complete", atLevel: .application)
            self.success()
            return
        }
        
        // Check that the image array exists.
        guard let responseImages = response.images, responseImages.count > 0 else {
            self.fail(error: FirmwareUpgradeError.invalidResponse(response))
            return
        }
        
        for image in self.images where !image.confirmed {
            switch self.configuration.upgradeMode {
            case .confirmOnly:
                guard let targetSlot = responseImages.first(where: {
                    $0.image == image.image && Data($0.hash) == image.hash
                }) else {
                    // Let's try the alternative slot...
                    guard let _ = responseImages.first(where: { $0.image == image.image && $0.slot != image.slot }) else {
                        self.fail(error: FirmwareUpgradeError.invalidResponse(response))
                        return
                    }
                    
                    self.mark(image, as: \.confirmed)
                    continue
                }
                
                // Check that the new image is in permanent state.
                guard targetSlot.permanent else {
                    // If a TEST command was sent before for the image that is to be confirmed we have to reset.
                    // It is not possible to confirm such image until the device is reset.
                    // A new DFU operation has to be performed to confirm the image.
                    guard !targetSlot.pending else {
                        continue
                    }
                    
                    
                    if !image.confirmed {
                        if image.confirmSent {
                            self.fail(error: FirmwareUpgradeError.unknown("Image \(targetSlot.image) (slot: \(targetSlot.slot)) was confirmed, but did not switch to permanent state."))
                        } else {
                            self.confirm(image)
                            self.mark(image, as: \.confirmSent)
                        }
                    }
                    return
                }
                
                self.mark(image, as: \.confirmed)
            case .testAndConfirm:
                if let targetSlot = responseImages.first(where: {
                    $0.image == image.image && Data($0.hash) == image.hash
                }) {
                    if targetSlot.active || targetSlot.permanent {
                        // Image booted. All okay.
                        self.mark(image, as: \.confirmed)
                        continue
                    }
                    
                    if image.confirmSent && !targetSlot.confirmed {
                        self.fail(error: FirmwareUpgradeError.unknown("Image \(targetSlot.image) (slot: \(targetSlot.slot)) was confirmed, but did not switch to permanent state."))
                        return
                    }
                    
                    self.mark(image, as: \.confirmed)
                }
            case .testOnly, .uploadOnly:
                // Impossible state. Ignore.
                return
            }
        }
        
        self.log(msg: "Upgrade complete", atLevel: .application)
        switch self.configuration.upgradeMode {
        case .confirmOnly:
            self.reset()
        case .testAndConfirm:
            // No need to reset again.
            self.success()
        case .testOnly:
            // Impossible!
            return
        case .uploadOnly:
            // (.uploadOnly is reserved for SUIT)
            self.success()
        }
    }
    
    // MARK: Erase App Settings Callback
    
    private lazy var eraseAppSettingsCallback: McuMgrCallback<McuMgrResponse> = { [weak self] response, error in
        guard let self = self else { return }
        
        if let error = error as? McuMgrTransportError {
            // Some devices will not even reply to Erase App Settings. So just move on.
            if McuMgrTransportError.sendFailed == error {
                self.finishedEraseAppSettings()
            } else {
                self.fail(error: error)
            }
            return
        }
        
        guard let response = response else {
            self.fail(error: FirmwareUpgradeError.unknown("Erase app settings response is nil."))
            return
        }
        
        switch response.result {
        case .success:
            self.log(msg: "App settings erased", atLevel: .application)
        case .failure:
            // rc != 0 is OK, meaning that this feature is not supported. DFU should continue.
            self.log(msg: "Erasing app settings not supported", atLevel: .warning)
        }
        
        self.finishedEraseAppSettings()
    }
    
    private func finishedEraseAppSettings() {
        // Set to false so uploadDidFinish() doesn't loop forever.
        self.configuration.eraseAppSettings = false
        self.uploadDidFinish()
    }
    
    // MARK: Reset Callback
    
    /// Callback for the RESET state.
    ///
    /// This callback will fail the upgrade on error. On success, the reset
    /// poller will be started after a 3 second delay.
    private lazy var resetCallback: McuMgrCallback<McuMgrResponse> = { [weak self] response, error in
        // Ensure the manager is not released.
        guard let self = self else {
            return
        }
        // Check for an error.
        if let error = error {
            self.fail(error: error)
            return
        }
        guard let response = response else {
            self.fail(error: FirmwareUpgradeError.unknown("Reset response is nil."))
            return
        }
        // Check for McuMgrReturnCode error.
        if let error = response.getError() {
            self.fail(error: error)
            return
        }
        self.resetResponseTime = Date()
        self.log(msg: "Reset request confirmed", atLevel: .info)
        self.log(msg: "Waiting for disconnection...", atLevel: .verbose)
    }
    
    public func transport(_ transport: McuMgrTransport, didChangeStateTo state: McuMgrTransportState) {
        transport.removeObserver(self)
        // Disregard connected state.
        guard state == .disconnected else {
            return
        }
        
        self.log(msg: "Device has disconnected", atLevel: .info)
        let timeSinceReset: TimeInterval
        if let resetResponseTime = resetResponseTime {
            let now = Date()
            timeSinceReset = now.timeIntervalSince(resetResponseTime)
        } else {
            // Fallback if state changed prior to `resetResponseTime` is set.
            timeSinceReset = 0
        }
        let remainingTime = configuration.estimatedSwapTime - timeSinceReset
        
        // If DirectXIP, regardless of variant, there's no swap time. So we try to reconnect
        // immediately.
        let waitForReconnectRequired = !configuration.bootloaderMode.isDirectXIP
            && remainingTime > .leastNonzeroMagnitude
        guard waitForReconnectRequired else {
            reconnect()
            return
        }
        
        self.log(msg: "Waiting \(Int(configuration.estimatedSwapTime)) seconds reconnecting...", atLevel: .info)
        DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) { [weak self] in
            self?.log(msg: "Reconnecting...", atLevel: .info)
            self?.reconnect()
        }
    }
    
    /// Reconnect to the device and continue the
    private func reconnect() {
        imageManager.transport.connect { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .connected:
                self.log(msg: "Reconnect successful", atLevel: .info)
            case .deferred:
                self.log(msg: "Reconnect deferred", atLevel: .info)
            case .failed(let error):
                self.log(msg: "Reconnect failed: \(error)", atLevel: .error)
                self.fail(error: error)
                return
            }
            
            // Continue the upgrade after reconnect.
            switch self.state {
            case .requestMcuMgrParameters:
                self.requestMcuMgrParameters()
            case .validate:
                self.validate()
            case .reset:
                switch self.configuration.upgradeMode {
                case .testAndConfirm:
                    self.testAndConfirmAfterReset()
                default:
                    self.log(msg: "Upgrade complete", atLevel: .application)
                    self.success()
                }
            default:
                break
            }
        }
    }
    
    // MARK: State
    
    private func mark(_ image: FirmwareUpgradeImage, as key: WritableKeyPath<FirmwareUpgradeImage, Bool>) {
        guard let i = images.firstIndex(of: image) else { return }
        images[i][keyPath: key] = true
    }
}

private extension FirmwareUpgradeManager {
    
    func log(msg: @autoclosure () -> String, atLevel level: McuMgrLogLevel) {
        if let logDelegate, level >= logDelegate.minLogLevel() {
            logDelegate.log(msg(), ofCategory: .dfu, atLevel: level)
        }
    }
}

// MARK: - FirmwareUpgradeConfiguration

public struct FirmwareUpgradeConfiguration: Codable {
    
    /**
     Estimated time required for swapping images, in seconds.
    
     If the mode is set to `.testAndConfirm`, the manager will try to reconnect after this time. 0 by default.
     
     Note: This setting is ignored if `bootloaderMode` is in any DirectXIP variant, since there's no swap whatsoever when DirectXIP is involved. Hence, why we can upload the same Image (though different hash) to either slot.
     */
    public var estimatedSwapTime: TimeInterval
    /**
     If enabled, after successful upload but before test/confirm/reset phase, an Erase App Settings Command will be sent and awaited before proceeding.
     */
    public var eraseAppSettings: Bool
    /**
     If set to a value larger than 1, this enables SMP Pipelining, wherein multiple packets of data ('chunks') are sent at once before awaiting a response, which can lead to a big increase in transfer speed if the receiving hardware supports this feature.
     */
    public var pipelineDepth: Int
    /**
     Necessary to set when Pipeline Length is larger than 1 (SMP Pipelining Enabled) to predict offset jumps as multiple packets are sent.
     */
    public var byteAlignment: ImageUploadAlignment
    /**
     If set, it is used instead of the MTU Size as the maximum size of the packet. It is designed to be used with a size larger than the MTU, meaning larger Data chunks per Sequence Number, trusting the reassembly Buffer on the receiving side to merge it all back. Thus, increasing transfer speeds.
     
     Can be used in conjunction with SMP Pipelining.
     
     - Note: **Cannot exceed `UInt16.max` value of 65535.**
     */
    public var reassemblyBufferSize: UInt64
    /**
     Previously set directly in `FirmwareUpgradeManager`, it has since been moved here, to the Configuration. It modifies the steps after `upload` step in Firmware Upgrade that need to be performed for the Upgrade process to be considered Successful.
     */
    public var upgradeMode: FirmwareUpgradeMode
    /**
     Provides valuable information regarding how the target device is set up to switch over to the new firmware being uploaded, if available.
     
     For example, in DirectXIP, some bootloaders will not accept a 'CONFIRM' Command and return an Error that could make the DFU Library return an Error. When in reality, what the target bootloader wants is just to receive a 'RESET' Command instead to conclude the process.
     
     Set to `.Unknown` by default, since BootloaderInfo is a new addition for NCS 2.5 / SMPv2.
     */
    public var bootloaderMode: BootloaderInfoResponse.Mode
    
    /**
     SMP Pipelining is considered Enabled for `pipelineDepth` values larger than `1`.
     */
    public var pipeliningEnabled: Bool { pipelineDepth > 1 }
    
    public init(estimatedSwapTime: TimeInterval = 0.0, eraseAppSettings: Bool = false, 
                pipelineDepth: Int = 1, byteAlignment: ImageUploadAlignment = .disabled,
                reassemblyBufferSize: UInt64 = 0,
                upgradeMode: FirmwareUpgradeMode = .confirmOnly,
                bootloaderMode: BootloaderInfoResponse.Mode = .unknown) {
        self.estimatedSwapTime = estimatedSwapTime
        self.eraseAppSettings = eraseAppSettings
        self.pipelineDepth = pipelineDepth
        self.byteAlignment = byteAlignment
        self.reassemblyBufferSize = min(reassemblyBufferSize, UInt64(UInt16.max))
        self.upgradeMode = upgradeMode
        self.bootloaderMode = bootloaderMode
    }
}

//******************************************************************************
// MARK: - ImageUploadDelegate
//******************************************************************************

extension FirmwareUpgradeManager: ImageUploadDelegate {
    
    public func uploadProgressDidChange(bytesSent: Int, imageSize: Int, timestamp: Date) {
        if bytesSent == imageSize {
            // An Image was sent. Mark as uploaded.
            if let image = self.images.first(where: { !$0.uploaded && $0.data.count == imageSize }) {
                self.mark(image, as: \.uploaded)
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.uploadProgressDidChange(bytesSent: bytesSent, imageSize: imageSize, timestamp: timestamp)
        }
    }
    
    public func uploadDidFail(with error: Error) {
        // If the upload fails, fail the upgrade.
        fail(error: error)
    }
    
    public func uploadDidCancel() {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.upgradeDidCancel(state: .none)
        }
        state = .none
        // Release cyclic reference.
        cyclicReferenceHolder = nil
    }
    
    public func uploadDidFinish() {
        // Before we can move on, we must check whether the user requested for App Core Settings
        // to be erased.
        if configuration.eraseAppSettings {
            eraseAppSettings()
            return
        }
        
        // If eraseAppSettings command was sent or was not requested, we can continue.
        switch configuration.upgradeMode {
        case .confirmOnly:
            let suitThroughMcuBoot = uploadingSUITImages()
            if suitThroughMcuBoot || configuration.bootloaderMode.isBareMetal {
                // Mark all images as confirmed
                images.forEach {
                    mark($0, as: \.confirmSent)
                    mark($0, as: \.confirmed)
                }
                
                if suitThroughMcuBoot {
                    // We send a single confirm() command with no hash
                    confirmAsSUIT()
                    return
                } else { // Bare Metal.
                    // Bare Metal doesn't need confirm. They're marked to make the code
                    // consistent within the library. Firmware just needs reset command.
                    log(msg: "Preparing to send Reset to Bare Metal Firmware Loader.", atLevel: .debug)
                    reset()
                }
            }
            
            if let firstUnconfirmedImage = images.first(where: {
                $0.uploaded && !$0.confirmed && !$0.confirmSent }
            ) {
                confirm(firstUnconfirmedImage)
                // We might send 'Confirm', but the firmware might not change the flag to reflect it.
                // If we don't track this internally, we could enter into an infinite loop always trying
                // to Confirm an image.
                mark(firstUnconfirmedImage, as: \.confirmSent)
                return
            } else {
                // If there's no image left to Confirm, then we Reset.
                reset()
                return
            }
        case .testOnly, .testAndConfirm:
            if let firstUntestedImage = images.first(where: { $0.uploaded && !$0.tested }) {
                test(firstUntestedImage)
                mark(firstUntestedImage, as: \.testSent)
                return
            }
            if configuration.upgradeMode == FirmwareUpgradeMode.testAndConfirm {
                if let firstUnconfirmedImage = images.first(where: {
                    $0.uploaded && $0.tested && !$0.confirmed && !$0.confirmSent }
                ) {
                    confirm(firstUnconfirmedImage)
                    // We might send 'Confirm', but the firmware might not change the flag to reflect it.
                    // If we don't track this internally, we could enter into an infinite loop always trying
                    // to Confirm an image.
                    mark(firstUnconfirmedImage, as: \.confirmSent)
                    return
                }
            }
        case .uploadOnly:
            // Nothing to do in SUIT since it does not support RESET Command and will
            // throw an Error if Reset is sent.
            guard bootloader != .suit else { break }
            reset()
        }
        success()
    }
}

// MARK: - FirmwareUpgradeManager

extension FirmwareUpgradeManager: SuitManagerDelegate {
    
    public func uploadRequestsResource(_ resource: FirmwareUpgradeResource) {
        guard let suitDelegate = delegate as? SuitFirmwareUpgradeDelegate else {
            delegate?.upgradeDidFail(inState: .upload, with: SuitManagerError.suitDelegateRequiredForResource(resource))
            return
        }
        suitDelegate.uploadRequestsResource(resource)
    }
}

//******************************************************************************
// MARK: - FirmwareUpgradeError
//******************************************************************************

public enum FirmwareUpgradeError: Error, LocalizedError {
    case unknown(String)
    case invalidResponse(McuMgrResponse)
    case connectionFailedAfterReset
    case untestedImageFound(image: Int, slot: Int)
    case resetIntoBootloaderModeNeeded
    
    public var errorDescription: String? {
        switch self {
        case .unknown(let message):
            return message
        case .invalidResponse(let response):
            return "Invalid response: \(response)"
        case .connectionFailedAfterReset:
            return "Connection failed after reset"
        case .untestedImageFound(let image, let slot):
            return "Image \(image) (slot: \(slot)) found to be not Tested after Reset"
        case .resetIntoBootloaderModeNeeded:
            return "Reset into Firmware Loader (Bootloader Mode) required."
        }
    }
}

//******************************************************************************
// MARK: - FirmwareUpgradeState
//******************************************************************************

public enum FirmwareUpgradeState {
    case none
    case requestMcuMgrParameters, bootloaderInfo, eraseAppSettings
    case upload, success
    case validate, test, confirm, reset
    
    func isInProgress() -> Bool {
        return self != .none
    }
}

//******************************************************************************
// MARK: - FirmwareUpgradeMode
//******************************************************************************

public enum FirmwareUpgradeMode: Codable, CustomStringConvertible, CustomDebugStringConvertible, CaseIterable {
    /// When this mode is set, the manager will send the test and reset commands
    /// to the device after the upload is complete. The device will reboot and
    /// will run the new image on its next boot. If the new image supports
    /// auto-confirm feature, it will try to confirm itself and change state to
    /// permanent. If not, test image will run just once and will be swapped
    /// again with the original image on the next boot.
    ///
    /// Use this mode if you just want to test the image, when it can confirm
    /// itself.
    case testOnly
    
    /// When this flag is set, the manager will send confirm and reset commands
    /// immediately after upload.
    ///
    /// Use this mode if when the new image does not support both auto-confirm
    /// feature and SMP service and could not be confirmed otherwise.
    case confirmOnly
    
    /**
     When set, the manager will first send test followed by reset commands, then it will reconnect to the new application and will send confirm command.
     
     Use this mode when the new image supports SMP service and you want to test it before confirming.
     */
    case testAndConfirm
    
    /**
     - McuBoot/McuMgr: Upload Only ignores Bootloader Info, does not test nor confirm any uploaded images. It does list/verify, proceed to upload the images, and reset. It is not recommended for use, except perhaps for DirectXIP use cases where the Bootloader is unreliable.
     
     - For SUIT: Expected value for all `SUIT` variants & situations as of this release.
     */
    case uploadOnly
    
    public var description: String {
        switch self {
        case .testOnly:
            return "Test only"
        case .confirmOnly:
            return "Confirm only"
        case .testAndConfirm:
            return "Test and Confirm"
        case .uploadOnly:
            return "Upload only (no revert)"
        }
    }
    
    public var debugDescription: String {
        switch self {
        case .testOnly:
            return ".testOnly"
        case .confirmOnly:
            return ".confirmOnly"
        case .testAndConfirm:
            return ".testAndConfirm"
        case .uploadOnly:
            return ".uploadOnly"
        }
    }
}

//******************************************************************************
// MARK: - FirmwareUpgradeDelegate
//******************************************************************************

/// Callbacks for firmware upgrades started using FirmwareUpgradeManager.
public protocol FirmwareUpgradeDelegate: AnyObject {
    
    /**
     Called when the upgrade has started.
     
     - parameter controller: The controller that may be used to pause, resume or cancel the upgrade.
     */
    func upgradeDidStart(controller: FirmwareUpgradeController)
    
    /**
     Called when the firmware upgrade state has changed.
     
     - parameter previousState: The state before the change.
     - parameter newState: The new state.
     */
    func upgradeStateDidChange(from previousState: FirmwareUpgradeState, to newState: FirmwareUpgradeState)
    
    /**
     Called when the firmware upgrade has succeeded.
     */
    func upgradeDidComplete()
    
    /**
     Called when the firmware upgrade has failed.
     
     - parameter state: The state in which the upgrade has failed.
     - parameter error: The error.
     */
    func upgradeDidFail(inState state: FirmwareUpgradeState, with error: Error)
    
    /**
     Called when the firmware upgrade has been cancelled using cancel() method. The upgrade may be cancelled only during uploading the image.
     When the image is uploaded, the test and/or confirm commands will be sent depending on the mode.
     */
    func upgradeDidCancel(state: FirmwareUpgradeState)
    
    /**
     Called when the upload progress has changed.
     
     - parameter bytesSent: Number of bytes sent so far.
     - parameter imageSize: Total number of bytes to be sent.
     - parameter timestamp: The time that the successful response packet for the progress was received.
     */
    func uploadProgressDidChange(bytesSent: Int, imageSize: Int, timestamp: Date)
}

// MARK: - SuitFirmwareUpgradeDelegate

public protocol SuitFirmwareUpgradeDelegate: FirmwareUpgradeDelegate {
    
    /**
     In SUIT (Software Update for the Internet of Things), various resources, such as specific files, URL contents, etc. may be requested by the firmware device. When it does, this callback will be triggered.
     */
    func uploadRequestsResource(_ resource: FirmwareUpgradeResource)
}

// MARK: - FirmwareUpgradeImage

internal struct FirmwareUpgradeImage: CustomDebugStringConvertible {
    
    // MARK: Properties
    
    let image: Int
    let slot: Int
    let data: Data
    let hash: Data
    let content: McuMgrManifest.File.ContentType
    var uploaded: Bool
    var tested: Bool
    var testSent: Bool
    var confirmed: Bool
    var confirmSent: Bool
    
    // MARK: Init
    
    init(_ image: ImageManager.Image) {
        self.image = image.image
        self.slot = image.slot
        self.data = image.data
        self.hash = image.hash
        self.content = image.content
        self.uploaded = false
        self.tested = false
        self.testSent = false
        self.confirmed = false
        self.confirmSent = false
    }
    
    // MARK: CustomDebugStringConvertible
    
    var debugDescription: String {
        return """
        Data: \(data)
        Hash: \(hash)
        Image \(image), Slot \(slot), Content \(content.description)
        Uploaded \(uploaded ? "Yes" : "No")
        Tested \(tested ? "Yes" : "No"), Test Sent \(testSent ? "Yes" : "No"),
        Confirmed \(confirmed ? "Yes" : "No"), Confirm Sent \(confirmSent ? "Yes" : "No")
        """
    }
}

// MARK: - Bare Metal

extension FirmwareUpgradeImage {
    
    func patchForBareMetal() -> Self {
        return FirmwareUpgradeImage(
            ImageManager.Image(image: image, slot: 0, content: .bin, hash: hash, data: data)
        )
    }
}

// MARK: - FirmwareUpgradeImage Hashable

extension FirmwareUpgradeImage: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(image)
        hasher.combine(hash)
    }
}

// MARK: - FirmwareUpgradeImage Comparable

extension FirmwareUpgradeImage: Equatable {
    
    public static func == (lhs: FirmwareUpgradeImage, rhs: FirmwareUpgradeImage) -> Bool {
        return lhs.hash == rhs.hash
    }
}
