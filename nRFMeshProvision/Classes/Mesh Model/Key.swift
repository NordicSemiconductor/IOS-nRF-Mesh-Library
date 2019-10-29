//
//  Key.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 29/04/2019.
//

import Foundation

public protocol Key {
    /// UTF-8 string, which should be a human readable name of this key.
    var name: String { get set }
    /// Index of this key, in range from 0 through to 4095.
    var index: KeyIndex { get }
    /// 128-bit key.
    var key: Data { get }
}
