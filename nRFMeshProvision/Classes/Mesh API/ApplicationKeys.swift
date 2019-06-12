//
//  ApplicationKeys.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 10/06/2019.
//

import Foundation

public extension Array where Element == ApplicationKey {
    
    subscript(keyIndex: KeyIndex) -> ApplicationKey? {
        return first {
            $0.index == keyIndex
        }
    }
    
}
