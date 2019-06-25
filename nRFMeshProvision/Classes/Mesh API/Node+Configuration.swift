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
       companyIdentifier = page0.companyIdentifier
       productIdentifier = page0.productIdentifier
       versionIdentifier = page0.versionIdentifier
       minimumNumberOfReplayProtectionList = page0.minimumNumberOfReplayProtectionList
       features = page0.features
        // Remove any existing Elements. There should not be any, but just to be sure.
        elements.forEach {
            $0.parentNode = nil
            $0.index = 0
        }
        elements.removeAll()
        // And add the Elements received.
        add(elements: page0.elements)
    }
    
    /// Applies the result of Config Default TTL Status message.
    ///
    /// - parameter defaultTtl: The response received.
    func apply(defaultTtl: ConfigDefaultTtlStatus) {
        ttl = defaultTtl.ttl
    }
    
}
