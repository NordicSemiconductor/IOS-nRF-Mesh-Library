//
//  McuMgrUploadPipeline.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 29/10/24.
//

import Foundation

// MARK: - McuMgrUploadPipeline

public struct McuMgrUploadPipeline {
    
    // MARK: Properties
    
    private let bufferSize: UInt64
    private let depth: Int
    private var lastReceivedOffset: UInt64
    private var expectedReturnOffsets: [UInt64] = []
    
    // MARK: init
    
    public init(adopting configuration: FirmwareUpgradeConfiguration, over transport: McuMgrTransport) {
        self.depth = configuration.pipelineDepth
        self.bufferSize = configuration.reassemblyBufferSize
        self.lastReceivedOffset = 0
        
        if let bleTransport = transport as? McuMgrBleTransport {
            bleTransport.numberOfParallelWrites = depth
            bleTransport.chunkSendDataToMtuSize = bufferSize != 0
        }
    }
    
    // MARK: pipelinedSend(ofSize:using:)
    
    mutating public func pipelinedSend(ofSize imageSize: Int, using sendFrom: @escaping (_ offset: UInt64) -> UInt64) {
        for _ in 0..<(depth - expectedReturnOffsets.count) {
            let offset = expectedReturnOffsets.last ?? lastReceivedOffset
            guard offset < imageSize else {
                return
            }
            let returnOffset = sendFrom(offset)
            expectedReturnOffsets.append(returnOffset)
        }
    }
    
    // MARK: receivedData(with:)
    
    mutating public func receivedData(with offset: UInt64) {
        // We expect In-Order Responses.
        if expectedReturnOffsets.contains(offset) {
            lastReceivedOffset = max(lastReceivedOffset, UInt64(offset))
        } else {
            // Offset Mismatch.
            lastReceivedOffset = offset
            
            if !expectedReturnOffsets.isEmpty {
                expectedReturnOffsets.removeFirst()
            }
            
            // All of our previous 'sends' are invalid.
            // Wait for all of them to return and then continue.
            guard expectedReturnOffsets.isEmpty else {
                return
            }
        }
        expectedReturnOffsets.removeAll(where: { $0 <= offset })
    }
    
    // MARK: allPacketsReceived()
    
    public func allPacketsReceived() -> Bool {
        return expectedReturnOffsets.isEmpty
    }
}
