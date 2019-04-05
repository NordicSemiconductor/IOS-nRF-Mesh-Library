//
//  AddressRange+String.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 04/04/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import nRFMeshProvision

extension AddressRange {
    
    func asString() -> String {
        return "\(lowAddress.asString()) - \(highAddress.asString())"
    }
    
}

extension Array where Element == AddressRange {
    
    func asString() -> String {
        if count == 1 {
            return self[0].asString()
        }
        return "\(count) ranges"
    }
    
}
