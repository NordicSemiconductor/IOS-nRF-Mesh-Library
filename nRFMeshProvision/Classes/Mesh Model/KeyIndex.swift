//
//  KeyIndex.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 21/03/2019.
//

import Foundation

public typealias KeyIndex = UInt16

public extension KeyIndex {
    
    /// A Key Index is 12-bit long Unsigned Integer.
    /// This property returns `true` if the value is in range 0...4095.
    var isValidKeyIndex: Bool {
        return self >= 0 && self <= 4095
    }
    
}
