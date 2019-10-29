//
//  Node+Elements.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 02/07/2019.
//

import Foundation

public extension Node {    
    
    /// Returns the Element that belongs to this Node with the given
    /// Unicast Address, or `nil`, if such does not exist.
    ///
    /// - parameter address: The Unicast Address of an Element to get.
    /// - returns: The Element found, or `nil`, if no such exist.
    func element(withAddress address: Address) -> Element? {
        let index = Int(address - unicastAddress)
        guard index >= 0 && index < elements.count else {
            return nil
        }
        return elements[index]
    }
    
}
