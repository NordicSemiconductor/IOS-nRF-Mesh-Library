//
//  FirmwareUpgradeManager+Public.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 28/11/25.
//

import Foundation

// MARK: - FirmwareUpgradeManager Public API

public extension FirmwareUpgradeManager {
    
    // MARK: start()
    
    /// Start the firmware upgrade.
    ///
    /// This is the full-featured API to start DFU update, including support for Multi-Image uploads, DirectXIP, and SUIT. It is a seamless API.
    /// - parameter package: The (`McrMgrPackage`) to upload.
    /// - parameter configuration: Fine-tuning of details regarding the upgrade process.
    func start(package: McuMgrPackage, using configuration: FirmwareUpgradeConfiguration = FirmwareUpgradeConfiguration()) {
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
    func start(hash: Data, data: Data, using configuration: FirmwareUpgradeConfiguration = FirmwareUpgradeConfiguration()) {
        start(images: [ImageManager.Image(image: 0, hash: hash, data: data)],
                  using: configuration)
    }
    
    /// Start the firmware upgrade.
    ///
    /// This is the full-featured API to start DFU update, including support for Multi-Image uploads.
    /// - parameter images: An Array of (`ImageManager.Image`) to upload.
    /// - parameter configuration: Fine-tuning of details regarding the upgrade process.
    func start(images: [ImageManager.Image], using configuration: FirmwareUpgradeConfiguration = FirmwareUpgradeConfiguration()) {
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
    
    // MARK: uploadResource(_:data:)
    
    /**
     For SUIT (Software Update for Internet of Things), the target device might request some resource via the ``SuitFirmwareUpgradeDelegate/uploadRequestsResource(_:)`` callback. After that happens, `FirmwareUpgradeManager` will wait until the requested ``FirmwareUpgradeResource`` is provided via this API.
     
     - parameter resource: The resource being provided ``FirmwareUpgradeResource``.
     - parameter data: The bytes of the resource itself.
     */
    func uploadResource(_ resource: FirmwareUpgradeResource, data: Data) {
        objc_sync_enter(self)
        suitManager.uploadResource(data)
        objc_sync_exit(self)
    }
    
    // MARK: cancel()
    
    func cancel() {
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
    
    // MARK: pause()
    
    func pause() {
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
    
    // MARK: resume()
    
    func resume() {
        objc_sync_enter(self)
        if paused {
            paused = false
            resumeFromCurrentState()
        }
        objc_sync_exit(self)
    }
    
    // MARK: isPaused()
    
    func isPaused() -> Bool {
        return paused
    }
    
    // MARK: isInProgress()
    
    func isInProgress() -> Bool {
        return state.isInProgress() && !paused
    }
    
    // MARK: setUploadMtu(mtu:)
    
    func setUploadMtu(mtu: Int) throws {
        try imageManager.setMtu(mtu)
    }
}
