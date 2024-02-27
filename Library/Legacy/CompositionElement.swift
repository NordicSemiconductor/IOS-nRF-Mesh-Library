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

/// This is a legacy class from nRF Mesh Provision 1.0.x library.
/// The only purpose of this class here is to allow to migrate from
/// the old data format to the new one.
internal struct CompositionElement: Codable {
    
    // MARK: - Properties
    private let location                    : Data
    private let sigModelCount               : Int
    private let vendorModelCount            : Int
    private let sigModels                   : [Data]
    private let vendorModels                : [Data]
    private let allModels                   : [Data]
    private let modelKeyBindings            : [Data: Data]
    private let modelPublishAddress         : [Data: Data]
    private let modelSubscriptionAddresses  : [Data: [Data]]
    
    func groups(for data: Data) -> [Group] {
        return modelSubscriptionAddresses[data]?.compactMap {
            let address: Address = $0.asUInt16
            return try? Group(name: "Group 0x\(address.hex)", address: address)
        } ?? []
    }
    
    var subscribedGroups: [Group] {
        return modelSubscriptionAddresses.flatMap { data in
            groups(for: data.key)
        }
    }
    
    var element: Element {
        let element = Element(location: Location(rawValue: location.asUInt16) ?? .unknown)
        sigModels.forEach {
            let model = Model(sigModelId: $0.asUInt16)
            if let binding = modelKeyBindings[$0] {
                model.bind(applicationKeyWithIndex: binding.asUInt16)
                
                if let publication = modelPublishAddress[$0] {
                    model.set(publication:
                        Publish(to: MeshAddress(publication.asUInt16), withKeyIndex: binding.asUInt16)
                    )
                }
            }
            groups(for: $0).forEach { group in model.subscribe(to: group )}
            element.add(model: model)
        }
        vendorModels.forEach { element.add(model: Model(modelId: $0.asUInt32)) }
        return element
    }
}

private extension Data {
    
    var asUInt16: UInt16 {
        return (UInt16(self[0]) << 8) | UInt16(self[1])
    }
    
    var asUInt32: UInt32 {
        return (UInt32(self[0]) << 24) | (UInt32(self[1]) << 16) | (UInt32(self[2]) << 8) | UInt32(self[3])
    }
    
}
