/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

/// A base protocol of a single Page of Composition Data.
///
/// The Composition Data state contains information about a Node,
/// the Elements it includes, and the supported models.
///
/// The Composition Data is composed of a number of pages of information.
public protocol CompositionDataPage {
    /// Page number of the Composition Data to get.
    var page: UInt8 { get }
    /// Composition Data parameters as Data.
    var parameters: Data? { get }
}

public struct ConfigCompositionDataStatus: ConfigResponse {
    public static let opCode: UInt32 = 0x02
    
    public var parameters: Data? {
        return page?.parameters
    }
    
    /// The Composition Data page.
    public let page: CompositionDataPage?
    
    public init(report page: CompositionDataPage) {
        self.page = page
    }
    
    public init?(parameters: Data) {
        guard parameters.count > 0 else {
            return nil
        }
        switch parameters[0] {
        case 0:
            guard let page0 = Page0(parameters: parameters) else {
                return nil
            }
            page = page0
        default:
            // Other Pages are not supported.
            return nil
        }
    }
}

/// Composition Data Page 0 shall be present on a Node.
///
/// Composition Data Page 0 shall not change during a term of a Node
/// on the network.
public struct Page0: CompositionDataPage {
    public let page: UInt8
    
    /// The 16-bit Company Identifier (CID) assigned by the Bluetooth SIG.
    ///
    /// Company Identifiers are published in
    /// [Assigned Numbers](https://www.bluetooth.com/specifications/assigned-numbers/).
    public let companyIdentifier: UInt16
    /// The 16-bit vendor-assigned Product Identifier (PID).
    public let productIdentifier: UInt16
    /// The 16-bit vendor-assigned Version Identifier (VID).
    public let versionIdentifier: UInt16
    /// The minimum number of Replay Protection List (RPL) entries for this
    /// node.
    public let minimumNumberOfReplayProtectionList: UInt16
    /// Node's features.
    ///
    /// The Page 0 of the Composition Data does not provide information
    /// whether a feature is enabled or disabled, just whether it is supported
    /// or not. Read the state of each feature using corresponding Config
    /// message.
    public let features: NodeFeaturesState
    /// An array of node's elements.
    public let elements: [Element]
    
    public var parameters: Data? {
        let data = Data([page])
            + companyIdentifier + productIdentifier + versionIdentifier
            + minimumNumberOfReplayProtectionList
        return data + features.rawValue + elements.data
    }
    
    /// This initializer constructs the Page 0 of Composition Data from
    /// the given Node.
    ///
    /// - parameter node: The Node to construct the Page 0 from.
    public init(node: Node) {
        page = 0
        companyIdentifier = node.companyIdentifier ?? 0
        productIdentifier = node.productIdentifier ?? 0
        versionIdentifier = node.versionIdentifier ?? 0
        minimumNumberOfReplayProtectionList = node.minimumNumberOfReplayProtectionList ?? 0
        features = node.features ?? NodeFeaturesState()
        elements = node.elements
    }
    
    /// This initializer should construct the message based on the
    /// received parameters.
    ///
    /// - parameter parameters: The Access Layer parameters.
    public init?(parameters: Data) {
        guard parameters.count >= 11, parameters[0] == 0 else {
            return nil
        }
        page = 0
        companyIdentifier = parameters.read(fromOffset: 1)
        productIdentifier = parameters.read(fromOffset: 3)
        versionIdentifier = parameters.read(fromOffset: 5)
        minimumNumberOfReplayProtectionList = parameters.read(fromOffset: 7)
        features = NodeFeaturesState(mask: parameters.read(fromOffset: 9))
        
        var readElements: [Element] = []
        var offset = 11
        while offset < parameters.count {
            guard let element = Element(compositionData: parameters, offset: &offset) else {
                return nil
            }
            element.index = UInt8(readElements.count)
            readElements.append(element)
        }
        elements = readElements
    }
}

// MARK: - Helper extension

private extension Array where Element == MeshElement {
    
    /// Returns Elements and their Models as Data, to be sent in
    /// Page 0 of the Composition Data.
    var data: Data {
        var data = Data()
        for element in self {
            data += element.location.rawValue
            
            var sigModels: [Model] = []
            var vendorModel: [Model] = []
            for model in element.models {
                if model.isBluetoothSIGAssigned {
                    sigModels.append(model)
                } else {
                    vendorModel.append(model)
                }
            }
            data += UInt8(sigModels.count)
            data += UInt8(vendorModel.count)
            
            for model in sigModels {
                data += model.modelIdentifier
            }
            for model in vendorModel {
                data += model.companyIdentifier!
                data += model.modelIdentifier
            }
        }
        return data
    }
    
}
