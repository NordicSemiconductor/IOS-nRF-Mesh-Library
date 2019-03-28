//
//  KeyIndex.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

public typealias KeyIndex = Int

public extension KeyIndex {
    
    public func isValidKeyIndex() -> Bool {
        return self >= 0 && self <= 4095
    }
}
