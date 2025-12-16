//
//  FirmwareUpgradeConfiguration.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 28/11/25.
//

import Foundation

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
