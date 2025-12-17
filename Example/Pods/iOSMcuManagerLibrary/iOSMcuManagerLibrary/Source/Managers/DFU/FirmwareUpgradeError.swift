//
//  FirmwareUpgradeError.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 28/11/25.
//

import Foundation

//******************************************************************************
// MARK: - FirmwareUpgradeError
//******************************************************************************

public enum FirmwareUpgradeError: Error, LocalizedError {
    case unknown(String)
    case invalidResponse(McuMgrResponse)
    case connectionFailedAfterReset
    case uploadedImageNotFound(image: Int, slot: Int)
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
        case .uploadedImageNotFound(let image, let slot):
            return "Uploaded Image \(image) to slot: \(slot) not found after Reset."
        case .untestedImageFound(let image, let slot):
            return "Image \(image) (slot: \(slot)) found to be not Tested after Reset"
        case .resetIntoBootloaderModeNeeded:
            return "Reset into Firmware Loader (Bootloader Mode) required."
        }
    }
}
