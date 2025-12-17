//
//  FirmwareUpgradeMode.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 28/11/25.
//

import Foundation

//******************************************************************************
// MARK: - FirmwareUpgradeMode
//******************************************************************************

public enum FirmwareUpgradeMode: Codable, CustomStringConvertible, CustomDebugStringConvertible, CaseIterable {
    /**
     When this mode is set, the manager will send the test and reset commands to the device after the upload is complete. The device will reboot and will run the new image on its next boot. If the new image supports auto-confirm feature, it will try to confirm itself and change state to permanent. If not, test image will run just once and will be swapped again with the original image on the next boot.
     
     Use this mode if you just want to test the image, when it can confirm itself.
     */
    case testOnly
    
    /**
     When this flag is set, the manager will send confirm and reset commands immediately after upload.
     
     Use this mode if when the new image does not support both auto-confirm feature and SMP service and could not be confirmed otherwise.
     */
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
            return "Confirm only (Recommended)"
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
