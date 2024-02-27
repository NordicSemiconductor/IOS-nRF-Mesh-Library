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

internal protocol SegmentedMessage: LowerTransportPdu {
    /// The Mesh Message that is being sent, or `nil`, when the message
    /// was received.
    var message: MeshMessage? { get }
    /// Whether sending this message has been initiated by the user.
    var userInitiated: Bool { get }
    /// 13 least significant bits of SeqAuth (SeqZero).
    var sequenceZero: UInt16 { get }
    /// This field is set to the segment number (zero-based)
    /// of the segment m of this Upper Transport PDU (SegO).
    var segmentOffset: UInt8 { get }
    /// This field is set to the last segment number (zero-based)
    /// of this Upper Transport PDU (SegN).
    var lastSegmentNumber: UInt8 { get }
}

internal extension SegmentedMessage {
    
    /// Returns whether the message is composed of only a single
    /// segment. Single segment messages are used to send short,
    /// acknowledged messages. The maximum size of payload of upper
    /// transport control PDU is 8 bytes.
    var isSingleSegment: Bool {
        return lastSegmentNumber == 0
    }
    
    /// Returns the `segmentOffset` as `Int`.
    var index: Int {
        return Int(segmentOffset)
    }
    
    /// Returns the expected number of segments for this message.
    var count: Int {
        return Int(lastSegmentNumber + 1)
    }
    
}
