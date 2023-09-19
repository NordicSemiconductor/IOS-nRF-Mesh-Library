//
//  Task+TimeInterval.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 15.09.2023.
//

import Foundation

internal extension Task where Success == Never, Failure == Never {
    
    static func sleep(seconds: TimeInterval) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
    
}
