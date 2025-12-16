/*
 * Copyright (c) 2017-2018 Runtime Inc.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import CoreBluetooth

// MARK: - FirmwareUpgradeManager

public class FirmwareUpgradeManager: FirmwareUpgradeController, ConnectionObserver {
    
    // MARK: Properties
    
    internal let imageManager: ImageManager
    private let defaultManager: DefaultManager
    private let basicManager: BasicManager
    private let settingsManager: SettingsManager
    internal let suitManager: SuitManager
    
    internal weak var delegate: FirmwareUpgradeDelegate?
    
    /// Cyclic reference is used to prevent from releasing the manager
    /// in the middle of an update. The reference cycle will be set
    /// when upgrade was started and released on success, error or cancel.
    internal var cyclicReferenceHolder: (() -> FirmwareUpgradeManager)?
    
    internal var images: [FirmwareUpgradeImage]!
    internal var configuration: FirmwareUpgradeConfiguration!
    internal var bootloader: BootloaderInfoResponse.Bootloader!
    
    /// Mostly applies for Bare Metal (mode=7) wherein we need to reset
    /// the device into Firwmare Loader Mode so that DFU may continue.
    private var connectionPeripheral: CBPeripheral!
    private var resetBootloaderName: String!
    private var firmwareLoaderFinder: FirmwareUpgradePeripheralFinder?
    
    internal var state: FirmwareUpgradeState
    internal var paused: Bool
    
    /// Logger delegate may be used to obtain logs.
    public weak var logDelegate: McuMgrLogDelegate? {
        didSet {
            imageManager.logDelegate = logDelegate
            defaultManager.logDelegate = logDelegate
            suitManager.logDelegate = logDelegate
        }
    }
    
    private var resetResponseTime: Date?
    
    // MARK: init
    
    public init(transport: McuMgrTransport, delegate: FirmwareUpgradeDelegate?) {
        self.imageManager = ImageManager(transport: transport)
        self.defaultManager = DefaultManager(transport: transport)
        self.basicManager = BasicManager(transport: transport)
        self.suitManager = SuitManager(transport: transport)
        self.settingsManager = SettingsManager(transport: transport)
        self.delegate = delegate
        self.state = .none
        self.paused = false
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
    
    internal func requestMcuMgrParameters() {
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
    
    // MARK: validate
    
    private func validate() {
        objc_sync_setState(.validate)
        if !paused {
            log(msg: "Sending Image List command...", atLevel: .verbose)
            imageManager.list(callback: listCallback)
        }
    }
    
    // MARK: upload
    
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
    
    // MARK: test
    
    private func test(_ image: FirmwareUpgradeImage) {
        objc_sync_setState(.test)
        if !paused {
            log(msg: "Sending Image Test command for image \(image.image) (slot: \(image.slot))...", atLevel: .verbose)
            imageManager.test(hash: [UInt8](image.hash), callback: testCallback)
        }
    }
    
    // MARK: confirm
    
    private func confirm(_ image: FirmwareUpgradeImage) {
        objc_sync_setState(.confirm)
        if !paused {
            log(msg: "Sending Image Confirm command to image \(image.image) (slot \(image.slot))...", atLevel: .verbose)
            log(msg: "confirm(hash: \(image.hash.prefix(12).hexEncodedString(options: [.prepend0x])))", atLevel: .application)
            imageManager.confirm(hash: [UInt8](image.hash), callback: confirmCallback)
        }
    }
    
    // MARK: confirmAsSUIT
    
    private func confirmAsSUIT() {
        objc_sync_setState(.confirm)
        if !paused {
            log(msg: "Sending single Confirm command for SUIT upload (no Hash) via McuBoot...", atLevel: .verbose)
            imageManager.confirm(hash: nil, callback: confirmCallback)
        }
    }
    
    // MARK: eraseAppSettings
    
    private func eraseAppSettings() {
        objc_sync_setState(.eraseAppSettings)
        log(msg: "Erasing app settings...", atLevel: .verbose)
        basicManager.eraseAppSettings(callback: eraseAppSettingsCallback)
    }
    
    // MARK: reset
    
    private func reset() {
        objc_sync_setState(.reset)
        if !paused {
            log(msg: "Sending Reset command...", atLevel: .verbose)
            defaultManager.transport.addObserver(self)
            defaultManager.reset(callback: resetCallback)
        }
    }
    
    // MARK: listAfterUploadReset
    
    /**
     Test and Confirm uploads desired images, and then marks them all as 'Tested' (which looks like 'pending' from McuMgr perspective) before Reset. Upon Reset, the previously tested Image will have switched image (core) due to image swap, so there's our mismatch between our tracking of (image, slot) and the status on the target device. Here, we match them, before proceeding to ``testAndConfirmAfterReset()``.
     */
    private func listAfterUploadReset() {
        log(msg: "Updating Image List after Upload phase Reset...", atLevel: .verbose)
        imageManager.list { [weak self] response, error in
            guard let self else { return }
            
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
            
            guard let responseImages = response.images, responseImages.count > 0 else {
                self.fail(error: FirmwareUpgradeError.invalidResponse(response))
                return
            }
            
            // After Reset, Images can be swapped. So an Image uploaded to 0, 1 in nRF52 for example,
            // might've been swapped to Active and Image 0, Slot 0.
            let imagesBeforeReset = images ?? []
            images = [FirmwareUpgradeImage]()
            for responseImage in responseImages {
                guard let match = imagesBeforeReset.first(where: { $0.hash == Data(responseImage.hash) }) else { continue }
                let image = ImageManager.Image(image: Int(responseImage.image), slot: Int(responseImage.slot), content: match.content, hash: match.hash, data: match.data)
                var fwImage = FirmwareUpgradeImage(image)
                fwImage.uploaded = match.uploaded
                fwImage.testSent = match.testSent
                fwImage.tested = match.tested
                fwImage.confirmSent = match.confirmSent
                fwImage.confirmed = match.confirmed
                if match.slot != fwImage.slot {
                    self.log(msg: "Detected swap of Image \(match.image), slot \(match.slot) to Image \(fwImage.image), slot \(fwImage.slot)", atLevel: .debug)
                }
                images.append(fwImage)
            }
            
            testAndConfirmAfterReset()
        }
    }
    
    // MARK: testAndConfirmAfterReset
    
    /**
     Called in .test&Confirm mode after uploaded images have been sent 'Test' command, they are tested (pending in McuMgr parlance), then Reset, and now we need to Confirm all Images.
     
     If the previously marked as tested Image became Active after Reset (image got swapped and is running), it is by definition internally marked as Confirmed/Permanent, but it is not returned to us as Confirmed via List command. But we do send them the Confirm command to mark them as such from our perspective.
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
    
    // MARK: success
    
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
    
    // MARK: fail(error:)
    
    private func fail(error: Error) {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        if let mcuMgrError = error as? McuMgrError,
           case let McuMgrError.returnCode(returnCode) = mcuMgrError {
            if configuration.bootloaderMode.isBareMetal, returnCode == .unsupported {
                if imageManager.transport.mode == .default {
                    log(msg: "Bare Metal Command Error Detected. Attempting Reset into Firmware Loader Mode...", atLevel: .debug)
                    buttonlessBareMetalResetIntoFirmwareLoader()
                    return // swallow error for Firmware Loader Mode switch.
                }
                // 'default' mode means Application Mode. 'alternate' is Firmware
                // Loader. So if there's an unsopported Bare Metal error and we're
                // already speaking to the Firmware Loader, there's nothing more
                // we can do.
                log(msg: "Bare Metal Command Error Detected in Firmware Loader Mode. Operation cannot continue.", atLevel: .error)
            }
        }
        log(msg: error.localizedDescription, atLevel: .error)
        let tmp = state
        state = .none
        paused = false
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.upgradeDidFail(inState: tmp, with: error)
            // Release cyclic reference.
            self?.cyclicReferenceHolder = nil
        }
    }
    
    // MARK: resumeFromCurrentState
    
    internal func resumeFromCurrentState() {
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
    
    // MARK: buttonlessBareMetalResetIntoFirmwareLoader()
    
    private func buttonlessBareMetalResetIntoFirmwareLoader() {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        state = .resetIntoFirmwareLoader
        resetBootloaderName = settingsManager.generateNewAdvertisingName()
        settingsManager.setFirmwareLoaderAdvertisingName(resetBootloaderName, callback: setFirmwareLoaderNameCallback)
    }
    
    // MARK: uploadingSUITImages()
    
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
        let mtu: Int = self.imageManager.transport.mtu
        if bufferSize < mtu {
            self.log(msg: "Parameters SAR Buffer Size (\(bufferSize)) is smaller than negotiated MTU (\(mtu)). Lowering MTU to match.", atLevel: .warning)
            try? self.setUploadMtu(mtu: Int(bufferSize))
        }
        self.bootloaderInfo() // Continue to Bootloader Mode.
    }
    
    // MARK: setFirmwareLoaderNameCallback
    
    private lazy var setFirmwareLoaderNameCallback: McuMgrCallback<McuMgrResponse> = { [weak self] response, error in
        guard let self else { return }
        
        guard error == nil, let response, response.rc.isSupported() else {
            log(msg: "Attempted Reset into Firmware Loader Mode failed due to rename error: \(error?.localizedDescription)", atLevel: .error)
            fail(error: FirmwareUpgradeError.resetIntoBootloaderModeNeeded)
            return
        }
        
        defaultManager.reset(bootMode: .bootloader, callback: resetIntoFirmwareLoaderCallback)
    }
    
    private lazy var resetIntoFirmwareLoaderCallback: McuMgrCallback<McuMgrResponse> = { [weak self] response, error in
        guard let self else { return }
        
        guard error == nil, let response, response.rc.isSupported() else {
            log(msg: "Reset into Firmware Loader Mode Command failed: \(error?.localizedDescription)", atLevel: .error)
            fail(error: FirmwareUpgradeError.resetIntoBootloaderModeNeeded)
            return
        }
        
        log(msg: "Reset into Firmware Loader Mode Command successful.", atLevel: .info)
        
        guard let bleTransport = imageManager.transport as? McuMgrBleTransport else {
            log(msg: "Reset into Firmware Loader Mode is only supported for Bluetooth LE Transport.", atLevel: .error)
            fail(error: FirmwareUpgradeError.unknown("Reset into Firmware Loader Mode is only supported for Bluetooth LE."))
            return
        }
        
        firmwareLoaderFinder = FirmwareUpgradePeripheralFinder(bleTransport.centralManager, searchName: resetBootloaderName)
        log(msg: "Looking for device named \(resetBootloaderName) after reset...", atLevel: .debug)
        firmwareLoaderFinder?.find(with: firmwareLoaderFinderCallback)
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
        case .directXIPNoRevert:
            // No Revert means Upload followed by Reset, and the firmware will handle setting up
            // the correct images to start.
            
            // Sending test or confirm will trigger firmware errors. So in practice, it translates
            // to the same procedure as "uploadOnly". Even if user selects confirm, test or test&Confirm.
            self.log(msg: "DirectXIP without Revert detected. Overriding upgrade mode to Upload Only.", atLevel: .debug)
            self.configuration.upgradeMode = .uploadOnly
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
    
    // MARK: listCallback
    
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
    
    // MARK: targetSlotMatch(for:to:)
    
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
    
    // MARK: listConfirm
    
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
        
        for image in self.images where (image.uploaded && !image.tested) {
            guard let targetSlot = responseImages.first(where: {
                $0.image == image.image && Data($0.hash) == image.hash
            }) else {
                self.fail(error: FirmwareUpgradeError.unknown("No image \(image.image) (slot: \(image.slot)) in Test Response."))
                return
            }
            
            // Check the target image is pending (i.e. test succeeded).
            guard targetSlot.pending else {
                guard !image.testSent else {
                    // If we've sent it the TEST Command, the slot must be in pending state to pass test.
                    self.fail(error: FirmwareUpgradeError.unknown("Image \(image.image) (slot: \(image.slot)) was tested but it did not switch to a pending state."))
                    return
                }
                
                // For every image we've uploaded, we need to send it
                // TEST command in test&Confirm mode.
                self.test(image)
                self.mark(image, as: \.testSent)
                // test will trigger another call to testCallback
                // so no need to continue here.
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
                guard let targetSlot = responseImages.first(where: {
                    Data($0.hash) == image.hash
                }) else { continue }
                
                // An image might boot and be internally confirmed, but not be marked as "confirmed"
                // as such in LIST response. But in test&Confirm we send CONFIRM after Reset.
                guard image.confirmSent else {
                    self.mark(image, as: \.confirmSent)
                    self.confirm(image) // confirmCallback 'callback' will continue execution
                    return
                }
                
                if targetSlot.active || targetSlot.permanent {
                    // Image booted. All okay.
                    self.mark(image, as: \.confirmed)
                    continue
                }
                
                guard targetSlot.confirmed else {
                    self.fail(error: FirmwareUpgradeError.unknown("Image \(targetSlot.image) (slot: \(targetSlot.slot)) was confirmed, but did not switch to permanent state."))
                    return
                }
                
                self.mark(image, as: \.confirmed)
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
    
    // MARK: transport(:didChangeStateTo:)
    
    public func transport(_ transport: McuMgrTransport, didChangeStateTo state: McuMgrTransportState) {
        transport.removeObserver(self)
        
        // Disregard connected state.
        guard state == .disconnected else { return }
        
        if resetBootloaderName != nil, imageManager.transport.mode == .alternate {
            do {
                log(msg: "Switching transport back to Default Mode...", atLevel: .debug)
                try imageManager.transport.switchMode(to: .default, with: nil)
            } catch {
                fail(error: error)
                return
            }
        }
        
        log(msg: "Device disconnected.", atLevel: .info)
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
        
        log(msg: "Waiting \(Int(configuration.estimatedSwapTime)) seconds before reconnect attempt...", atLevel: .info)
        DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) { [weak self] in
            self?.log(msg: "Reconnecting...", atLevel: .info)
            self?.reconnect()
        }
    }
    
    private lazy var firmwareLoaderFinderCallback: FirmwareUpgradePeripheralFinder.FindCallback = { [weak self] result in
        
        self?.firmwareLoaderFinder = nil
        
        switch result {
        case .success(let peripheral):
            do {
                self?.log(msg: "Switching Bluetooth LE Transport into alternate mode with Firmware Loader peripheral...", atLevel: .debug)
                try self?.imageManager.transport.switchMode(to: .alternate, with: peripheral)
            } catch {
                self?.log(msg: error.localizedDescription, atLevel: .error)
                self?.fail(error: FirmwareUpgradeError.connectionFailedAfterReset)
                return
            }
            
            self?.log(msg: "Successfully reset device into Firmware Loader Mode", atLevel: .info)
            // Retry / Continue
            self?.state = .validate
            self?.log(msg: "Retrying LIST Command from Firwmare Loader Mode...", atLevel: .debug)
            self?.resumeFromCurrentState()
        case .failure(let error):
            self?.log(msg: error.localizedDescription, atLevel: .error)
            self?.fail(error: error)
        }
    }
    
    /// Reconnect to the device and continue the
    private func reconnect() {
        imageManager.transport.connect { [weak self] result in
            guard let self else { return }
            
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
                    self.listAfterUploadReset()
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

internal extension FirmwareUpgradeManager {
    
    func log(msg: @autoclosure () -> String, atLevel level: McuMgrLogLevel) {
        if let logDelegate, level >= logDelegate.minLogLevel() {
            logDelegate.log(msg(), ofCategory: .dfu, atLevel: level)
        }
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
        // Before we can move on, we must check whether the user requested for App Core
        // Settings to be erased.
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
                return // testCallback will continue execution
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

// MARK: - SuitManagerDelegate

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
// MARK: - FirmwareUpgradeState
//******************************************************************************

public enum FirmwareUpgradeState {
    case none
    case requestMcuMgrParameters, bootloaderInfo, eraseAppSettings
    case upload, success
    case validate, test, confirm, reset
    case resetIntoFirmwareLoader
    
    func isInProgress() -> Bool {
        return self != .none
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
