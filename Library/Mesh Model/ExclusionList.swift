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

/// This object contains list of excluded Unicast Addresses for particular IV Index.
///
/// The excluded addresses cannot be assigned to new Nodes until the current IV Index
/// is greater by 2 or more to the given one. At that point, the Seq Auth value
/// (IV Index + Sequence number) is always greater than the value used by the deleted
/// Node.
///
/// - seeAlso: IvIndex
internal class ExclusionList: Codable {
    /// The IV Index of the mesh network that was in use while the Unicast Addresses
    /// were marked as excluded.
    let ivIndex: UInt32
    /// Excluded Unicast Addresses for the particular IV Index.
    var addresses: [Address]
    
    init(for ivIndex: IvIndex) {
        self.ivIndex = ivIndex.index
        self.addresses = []
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: CodingKey {
        case ivIndex
        case addresses
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.ivIndex = try container.decode(UInt32.self, forKey: .ivIndex)
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
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ivIndex, forKey: .ivIndex)
        try container.encode(addresses.map { $0.hex }, forKey: .addresses)
    }
}

internal extension ExclusionList {
    
    /// Returns whether the given Unicast Address is excluded, or not.
    ///
    /// - parameter address: The Unicast Address to test.
    /// - returns: `True` if the Address cannot be used; `false` otherwise.
    func isExcluded(_ address: Address) -> Bool {
        return addresses.contains(address)
    }
    
    /// Adds the given Unicast Address to exclusion list.
    ///
    /// - parameter address: The address to be excluded.
    func exclude(_ address: Address) {
        guard address.isUnicast else {
            return
        }
        addresses.append(address)
    }
    
    /// Adds all Unicast Addresses of all Elements on the Node to the
    /// exclusion list.
    ///
    /// - parameter node: The removed Node.
    func exclude(_ node: Node) {
        node.elements.forEach { element in
            exclude(element.unicastAddress)
        }
    }
    
}

internal extension Array where Element ==  ExclusionList {
    
    subscript(ivIndex: UInt32) -> ExclusionList? {
        return first {
            $0.ivIndex == ivIndex
        }
    }
    
    subscript(ivIndex: IvIndex) -> ExclusionList? {
        return first {
            $0.ivIndex == ivIndex.index
        }
    }
    
    /// Appends Unicast Addresses of all Elements belonging to the given Node
    /// to the exclusion list associated with the given IV Index.
    ///
    /// - parameters:
    ///   - node: The removed Node.
    ///   - ivIndex: The current IV Index.
    mutating func append(_ node: Node, forIvIndex ivIndex: IvIndex) {
        var entry: ExclusionList! = self[ivIndex.index]
        if entry == nil {
            entry = ExclusionList(for: ivIndex)
            append(entry)
        }
        entry.exclude(node)
    }
    
    /// Removes all exclusion lists that for old values of IV Index.
    ///
    /// - parameter ivIndex: The current IV Index.
    mutating func cleanUp(forIvIndex ivIndex: IvIndex) {
        removeAll { $0.addresses.isEmpty }
        guard ivIndex.index >= 2 else {
            return
        }
        removeAll { $0.ivIndex <= ivIndex.index - 2 }
    }
    
    /// List of excluded Unicast Addresses for the given IV Index.
    ///
    /// - parameter ivIndex: The current IV Index.
    func excludedAddresses(forIvIndex ivIndex: IvIndex) -> [Address] {
        return self
            .filter { $0.ivIndex == ivIndex.index || (ivIndex.index > 0 && $0.ivIndex == ivIndex.index - 1) }
            .flatMap { $0.addresses }
    }
    
    /// Checks whether the given Unicast Address range cannot be reassigned to
    /// a new Node, as at least one of the addresses from the given range has
    /// been used by a recently removed Node.
    ///
    /// Unicast Addresses may be excluded, as other Nodes may still keep the
    /// Sequence number associated with those addresses and may discard packets
    /// sent from them until the new Sequence number exceeds the saved one.
    ///
    /// A Unicast Address may be reassigned to a new Node when the IV Index
    /// increments by at least 2 since the it has been excluded, after which
    /// the Seq Auth value (IV Index + Sequence number) is always greater than
    /// one used for the deleted Node.
    ///
    /// - parameters:
    ///   - range:   The Unicast Address range to check.
    ///   - ivIndex: The current IV Index.
    /// - returns: `True` if at least one address from the given address range
    ///             is excluded; `false` otherwise.
    func contains(_ range: AddressRange, forIvIndex ivIndex: IvIndex) -> Bool {
        guard count > 0 else {
            return false
        }
        return !excludedAddresses(forIvIndex: ivIndex)
            .filter { range.contains($0) }
            .isEmpty
    }
    
    /// Checks whether the given Unicast Address should not be reassigned to
    /// a new Node, as it has been used by a Node that was recently removed.
    /// Other Nodes may still keep the Sequence number associated with this
    /// address and may discard packets sent from it.
    ///
    /// - parameters:
    ///   - address: The Unicast Address to check.
    ///   - count:   Number of Elements to check.
    ///   - ivIndex: The current IV Index.
    /// - returns: `True` if the given address is excluded; `false` otherwise.
    @available(*, deprecated, message: "Use contains(_:forIvIndex:) instead")
    func contains(_ address: Address, elementCount count: UInt8 = 1,
                    forIvIndex ivIndex: IvIndex) -> Bool {
        guard count > 0 else {
            return false
        }
        return !excludedAddresses(forIvIndex: ivIndex)
            .filter { $0 >= address && $0 <= address + UInt16(count) - 1 }
            .isEmpty
    }
    
}
