/*
* Copyright (c) 2021, Nordic Semiconductor
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

// This extension contains helper methods for handling Sequence Numbers
// of outgoing messages from the local Node. Each message must contain
// a unique 24-bit Sequence Number, which together with 32-bit IV Index
// ensure that replay attacks are not possible.
internal extension UserDefaults {
    
    /// Returns the next SEQ number to be used to send a message from
    /// the given Unicast Address.
    ///
    /// Each time this method is called returned value is incremented by 1.
    ///
    /// Size of SEQ is 24 bits.
    ///
    /// - parameter source: The Unicast Address of local Element.
    /// - returns: The next SEQ number to be used.
    func nextSequenceNumber(for source: Address) -> UInt32 {
        // Get the current sequence number source address.
        let sequence = UInt32(integer(forKey: "S\(source.hex)"))
        // As the sequence number was just used, it has to be incremented.
        set(sequence + 1, forKey: "S\(source.hex)")
        return sequence
    }
    
    /// Resets the SEQ associated with all Elements of the given Node to 0.
    ///
    /// This method should be called when the IV Index is incremented and SEQ
    /// number should be reset.
    ///
    /// - parameter node: The local Node.
    func resetSequenceNumbers(of node: Node) {
        node.elements.forEach { element in
            set(0, forKey: "S\(element.unicastAddress.hex)")
        }
    }
    
    /// Removes the SEQ number associated with the given address.
    ///
    /// - parameter source: The address to be forgotten.
    func removeSequenceNumber(for source: Address) {
        removeObject(forKey: "S\(source.hex)")
    }
    
}

// This extension contains helper methods for handling SeqAuth values
// of received messages. The local Node must remember the last SeqAuth value
// received from all Nodes it is communicating with and discard messages
// having lower or equal SeqAuth value, as potential replies.
internal extension UserDefaults {
    
    /// Returns the last SeqAuth value stored for the given source address, or nil,
    /// if no message has ever been received from that address.
    ///
    /// The SeqAuth value ensures uniqueness of each message. Each message from
    /// the same source address must be sent with unique value of SeqAuth.
    ///
    /// - parameter source: The source Unicast Address.
    /// - returns: The 32+24 bit SeqAuth value, or nil.
    func lastSeqAuthValue(for source: Address) -> UInt64? {
        return (object(forKey: source.hex) as? NSNumber)?.uint64Value
    }
    
    /// Stores the last received SeqAuth value in User Defaults.
    ///
    /// - parameters:
    ///   - value: The SeqAuth value of received message.
    ///   - source: The source Unicast Address.
    func storeLastSeqAuthValue(_ value: UInt64, for source: Address) {
        set(NSNumber(value: value), forKey: source.hex)
    }
    
    /// Returns the previous SeqAuth value for the given source address, or nil,
    /// if no more than 1 message has ever been received from that address.
    ///
    /// - parameter source: The source Unicast Address.
    /// - returns: The 32+24 bit SeqAuth value, or nil.
    func previousSeqAuthValue(for source: Address) -> UInt64? {
        return (object(forKey: "P\(source.hex)") as? NSNumber)?.uint64Value
    }
    
    /// Stores the previously received SeqAuth value in User Defaults.
    ///
    /// - parameters:
    ///   - value: The previously received SeqAuth value.
    ///   - source: The source Unicast Address.
    func storePreviousSeqAuthValue(_ value: UInt64, for source: Address) {
        set(NSNumber(value: value), forKey: "P\(source.hex)")
    }
    
    /// Removes all known SeqAuth values associated with any of the Elements
    /// of the given remote Node.
    ///
    /// - parameter node: The remote Node.
    func removeSeqAuthValues(of node: Node) {
        node.elements.forEach { element in
            removeSeqAuthValues(of: element.unicastAddress)
        }
    }
    
    /// Removes last known SeqAuth value associated with the given address
    /// of a remote Node.
    ///
    /// - parameter source: The forgotten Address.
    func removeSeqAuthValues(of source: Address) {
        removeObject(forKey: source.hex)
        removeObject(forKey: "P\(source.hex)")
    }
    
}
