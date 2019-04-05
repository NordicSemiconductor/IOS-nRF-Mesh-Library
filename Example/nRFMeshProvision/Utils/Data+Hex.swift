//
//  File.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 01/04/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

extension Data {
    
    /// Returns the Data object as hexadecimal String without
    /// leading "0x".
    func asString() -> String {
        return map { String(format: "%02hhX", $0) }.joined()
    }
    
}
