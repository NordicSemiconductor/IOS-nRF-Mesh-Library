//
//  SequenceNumber.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 19/03/2018.
//

import Foundation

public struct SequenceNumber {
    var count: UInt32
    let defaultsKey = "nRFMeshSequenceNumber"
    public init() {
        if let aNumber =  UserDefaults.standard.value(forKey: defaultsKey) as? UInt32 {
            count = aNumber
        } else {
            count = 0
            UserDefaults.standard.set(count, forKey: defaultsKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    public init(withCount aCount: UInt32) {
        count = aCount
        UserDefaults.standard.set(count, forKey: defaultsKey)
        UserDefaults.standard.synchronize()
    }
    
    public mutating func incrementSequneceNumber() {
        incrementAndStore()
    }
   
    public func sequenceData() -> Data {
        return convertToData(aNumber: count)
    }

    private mutating func incrementAndStore() {
        count += 1
        UserDefaults.standard.set(count, forKey: defaultsKey)
        UserDefaults.standard.synchronize()
    }

    private func convertToData(aNumber: UInt32) -> Data {
        let octet1 = UInt8((aNumber & 0x00FF0000) >> 16)
        let octet2 = UInt8((aNumber & 0x0000FF00) >> 8)
        let octet3 = UInt8(aNumber & 0x000000FF)
        return Data([octet1, octet2, octet3])
    }
}
