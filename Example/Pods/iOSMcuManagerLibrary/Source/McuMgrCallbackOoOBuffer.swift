//
//  McuMgrCallbackOoOBuffer.swift
//  iOSMcuManagerLibrary
//
//  Created by Dinesh Harjani on 29/9/22.
//

import Foundation
import Dispatch
import os.log

// MARK: - McuMgrCallbackOoOBuffer<Key, Value>

/**
 <Key, Value> Out-of-Order Buffer.
 */
public struct McuMgrCallbackOoOBuffer<Key: Hashable & Comparable, Value> {
    
    // MARK: BufferError
    
    enum BufferError: Error {
        case empty
        case invalidKey(_ key: Key)
        case noValueForKey(_ key: Key)
    }
    
    // MARK: Private
    
    private var internalQueue = DispatchQueue(label: "mcumgr.robbuffer.queue")
    
    private var expectedKeys: [Key] = []
    private var outOfOrderKeys: Set<Key> = []
    private var buffer: [Key: Value] = [:]
    
    // MARK: API
    
    public weak var logDelegate: McuMgrLogDelegate?
    
    /**
     Required call when a `Key` is now expected, so the buffer can track it.
     
     For example, if you'd like to be able to reorder a sequence of expected
     events, when you know a certain event is expected to happen, you must call
     this function. Subsequent calls to this function should reflect the expected
     order of responses, so for example, if you expect events A, B, C, D, E,
     call in said order.
     */
    mutating func enqueueExpectation(for key: Key) {
        internalQueue.sync {
            expectedKeys.append(key)
        }
    }
    
    /**
     Required call when a `Value` is received.
     
     This function informs the buffer a `Value` has been received. If the
     buffer recommends proceeding with a call to get a value, which is
     through the `deliver(to:)` API, it will return true. If not, the buffer
     is pending reception of values for a different key.
     
     - returns: `true` if a subsequent call to `deliver(to:)` is suggested.
     */
    mutating func received(_ value: Value, for key: Key) throws -> Bool {
        try internalQueue.sync {
            guard let i = expectedKeys.firstIndex(where: { $0 == key }) else {
                if outOfOrderKeys.contains(key) {
                    buffer[key] = value
                    log(msg: "Received missing OoO (Out of Order) Key \(key).", atLevel: .debug)
                    outOfOrderKeys.remove(key)
                    // Deliver the received key.
                    return true
                } else {
                    throw BufferError.invalidKey(key)
                }
            }
            
            guard let lowestExpectedKey = expectedKeys.first else {
                throw BufferError.empty
            }
            assert(expectedKeys[i] == key)
            buffer[key] = value

            let valueReceivedInOrder = i == 0
            guard !valueReceivedInOrder else {
                expectedKeys.removeFirst()
                return true
            }
            
            let lowerKeys = expectedKeys.filter({ $0 < key })
            lowerKeys.forEach {
                outOfOrderKeys.insert($0)
            }
            
            log(msg: "Received Value for Key \(key) OoO (Out of Order). Expected \(lowestExpectedKey) instead.",
                atLevel: .debug)
            expectedKeys.removeAll(where: { $0 <= key })
            return false // Wait until we next receive a value.
        }
    }
    
    /**
     Call to receive `Value`(s) that have been received thus far.
     
     Designed for use in conjunction with `received(_,for:)`. If there are
     `Value`(s) missing because some have been received out of order, nothing
     will be returned. See the aforementioned function for more information.
     
     - returns: Undelivered `Value`(s) received in order, if none is pending.
     */
    mutating func deliver(to callback: @escaping ((Key, Value) -> Void)) throws {
        try internalQueue.sync {
            // Wait until there's nothing OoO to return.
            guard outOfOrderKeys.isEmpty else { return }
            
            for key in buffer.keys.sorted(by: <) {
                guard let value = buffer.removeValue(forKey: key) else {
                    throw BufferError.noValueForKey(key)
                }
                
                DispatchQueue.main.async {
                    callback(key, value)
                }
            }
        }
    }
}

private extension McuMgrCallbackOoOBuffer {
    
    func log(msg: @autoclosure () -> String, atLevel level: McuMgrLogLevel) {
        if let logDelegate, level >= logDelegate.minLogLevel() {
            logDelegate.log(msg(), ofCategory: .transport, atLevel: level)
        }
    }
    
}
