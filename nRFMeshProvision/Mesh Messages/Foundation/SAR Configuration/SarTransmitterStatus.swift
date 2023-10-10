/*
* Copyright (c) 2023, Nordic Semiconductor
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

/// A `SarTransmitterStatus` message is an unacknowledged message used to report
/// the current SAR Transmitter state of a Node.
public struct SarTransmitterStatus: ConfigResponse {
    public static let opCode: UInt32 = 0x806E
    
    public var parameters: Data? {
        return Data([
            sarSegmentIntervalStep | (sarUnicastRetransmissionsCount << 4),
            sarUnicastRetransmissionsWithoutProgressCount | (sarUnicastRetransmissionsIntervalStep << 4),
            sarUnicastRetransmissionsIntervalIncrement | (sarMulticastRetransmissionsCount << 4),
            sarMulticastRetransmissionsIntervalStep // | (RSU << 4)
        ])
    }
    
    // MARK: - SAR Transmitter states
    
    /// The **SAR Segment Interval Step state** is a 4-bit value that controls
    /// the interval between transmissions of segments of a segmented message using
    /// a ADV bearer.
    ///
    /// The segment transmission interval is the number of milliseconds calculated
    /// using the following formula:
    /// ```
    /// (SAR Segment Interval Step + 1) * 10 ms
    /// ```
    /// The default value of the **SAR Segment Interval Step state** is `0b0101`
    /// (60 milliseconds). 
    ///
    /// - seeAlso: ``segmentTransmissionInterval``
    public let sarSegmentIntervalStep: UInt8
    
    /// The **SAR Unicast Retransmissions Count state** is a 4-bit value that
    /// controls the maximum number of transmissions of segments of segmented
    /// messages to a Unicast destination.
    ///
    /// The maximum number of transmissions of a segment is given with the formula:
    /// ```
    /// SAR Unicast Retransmissions Count + 1
    /// ```
    /// For example, `0b0000` represents a single transmission, and `0b0111`
    /// represents 8 transmissions.
    ///
    /// The default value of the **SAR Unicast Retransmissions Count state** is
    /// `0b0010` (3 transmissions). 
    public let sarUnicastRetransmissionsCount: UInt8
    
    /// The **SAR Unicast Retransmissions Without Progress Count state**
    /// is a 4-bit value that controls the maximum number of transmissions of segments
    /// of segmented messages to a Unicast destination without progress
    /// (i.e., without newly marking any segment as acknowledged).
    ///
    /// The maximum number of transmissions of a segment without progress is
    /// calculated using the formula:
    /// ```
    /// SAR Unicast Retransmissions Without Progress Count + 1
    /// ```
    /// For example, `0b0000` represents a single transmission, and `0b0111`
    /// represents 8 transmissions.
    ///
    /// The default value of the **SAR Unicast Retransmissions Without Progress
    /// Count state** is `0b0010` (3 transmissions). 
    ///
    /// - note: The value of this state should be set to a value greater than the
    ///         value of the **SAR Acknowledgement Retransmissions Count**
    ///         on a peer node. This helps prevent the SAR transmitter from
    ///         abandoning the SAR prematurely.
    public let sarUnicastRetransmissionsWithoutProgressCount: UInt8
    
    /// The **SAR Unicast Retransmissions Interval Step state** is a 4-bit value
    /// that controls the interval between retransmissions of segments of a segmented
    /// message for a destination that is a Unicast Address.
    ///
    /// The unicast retransmissions interval step is the number of milliseconds calculated
    /// using the following formula:
    /// ```
    /// (SAR Unicast Retransmissions Interval Step + 1) * 25 (ms)
    /// ```
    /// The default value of the **SAR Unicast Retransmissions Interval Step**
    /// is `0b0111` (200 milliseconds).
    ///
    /// - seeAlso: ``unicastRetransmissionsIntervalStep``
    public let sarUnicastRetransmissionsIntervalStep: UInt8
    
    /// The **SAR Unicast Retransmissions Interval Increment state** is a 4-bit
    /// value that controls the incremental component of the interval between
    /// retransmissions of segments of a segmented message for a destination
    /// that is a Unicast Address.
    ///
    /// The unicast retransmissions interval increment is the number of milliseconds
    /// calculated using the following formula:
    /// ```
    /// (SAR Unicast Retransmissions Interval Increment + 1) * 25 (ms)
    /// ```
    /// The default value of the **SAR Unicast Retransmissions Interval Increment state**
    /// is `0b0001` (50 milliseconds).
    public let sarUnicastRetransmissionsIntervalIncrement: UInt8
    
    /// The **SAR Multicast Retransmissions Count state** is a 4-bit value that
    /// controls the maximum number of transmissions of segments of segmented
    /// messages to a group address or a virtual address.
    ///
    /// The maximum number of transmissions of a segment is calculated with the following formula:
    /// ```
    /// SAR Multicast Retransmissions Count + 1
    /// ```
    /// For example, `0b0000` represents a single transmission, and `0b0111`
    /// represents 8 transmissions.
    ///
    /// The default value of the **SAR Multicast Retransmissions Count state** is
    /// `0b0010` (3 transmissions).
    public let sarMulticastRetransmissionsCount: UInt8
    
    /// **The SAR Multicast Retransmissions Interval Step state** is a 4-bit
    /// value that controls the interval between retransmissions of segments of a
    /// segmented message for a destination that is a group address or a virtual address.
    ///
    /// The multicast retransmissions interval is the number of milliseconds
    /// calculated using the following formula:
    /// ```
    /// SAR Multicast Retransmissions Interval Step + 1
    /// ```
    /// The default value of the **SAR Multicast Retransmissions Interval Step state** is
    /// `0b1001` (250 milliseconds).
    ///
    /// - seeAlso: ``multicastRetransmissionsInterval``
    public let sarMulticastRetransmissionsIntervalStep: UInt8
    
    // MARK: - Helper methods
    
    /// The interval between transmissions of segments of a segmented message.
    ///
    /// The value ot this interval is indicated by **SAR Segment Interval Step state**.
    ///
    /// - seeAlso: ``sarSegmentIntervalStep``
    public var segmentTransmissionInterval: TimeInterval {
        return Double(sarSegmentIntervalStep + 1) * 0.01
    }
    
    
    /// The interval between retransmissions of segments of a segmented
    /// message for a destination that is a Unicast Address.
    ///
    /// Valid range is from 25 ms to 400 ms with 25 ms interval.
    /// - seeAlso: ``sarUnicastRetransmissionsIntervalStep``
    public var unicastRetransmissionsIntervalStep: TimeInterval {
        return Double(sarUnicastRetransmissionsIntervalStep + 1) * 0.025
    }
    
    /// The incremental component of the interval between retransmissions of segments
    /// of a segmented message for a destination that is a Unicast Address.
    ///
    /// The increment component is multiplied by `TTL - 1` when calculating the
    /// initial value of the SAR Unicast Retransmissions timer.
    ///
    /// Valid range is from 25 ms to 400 ms with 25 ms interval.
    /// - seeAlso: ``sarUnicastRetransmissionsIntervalIncrement``
    public var unicastRetransmissionsIntervalIncrement: TimeInterval {
        return Double(sarUnicastRetransmissionsIntervalIncrement + 1) * 0.025
    }
    
    /// The interval between retransmissions of segments of a segmented message for
    /// a destination that is a Group Address or a Virtual Address.
    ///
    /// Valid range is from 25 ms to 400 ms with 25 ms interval.
    ///
    /// - seeAlso: ``sarMulticastRetransmissionsIntervalStep``
    public var multicastRetransmissionsInterval: TimeInterval {
        return Double(sarMulticastRetransmissionsIntervalStep + 1) * 0.025
    }
    
    // MARK: - Initializers
    
    /// Creates a ``SarTransmitterStatus`` message.
    ///
    /// - parameters:
    ///   - sarSegmentIntervalStep: See ``sarSegmentIntervalStep``.
    ///   - sarUnicastRetransmissionsCount: See ``sarUnicastRetransmissionsCount``.
    ///   - sarUnicastRetransmissionsWithoutProgressCount: See ``sarUnicastRetransmissionsWithoutProgressCount``.
    ///   - sarUnicastRetransmissionsIntervalStep: See ``sarUnicastRetransmissionsIntervalStep``.
    ///   - sarUnicastRetransmissionsIntervalIncrement: See ``sarUnicastRetransmissionsIntervalIncrement``.
    ///   - sarMulticastRetransmissionsCount: See ``sarMulticastRetransmissionsCount``.
    ///   - sarMulticastRetransmissionsIntervalStep: See ``sarMulticastRetransmissionsIntervalStep``.
    public init(
        sarSegmentIntervalStep: UInt8,
        sarUnicastRetransmissionsCount: UInt8,
        sarUnicastRetransmissionsWithoutProgressCount: UInt8,
        sarUnicastRetransmissionsIntervalStep: UInt8,
        sarUnicastRetransmissionsIntervalIncrement: UInt8,
        sarMulticastRetransmissionsCount: UInt8,
        sarMulticastRetransmissionsIntervalStep: UInt8
    ) {
        self.sarSegmentIntervalStep = sarSegmentIntervalStep
        self.sarUnicastRetransmissionsCount = sarUnicastRetransmissionsCount
        self.sarUnicastRetransmissionsWithoutProgressCount = sarUnicastRetransmissionsWithoutProgressCount
        self.sarUnicastRetransmissionsIntervalStep = sarUnicastRetransmissionsIntervalStep
        self.sarUnicastRetransmissionsIntervalIncrement = sarUnicastRetransmissionsIntervalIncrement
        self.sarMulticastRetransmissionsCount = sarMulticastRetransmissionsCount
        self.sarMulticastRetransmissionsIntervalStep = sarMulticastRetransmissionsIntervalStep
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 4 else {
            return nil
        }
        sarSegmentIntervalStep = parameters[0] & 0x0F
        sarUnicastRetransmissionsCount = (parameters[0] >> 4) & 0x0F
        sarUnicastRetransmissionsWithoutProgressCount = parameters[1] & 0x0F
        sarUnicastRetransmissionsIntervalStep = (parameters[1] >> 4) & 0x0F
        sarUnicastRetransmissionsIntervalIncrement = parameters[2] & 0x0F
        sarMulticastRetransmissionsCount = (parameters[2] >> 4) & 0x0F
        sarMulticastRetransmissionsIntervalStep = parameters[3] & 0x0F
        // 4 remaining bits are RFU
    }
}
