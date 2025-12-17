//
//  McuMgrBleTransportWriteState.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 12/5/22.
//

import Foundation
import Dispatch

// MARK: - McuMgrBleTransportWrite

typealias McuMgrBleTransportWrite = (sequenceNumber: McuSequenceNumber, writeLock: ResultLock,
                                     chunk: Data?, totalChunkSize: Int?)

// MARK: - McuMgrBleTransportWriteState

final class McuMgrBleTransportWriteState {
    
    // MARK: - Private Properties
    
    private let lockingQueue = DispatchQueue(label: "McuMgrBleTransportWriteState",
                                             qos: .userInitiated)
    
    private var state = [UInt8: McuMgrBleTransportWrite]()
    
    // MARK: - APIs
    
    subscript(sequenceNumber: McuSequenceNumber) -> McuMgrBleTransportWrite? {
        get {
            lockingQueue.sync { state[sequenceNumber] }
        }
    }
    
    func newWrite(sequenceNumber: McuSequenceNumber, lock: ResultLock) {
        lockingQueue.async {
            // Either the Lock for a Sequence Number is Open, or there's no state for it.
            assert(self.state[sequenceNumber]?.writeLock.isOpen ?? true)
            self.state[sequenceNumber] = (sequenceNumber: sequenceNumber, writeLock: lock, nil, nil)
        }
    }
    
    func sharedLock(_ writeClosure: @escaping () -> Void) {
        lockingQueue.async { writeClosure() }
    }
    
    func received(sequenceNumber: McuSequenceNumber, data: Data) {
        lockingQueue.async {
            if self.state[sequenceNumber]?.chunk == nil {
                // If we do not have any current response data, this is the initial
                // packet in a potentially fragmented response. Get the expected
                // length of the full response and initialize the responseData with
                // the expected capacity.
                guard let dataSize = McuMgrResponse.getExpectedLength(scheme: .ble, responseData: data) else {
                    self.state[sequenceNumber]?.writeLock.open(McuMgrTransportError.badResponse)
                    return
                }
                self.state[sequenceNumber]?.chunk = Data(capacity: dataSize)
                self.state[sequenceNumber]?.totalChunkSize = dataSize
            }
            
            self.state[sequenceNumber]?.chunk?.append(data)
            
            guard self.unsafe_isChunkComplete(for: sequenceNumber) else {
                // More bytes expected.
                return
            }
            self.state[sequenceNumber]?.writeLock.open()
        }
    }
    
    /**
     Helper to check whether we've received all `Data` for a `McuSequenceNumber`.
     
     Returns: `true` if there's no state whatsoever for the given `McuSequenceNumber`, or there is state and we can verify the full chunk `Data` is present. `false` if otherwise, including if we have state for the `McuSequenceNumber`, but no chunk `Data` available or it's not complete yet.
     */
    func isChunkComplete(for sequenceNumber: McuSequenceNumber) -> Bool {
        lockingQueue.sync {
            guard let chunkState = self.state[sequenceNumber] else { return true }
            
            guard let chunk = chunkState.chunk,
                  let expectedChunkSize = chunkState.totalChunkSize else { return false }
            return chunk.count >= expectedChunkSize
        }
    }
    
    func open(sequenceNumber: McuSequenceNumber, dueTo error: McuMgrTransportError) {
        lockingQueue.async {
            self.state[sequenceNumber]?.writeLock.open(error)
        }
    }
    
    func completedWrite(sequenceNumber: McuSequenceNumber) {
        lockingQueue.async {
            self.state[sequenceNumber] = nil
        }
    }
    
    func onError(_ error: Error) {
        lockingQueue.async {
            self.state.forEach { _, value in
                value.writeLock.open(error)
            }
        }
    }
    
    func onWriteError(sequenceNumber: McuSequenceNumber, error: Error) {
        lockingQueue.async {
            self.state[sequenceNumber]?.writeLock.open(error)
        }
    }
}

// MARK: - File private

fileprivate extension McuMgrBleTransportWriteState {
    
    func unsafe_isChunkComplete(for sequenceNumber: McuSequenceNumber) -> Bool {
        guard let chunk = self.state[sequenceNumber]?.chunk,
              let expectedChunkSize = self.state[sequenceNumber]?.totalChunkSize else { return false }
        return chunk.count >= expectedChunkSize
    }
}
