//
//  OptionSet+Data.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 07/05/2019.
//

import Foundation

extension OptionSet where RawValue == UInt8 {
    
    init(data: Data, offset: Int) {
        self.init(rawValue: data.convert(offset: offset))
    }
    
}

extension OptionSet where RawValue == UInt16 {
    
    init(data: Data, offset: Int) {
        self.init(rawValue: CFSwapInt16BigToHost(data.convert(offset: offset)))
    }
    
}
