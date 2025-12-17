//
//  FirmwareUpgradeImage.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 28/11/25.
//

import Foundation

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

internal extension FirmwareUpgradeImage {
    
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
