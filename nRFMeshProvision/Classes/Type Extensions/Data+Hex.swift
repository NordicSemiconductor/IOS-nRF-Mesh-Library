//
//  Data+Hex.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 27/03/2019.
//

import Foundation

extension Data {
    
    /// Hex string to Data representation
    /// Inspired by https://stackoverflow.com/questions/26501276/converting-hex-string-to-nsdata-in-swift
    public init?(hex: String) {
        let len = hex.count / 2
        var data = Data(capacity: len)
        
        for i in 0..<len {
            let j = hex.index(hex.startIndex, offsetBy: i * 2)
            let k = hex.index(j, offsetBy: 2)
            let bytes = hex[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
}
