//
//  DefaultManager+Async.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 26/3/26.
//  Copyright © 2026 Nordic Semiconductor ASA. All rights reserved.
//

import Foundation
import iOSMcuManagerLibrary

// MARK: - DefaultManager+Async

@available(iOS 13.0, macCatalyst 13.0, macOS 10.15, *)
public extension DefaultManager {
    
    // MARK: async params()
    
    public func params() async throws -> McuMgrParametersResponse {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<McuMgrParametersResponse, Error>) in
            params { response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let response {
                    continuation.resume(returning: response)
                } else {
                    continuation.resume(throwing: McuMgrResponseParseError.invalidPayload)
                }
            }
        }
    }
    
    // MARK: async applicationInfo(format:)
    
    public func applicationInfo(format: Set<ApplicationInfoFormat>) async throws -> AppInfoResponse {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AppInfoResponse, Error>) in
            applicationInfo(format: format) { response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let response {
                    continuation.resume(returning: response)
                } else {
                    continuation.resume(throwing: McuMgrResponseParseError.invalidPayload)
                }
            }
        }
    }
    
    // MARK: bootloaderInfo()
    
    public func bootloaderInfo() async throws -> (bootloader: BootloaderInfoResponse.Bootloader?, mode: BootloaderInfoResponse.Mode?, slot: UInt64?) {
        let bootloader = try await bootloaderQuery(.name).bootloader
        guard bootloader == .mcuboot else { return (bootloader: bootloader, mode: nil, slot: nil) }
        
        let mode = try await bootloaderQuery(.mode).mode
        let slot = try await bootloaderQuery(.slot).activeSlot
        return (bootloader: bootloader, mode: mode, slot: slot)
    }
    
    // MARK: bootloaderQuery(:)
    
    public func bootloaderQuery(_ query: BootloaderInfoQuery) async throws -> BootloaderInfoResponse {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<BootloaderInfoResponse, Error>) in
            bootloaderInfo(query: query) { response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let response {
                    continuation.resume(returning: response)
                } else {
                    continuation.resume(throwing: McuMgrResponseParseError.invalidPayload)
                }
            }
        }
    }
}
