//
//  ClosedRange+String.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 09/04/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

extension ClosedRange where Bound == UInt16 {
    
    func asString() -> String {
        return "\(lowerBound.asString()) - \(upperBound.asString())"
    }
    
}
