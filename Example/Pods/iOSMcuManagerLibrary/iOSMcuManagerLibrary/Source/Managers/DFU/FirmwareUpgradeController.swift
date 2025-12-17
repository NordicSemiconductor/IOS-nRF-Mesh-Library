//
//  FirmwareUpgradeController.swift
//  nRF Connect Device Manager
//
//  Created by Aleksander Nowakowski on 05/07/2018.
//  Copyright © 2024 Nordic Semiconductor ASA.
//

import Foundation

// MARK: - FirmwareUpgradeController

public protocol FirmwareUpgradeController: AnyObject {
    
    /// Pause the firmware upgrade.
    func pause()
    
    /// Resume a paused firmware upgrade.
    func resume()
    
    /// Cancel the firmware upgrade.
    func cancel()
    
    /// Returns true if the upload has been paused.
    func isPaused() -> Bool
    
    /// Returns true if the upload is in progress.
    func isInProgress() -> Bool
    
    /**
     Firmware upgrades on SUIT (Software Update for the Internet of Things) devices might request a ``FirmwareUpgradeResource`` to continue via callback. When that happens, this API allows you to provide said resource.
     */
    func uploadResource(_ resource: FirmwareUpgradeResource, data: Data) -> Void
}

// MARK: FirmwareUpgradeResource

public enum FirmwareUpgradeResource: CustomStringConvertible {
    case file(name: String)
    
    // MARK: Init
    
    public init?(_ resourceID: String) {
        guard let filename = resourceID.components(separatedBy: "//").last else {
            return nil
        }
        self = .file(name: String(filename))
    }
    
    // MARK: CustomStringConvertible
    
    public var description: String {
        switch self {
        case .file(let name):
            return "file://\(name)"
        }
    }
}
