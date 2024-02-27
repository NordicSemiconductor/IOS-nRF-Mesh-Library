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

/// A `SarReceiverStatus` message is an unacknowledged message used to report the current 
/// SAR Receiver state of a Node.
public struct SarReceiverStatus: ConfigResponse {
    public static let opCode: UInt32 = 0x8071
    
    public var parameters: Data? {
        return Data([
            sarSegmentsThreshold | (sarAcknowledgmentDelayIncrement << 5),
            sarDiscardTimeout | (sarReceiverSegmentIntervalStep << 4),
            sarAcknowledgmentRetransmissionsCount // | (RFU << 2)
        ])
    }
    
    // MARK: - SAR Receiver states
    
    /// The **SAR Discard Timeout state** is a 4-bit value that controls the time that the
    /// Lower Transport layer waits after receiving unique segments of a segmented
    /// message before discarding that segmented message.
    ///
    /// The default value of the **SAR Discard Timeout state** is `0b0001` (10 seconds).
    ///
    /// The Discard Timeout initial value is set using the following formula:
    /// ```
    /// (SAR Discard Timeout + 1) * 5 ms
    /// ```
    ///
    /// - seeAlso:``discardTimeout``
    public let sarDiscardTimeout: UInt8
    
    /// The **SAR Acknowledgment Delay Increment state** is a 3-bit value that controls
    /// the interval between the reception of a new segment of a segmented message
    /// for a destination that is a Unicast Address and the transmission of the
    /// Segment Acknowledgment for that message.
    ///
    /// The default value of the **SAR Acknowledgment Delay Increment state** is `0b001`
    /// (2.5 segment transmission interval steps).
    ///
    /// - seeAlso:``sarReceiverSegmentIntervalStep``
    public let sarAcknowledgmentDelayIncrement: UInt8
    
    /// The **SAR Receiver Segment Interval Step state** is a 4-bit value that indicates
    /// the interval between received segments of a segmented message.
    /// This is used to control rate of transmission of Segment Acknowledgment messages.
    ///
    /// The default value of the **SAR Receiver Segment Interval Step state** is `0b0101`
    /// (60 milliseconds).
    ///
    /// - seeAlso:``sarAcknowledgmentDelayIncrement``
    public let sarReceiverSegmentIntervalStep: UInt8
    
    /// The **SAR Segments Threshold state** is a 5-bit value that represents
    /// the size of a segmented message in number of segments above which the
    /// retransmissions of Segment Acknowledgment messages are enabled.
    ///
    /// Example: When a message is composed of 4 segments retransmissions of
    /// Segment Acknowledgment messages is enabled if the **SAR Segments
    /// Threshold state** is set to 3 or less.
    ///
    /// - note: Retransmissions of Segment Acknowledgment messages is always
    ///         disabled for single-segment segmented messages as they are complete
    ///         after receiving just one segment. The value of 0 and 1 are then
    ///         equivalent, as the shortest message for which Ack retransmissions
    ///         are enabled is 2 segments.
    ///
    /// The default value for the **SAR Segments Threshold state** is `0b00011` (3 segments).
    ///
    /// - seeAlso: ``sarAcknowledgmentRetransmissionsCount``
    public let sarSegmentsThreshold: UInt8
    
    /// The **SAR Acknowledgment Retransmissions Count** state is a 2-bit value
    /// that controls the number of retransmissions of Segment Acknowledgment messages
    /// sent by the lower transport layer.
    ///
    /// Retransmission of Segment Acknowledgment messages is only enabled for messages
    /// composed of more segments then the value of ``sarSegmentsThreshold``.
    ///
    /// The maximum number of transmissions of a Segment Acknowledgment message is
    /// ```
    /// SAR Acknowledgment Retransmissions Count + 1
    /// ```
    /// For example, `0b00` represents a limit of 1 transmission, and `0b11` represents a limit of 4 transmissions.
    ///
    /// The default value of the **SAR Acknowledgment Retransmissions Count state** is `0b00`
    /// (1 transmission, retransmissions disabled).
    ///
    /// - note: Retransmission of Segment Acknowledgent messages is controlled by
    ///         ``sarSegmentsThreshold``.
    ///
    /// - seeAlso: ``sarSegmentsThreshold``
    public let sarAcknowledgmentRetransmissionsCount: UInt8
    
    // MARK: - Initializers
    
    /// Creates a ``SarReceiverStatus`` message.
    ///
    /// - parameters:
    ///   - sarSegmentsThreshold: See ``sarSegmentsThreshold``.
    ///   - sarAcknowledgmentDelayIncrement: See ``sarAcknowledgmentDelayIncrement``.
    ///   - sarDiscardTimeout: See ``sarDiscardTimeout``.
    ///   - sarReceiverSegmentIntervalStep: See ``sarReceiverSegmentIntervalStep``.
    ///   - sarAcknowledgmentRetransmissionsCount: See ``sarAcknowledgmentRetransmissionsCount``.
    public init(
        sarSegmentsThreshold: UInt8,
        sarAcknowledgmentDelayIncrement: UInt8,
        sarDiscardTimeout: UInt8,
        sarReceiverSegmentIntervalStep: UInt8,
        sarAcknowledgmentRetransmissionsCount: UInt8
    ) {
        self.sarSegmentsThreshold = sarSegmentsThreshold
        self.sarAcknowledgmentDelayIncrement = sarAcknowledgmentDelayIncrement
        self.sarDiscardTimeout = sarDiscardTimeout
        self.sarReceiverSegmentIntervalStep = sarReceiverSegmentIntervalStep
        self.sarAcknowledgmentRetransmissionsCount = sarAcknowledgmentRetransmissionsCount
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 3 else {
            return nil
        }
        sarSegmentsThreshold = parameters[0] & 0x1F
        sarAcknowledgmentDelayIncrement = (parameters[0] >> 5) & 0x07
        sarDiscardTimeout = parameters[1] & 0x0F
        sarReceiverSegmentIntervalStep = (parameters[1] >> 4) & 0x0F
        sarAcknowledgmentRetransmissionsCount = parameters[2] & 0x03
        // 6 remaining bits are RFU
    }
}
