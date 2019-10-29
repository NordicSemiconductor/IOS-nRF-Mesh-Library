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

public extension Node {
    
    /// Number of Node's Elements.
    var elementsCount: UInt8 {
        return UInt8(elements.count)
    }
    
    /// The last Unicast Address allocated to this Node. Each Node's Element
    /// uses its own subsequent Unicast Address. The first (0th) Element is identified
    /// by the Node's Unicast Address.
    var lastUnicastAddress: Address {
        let allocatedAddresses = Address(elementsCount > 0 ? elementsCount : 1)
        return unicastAddress + allocatedAddresses - 1
    }
    
    /// Returns whether the address uses the given Unicast Address for one
    /// of its Elements.
    ///
    /// - parameter address: Address to check.
    /// - returns: `True` if any of node's elements (or the node itself) was assigned
    ///            the given address, `false` otherwise.
    func hasAllocatedAddress(_ address: Address) -> Bool {
        return address >= unicastAddress && address <= lastUnicastAddress
    }
    
    /// Returns whether the node address range overlaps with the given
    /// address range.
    ///
    /// - parameter address: Address to check.
    /// - parameter count:   Number of following addresses to check.
    /// - returns: `True`, if the node address range overlaps with the given
    ///            range, `false` otherwise.
    func overlapsWithAddress(_ address: Address, elementsCount count: UInt8) -> Bool {
        return !(unicastAddress + UInt16(elementsCount) - 1 < address
              || unicastAddress > address + UInt16(count) - 1)
    }
    
}
