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

public class Scene: Codable {
    internal weak var meshNetwork: MeshNetwork?
    
    /// Scene number.
    public let number: SceneNumber
    /// UTF-8 human-readable name of the Scene.
    public var name: String
    /// Addresses of Nodes whose Scene Register state contains this Scene.
    public internal(set) var addresses: [Address]
    
    internal init(_ number: SceneNumber, name: String) {
        self.number = number
        self.name = name
        self.addresses = []
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: CodingKey {
        case scene
        case name
        case addresses
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let sceneNumberString  = try container.decode(String.self, forKey: .scene)
        guard let number = SceneNumber(hex: sceneNumberString) else {
            throw DecodingError.dataCorruptedError(forKey: .scene, in: container,
                                                       debugDescription: "Scene must be 4-character hexadecimal string.")
        }
        guard number.isValidSceneNumber else {
            throw DecodingError.dataCorruptedError(forKey: .scene, in: container,
                                                   debugDescription: "Invalid scene number.")
        }
        self.number = number
        self.name = try container.decode(String.self, forKey: .name)
        self.addresses = []
        let addressesStrings = try container.decode([String].self, forKey: .addresses)
        try addressesStrings.forEach {
            guard let address = Address(hex: $0) else {
                throw DecodingError.dataCorruptedError(forKey: .addresses, in: container,
                                                       debugDescription: "Address must be 4-character hexadecimal.")
            }
            guard address.isUnicast else {
                throw DecodingError.dataCorruptedError(forKey: .addresses, in: container,
                                                       debugDescription: "Address must be of unicast type.")
            }
            self.addresses.append(address)
        }
        self.addresses.sort()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(number.hex, forKey: .scene)
        try container.encode(name, forKey: .name)
        try container.encode(addresses.map { $0.hex }, forKey: .addresses)
    }
}

internal extension Scene {
    
    /// Adds the given Node to the Scene object.
    ///
    /// - parameter node: The Node that is confirmed to have the Scene in its Scene Register.
    func add(node: Node) {
        guard !addresses.contains(node.unicastAddress) else {
            return
        }
        addresses.append(node.unicastAddress)
        addresses.sort()
        meshNetwork?.timestamp = Date()
    }
    
    /// Removes the given Node from the Scene object.
    ///
    /// - parameter node: The Node that is confirmed not to have the Scene in its Scene Register.
    func remove(node: Node) {
        if let index = addresses.firstIndex(of: node.unicastAddress) {
            addresses.remove(at: index)
            meshNetwork?.timestamp = Date()
        }
    }
    
}

extension Scene: Equatable, Comparable, Hashable {
    
    public static func == (lhs: Scene, rhs: Scene) -> Bool {
        return lhs.number == rhs.number
    }
    
    public static func < (lhs: Scene, rhs: Scene) -> Bool {
        return lhs.number < rhs.number
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(number)
    }
    
}
