//
//  SceneRange+String.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 04/04/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import nRFMeshProvision

extension SceneRange {
    
    func asString() -> String {
        return range.asString()
    }
    
}

extension Array where Element == SceneRange {
    
    func asString() -> String {
        if count == 1 {
            return self[0].asString()
        }
        return "\(count) ranges"
    }
    
}
