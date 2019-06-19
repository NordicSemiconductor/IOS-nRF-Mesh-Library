//
//  Node+Configuration.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 19/06/2019.
//

import Foundation

public extension Node {
    
    /// Returns weather Composition Data has been applied to the Node.
    var isConfigured: Bool {
        return companyIdentifier != nil
    }
    
    /// Applies the result of Composition Data to the Node.
    ///
    /// This method does nothing if the Node already was configured
    /// or the Composition Data Status does not have Page 0.
    ///
    /// - parameter compositionData: The result of Config Composition Data Get
    ///                              with page 0.
    func apply(compositionData: ConfigCompositionDataStatus) {
        guard !isConfigured else {
            return
        }
        guard let page0 = compositionData.page as? Page0 else {
            return
        }
        page0.apply(to: self)
    }
    
}
