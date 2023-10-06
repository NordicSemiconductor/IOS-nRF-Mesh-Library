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

/// A set of network parameters that can be applied to the ``MeshNetworkManager``.
///
/// Network parameters configure the transsmition and retranssmition intervals,
/// acknowledge message timeout, the default Time To Live (TTL) and other.
///
/// Use ``NetworkParameters/default`` or ``NetworkParameters/custom(_:)`` to create
/// an instance of this structure.
///
/// - since: 4.0.0
public struct NetworkParameters {
    /// A builder type for ``NetworkParameters``.
    ///
    /// Parameters can be set one-by-one, or using a builder:
    /// ```swift
    /// meshNetworkManager.networkParameters = .custom { builder in
    ///     // Setting default Time To Live.
    ///     builder.defaultTtl = ...
    ///     // Setting a timeout to discard a partially received segmented message
    ///     // if no new segments were received.
    ///     builder.discardTimeout = ...
    ///     // Adjusting the rate of sending Segment Acknowledgment messages.
    ///     builder.setAcknowledgmentTimerInterval(..., andMinimumDelayIncrement: ...)
    ///     // Setting up Segment Acknowledgment retransmission.
    ///     builder.retranssmitSegmentAcknowledgmentMessages(..., timesWhenNumberOfSegmentsIsGreaterThan: ...)
    ///     builder.transmissionTimerInterval = ...
    ///     builder.retransmissionLimit = ...
    ///     builder.acknowledgmentMessageTimeout = ...
    ///     builder.acknowledgmentMessageInterval = ...
    ///     // If you know what you're doing, customize the advanced parameters.
    ///     builder.allowIvIndexRecoveryOver42 = ...
    ///     builder.ivUpdateTestMode = ...
    /// }
    /// ```
    ///
    /// If not modified, ``NetworkParameters/default`` values are used.
    public typealias Builder = (inout NetworkParameters) -> ()
    
    // MARK: - TTL states
    private var _defaultTtl: UInt8 = 5
    
    // MARK: - SAR Receiver states
    private var _sarDiscardTimeout: UInt8 = 0b0001              // (n+1)*5 sec = 10 seconds
    private var _sarAcknowledgmentDelayIncrement: UInt8 = 0b001 // n+1.5 = 2.5
    private var _sarReceiverSegmentIntervalStep: UInt8 = 0b0101 // (n+1)*10 ms = 60 ms
    private var _sarSegmentsThreshold: UInt8 = 0b00011          // 3
    private var _sarAcknowledgmentRetransmissionsCount: UInt8 = 0b00 // 0
    
    // MARK: - SAR Transmitter states
    private var _sarSegmentIntervalStep: UInt8 = 0b0101         // (n+1)*10 ms = 60 ms
    private var _sarUnicastRetransmissionsCount: UInt8 = 0b0010 // 3
    private var _sarUnicastRetransmissionsWithoutProgressCount: UInt8 = 0b0010 // 3
    private var _sarUnicastRetransmissionsIntervalStep: UInt8 = 0b0111 // (n+1)*25 ms = 200 ms
    private var _sarUnicastRetransmissionsIntervalIncrement: UInt8 = 0b0001 // (n+1)*25 ms = 50 ms
    private var _sarMulticastRetransmissionsCount: UInt8 = 0b0010 // 3
    private var _sarMulticastRetransmissionsIntervalStep: UInt8 = 0b1001 // (n+1)*25 ms = 250 ms

    // MARK: - Acknowledge messages configuration states
    private var _acknowledgmentMessageTimeout: TimeInterval = 30.0
    private var _acknowledgmentMessageInterval: TimeInterval = 2.0
    
    // MARK: - TTL Configuration
    
    /// The Default TTL will be used for sending messages, if the value has
    /// not been set in the Provisioner's Node.
    ///
    /// By default it is set to 5, which is a reasonable value. The TTL shall be in range 2...127.
    ///
    /// In Bluetooth Mesh each message is sent with a given TTL value. When a relay
    /// Node receives such message it decrements the TTL value by 1, re-encrypts it
    /// using the same Network Key and retransmits further. If the received TTL value is
    /// 1 or 0 the message is no longer retransmitted.
    public var defaultTtl: UInt8 {
        get { return _defaultTtl }
        set { _defaultTtl = max(2, min(newValue, 127)) }
    }
    
    // MARK: - SAR Receiver state implementation
    
    /// The timeout after which an incomplete segmented message will be
    /// abandoned. The timer is restarted each time a segment of this
    /// message is received.
    ///
    /// The incomplete timeout should be set to at least 10 seconds.
    ///
    /// Mesh Protocol 1.1 replaced the Incomplete Message Timeout with
    /// a SAR Discard Timeout (``discardTimeout``).
    @available(*, deprecated, renamed: "discardTimeout")
    public var incompleteMessageTimeout: TimeInterval {
        get { return discardTimeout }
        set { discardTimeout = newValue }
    }
    
    /// The Discard Timeout is the time that the Lower Transport layer waits
    /// after receiving a new segment of a segmented message before
    /// discarding that segmented message.
    ///
    /// Valid range for this timeout is from 5 seconds to 1 minute and 20 seconds
    /// (80 seconds) with 5 second step. The default value is 10 seconds.
    ///
    /// The Discard Timeout is reset every time a new segment of a message
    /// is received.
    ///
    /// The value of this timeout is controlled by ``sarDiscardTimeout``
    /// state and is calculated the following way:
    /// ```
    /// (SAR Discard Timeout + 1) * 5 ms
    /// ```
    public var discardTimeout: TimeInterval {
        get { return TimeInterval(_sarDiscardTimeout + 1) * 5.0 }
        set { _sarDiscardTimeout = UInt8(min(5.0, newValue) / 5.0) - 1 }
    }
    
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
    public var sarDiscardTimeout: UInt8 {
        get { return _sarDiscardTimeout }
        set { _sarDiscardTimeout = min(newValue, 0b1111) } // Valid range: 0-15
    }
    
    /// This property used to control the time after which the lower transport
    /// layer sends a/ Segment Acknowledgment message after receiving a
    /// segment of a multi-segment message where the destination is the
    /// Unicast Address of one of the Provisioner's Elements
    ///
    /// In Bluetooth Mesh Profile 1.0.1 the inteval was dependent on Time To Live (TTL)
    /// and this property was used to adjust the constant part of the interval
    /// using the given formula:
    /// ```
    /// acknowledgment timer interval + (50 ms * TTL)
    /// ```
    /// The TTL dependent part was added automatically.
    ///
    /// - warning: In Bluetooth Mesh Protocol 1.1 this property was replace by
    ///            ``sarAcknowledgmentDelayIncrement`` and
    ///            ``sarReceiverSegmentIntervalStep`` which control
    ///            the interval using `segN` of a segmented message instead of `TTL`.
    ///            Setting this property does nothing.
    @available(*, deprecated, renamed: "setAcknowledgmentTimerInterval(_:andMinimumDelayIncrement:)")
    public var acknowledgmentTimerInterval: TimeInterval {
        get { return acknowledgmentTimerInterval(forLastSegmentNumber: 2) }
        set {
            // It is not possible to translate the old interval, which
            // depended on TTL value, to the new one, which is using number
            // of segments in a message.
        }
    }
    
    /// Sets the parameters for calculating the initial value fo SAR Acknowledgement timer.
    ///
    /// The initial value of SAR Acknowledgment timer is calculated with the following formula:
    /// ```
    /// min(SegN + 0.5, acknowledgment delay increment) * segment reception interval (ms)
    /// ```
    /// `SegN` field in a segmented message is the index of the last segment in a message,
    /// equal to the number of segments minus 1, therefore the formula can be also written as:
    /// ```
    /// min(number of segments - 0.5, acknowledgment delay increment) * segment reception interval (ms)
    /// ```
    ///
    /// - parameters:
    ///   - segmentReceptionInterval: The interval multipled by the number of segments in a
    ///                               message minus 0.5.
    ///                               Available values are in range 10 ms - 160 ms with 10 ms step.
    ///   - acknowledgmentDelayIncrement: The minimum delay increment. The value must be from
    ///                                   1.5 + n up to 8.5, that is 1.5, 2.5, 3.5, ... until 8.5.
    ///                                   Other values will be rounded down.
    public mutating func setAcknowledgmentTimerInterval(_ segmentReceptionInterval: TimeInterval,
                                                        andMinimumDelayIncrement acknowledgmentDelayIncrement: Double) {
        // Valid range: 10-160 ms
        _sarReceiverSegmentIntervalStep = UInt8((max(0.01, min(0.16, segmentReceptionInterval)) * 100) - 1)
        // Valid range: 1.5-8.5 segment transmission interval steps
        _sarAcknowledgmentDelayIncrement = UInt8(max(0, max(1.5, min(8.5, acknowledgmentDelayIncrement)) - 1.5))
    }
    
    /// The **SAR Acknowledgment Delay Increment state** is a 3-bit value that controls
    /// the interval between the reception of a new segment of a segmented message
    /// for a destination that is a Unicast Address and the transmission of the
    /// Segment Acknowledgment for that message.
    ///
    /// The default value of the **SAR Acknowledgment Delay Increment state** is `0b001`
    /// (2.5 segment transmission interval steps).
    ///
    /// - seeAlso:``sarReceiverSegmentIntervalStep``
    public var sarAcknowledgmentDelayIncrement: UInt8 {
        get { return _sarAcknowledgmentDelayIncrement }
        set { _sarAcknowledgmentDelayIncrement = min(newValue, 0b111) } // Valid range: 0-7
    }
    
    /// The **SAR Receiver Segment Interval Step state** is a 4-bit value that indicates
    /// the interval between received segments of a segmented message.
    /// This is used to control rate of transmission of Segment Acknowledgment messages.
    ///
    /// The default value of the **SAR Receiver Segment Interval Step state** is `0b0101`
    /// (60 milliseconds).
    ///
    /// - seeAlso:``sarAcknowledgmentDelayIncrement``
    public var sarReceiverSegmentIntervalStep: UInt8 {
        get { return _sarReceiverSegmentIntervalStep }
        set { _sarReceiverSegmentIntervalStep = min(newValue, 0b1111) } // Valid range: 0-15
    }
    
    /// A value indicated by the **SAR Acknowledgment Delay Increment state**.
    ///
    /// - seeAlso ``sarAcknowledgmentDelayIncrement``
    /// - seeAlso ``setAcknowledgmentTimerInterval(_:andMinimumDelayIncrement:)``
    public var acknowledgmentDelayIncrement: Double {
        get { return Double(_sarAcknowledgmentDelayIncrement) + 1.5 }
        set { _sarAcknowledgmentDelayIncrement = UInt8(max(0, max(1.5, min(8.5, newValue)) - 1.5)) }
    }
    
    /// A value indicated by the **SAR Receiver Segment Interval Step state**.
    ///
    /// - seeAlso ``sarReceiverSegmentIntervalStep``
    /// - seeAlso ``setAcknowledgmentTimerInterval(_:andMinimumDelayIncrement:)``
    public var segmentReceptionInterval: TimeInterval {
        get { return Double(_sarReceiverSegmentIntervalStep + 1) * 0.01 }
        set { _sarReceiverSegmentIntervalStep = UInt8(min(0.16, max(newValue, 0.01)) * 100) - 1 }
    }
    
    /// The initial value of the SAR Acknowledgment timer for a given `segN`.
    ///
    /// The value depends on the number of segments in a segmented message.
    ///
    /// The initial value of the SAR Acknowledgment timer is calculated using the following
    /// formula:
    /// ```
    /// min(SegN + 0.5 , acknowledgment delay increment) * segment reception interval (ms)
    /// ```
    /// where
    /// ```
    /// acknowledgment delay increment = SAR Acknowledgment Delay Increment + 1.5
    ///
    /// segment reception interval = (SAR Receiver Segment Interval Step + 1) × 10 ms
    /// ```
    internal func acknowledgmentTimerInterval(forLastSegmentNumber segN: UInt8) -> TimeInterval {
        return min(Double(segN) + 0.5, acknowledgmentDelayIncrement) * segmentReceptionInterval
    }
    
    /// The initial value of the timer ensuring that no more than one Segment Acknowledgment message
    /// is sent for the same SeqAuth value in a period of:
    /// ```
    /// acknowledgment delay increment * segment reception interval (ms)
    /// ```
    internal var completeAcknowledgmentTimerInterval: TimeInterval {
        return acknowledgmentDelayIncrement * segmentReceptionInterval
    }
    
    /// Sets the parameters controlling retransmission of Segment Acknowledgment messages
    /// for incomplete messages.
    ///
    /// When a Receiver receives a segment of asegmented message composed of 2 ro more
    /// segments it starts the SAR Acknowledgment timer. The initial value of this timer
    /// is controller by ``setAcknowledgmentTimerInterval(_:andMinimumDelayIncrement:)``
    /// and depends on the number of segments. When this timer expires and no new segment
    /// was received a Segment Acknowledgment message is sent to the Transmitter indicating
    /// which segments were received until that point. When the number of segments of the message
    /// is greater than the `threshold` and the `count` parameter is greater than 0 the
    /// Segment Acknowledgment message is retransmitted `count` times.
    ///
    /// By default retransmissions of Segment Acknowledgment messages are disabled.
    ///
    /// - parameters:
    ///   - count: Number of retransmissions of Segment Acknowledgment.
    ///            Valid values are 0-3, where 0 disables retransmissions.
    ///   - threshold: The number of segments above which the retransmissions of
    ///                Segment Acknowledgment messages are enabled.
    /// - seeAlso: ``sarSegmentsThreshold``
    /// - seeAlso: ``sarAcknowledgmentRetransmissionsCount``
    public mutating func retranssmitSegmentAcknowledgmentMessages(
        _ count: UInt8,
        timesWhenNumberOfSegmentsIsGreaterThan threshold: UInt8) {
        sarSegmentsThreshold = threshold
        sarAcknowledgmentRetransmissionsCount = count
    }
    
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
    /// - seeAlso: ``retranssmitSegmentAcknowledgmentMessages(_:timesWhenNumberOfSegmentsIsGreaterThan:)``
    public var sarSegmentsThreshold: UInt8 {
        get { return _sarSegmentsThreshold }
        set { _sarSegmentsThreshold = min(newValue, 0b11111) } // Valid range: 0-31
    }
    
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
    /// - seeAlso: ``retranssmitSegmentAcknowledgmentMessages(_:timesWhenNumberOfSegmentsIsGreaterThan:)``
    public var sarAcknowledgmentRetransmissionsCount: UInt8 {
        get { return _sarAcknowledgmentRetransmissionsCount }
        set { _sarAcknowledgmentRetransmissionsCount = min(newValue, 0b11) } // Valid range: 0-3
    }
    
    // MARK: - SAR Transmitter state implementation
    
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
    public var sarSegmentIntervalStep: UInt8 {
        get { return _sarSegmentIntervalStep }
        set { _sarSegmentIntervalStep = min(newValue, 0b1111) } // Valid range: 0-15
    }
    
    /// The interval between transmissions of segments of a segmented message.
    ///
    /// The value ot this interval is indicated by **SAR Segment Interval Step state**.
    ///
    /// - seeAlso: ``sarSegmentIntervalStep``
    public var segmentTransmissionInterval: TimeInterval {
        get { return Double(_sarSegmentIntervalStep + 1) * 0.01 }
        set { _sarSegmentIntervalStep = UInt8(min(0.16, max(newValue, 0.01)) * 100) - 1 }
    }
    
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
    public var sarUnicastRetransmissionsCount: UInt8 {
        get { return _sarUnicastRetransmissionsCount }
        set { _sarUnicastRetransmissionsCount = min(newValue, 0b1111) } // Valid range: 0-15
    }
    
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
    public var sarUnicastRetransmissionsWithoutProgressCount: UInt8 {
        get { return _sarUnicastRetransmissionsWithoutProgressCount }
        set { _sarUnicastRetransmissionsWithoutProgressCount = min(newValue, 0b1111) } // Valid range: 0-15
    }
    
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
    public var sarUnicastRetransmissionsIntervalStep: UInt8 {
        get { return _sarUnicastRetransmissionsIntervalStep }
        set { _sarUnicastRetransmissionsIntervalStep = min(newValue, 0b1111) } // Valid range: 0-15
    }
    
    /// The interval between retransmissions of segments of a segmented
    /// message for a destination that is a Unicast Address.
    ///
    /// Valid range is from 25 ms to 400 ms with 25 ms interval.
    /// - seeAlso: ``sarUnicastRetransmissionsIntervalStep``
    public var unicastRetransmissionsIntervalStep: TimeInterval {
        get { return Double(_sarUnicastRetransmissionsIntervalStep + 1) * 0.025 }
        set { _sarUnicastRetransmissionsIntervalStep = UInt8(min(0.4, max(newValue, 0.025)) * 40) - 1 }
    }
    
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
    public var sarUnicastRetransmissionsIntervalIncrement: UInt8 {
        get { return _sarUnicastRetransmissionsIntervalIncrement }
        set { _sarUnicastRetransmissionsIntervalIncrement = min(newValue, 0b1111) } // Valid range: 0-15
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
        get { return Double(_sarUnicastRetransmissionsIntervalIncrement + 1) * 0.025 }
        set { _sarUnicastRetransmissionsIntervalIncrement = UInt8(min(0.4, max(newValue, 0.025)) * 40) - 1 }
    }
    
    /// The initial value of the SAR Unicast Retransmissions timer.
    ///
    /// - parameter ttl: The TTL value with the message is being sent.
    /// - returns: The initial value of the SAR Unicast Retransmissions timer.
    internal func unicastRetransmissionsInterval(for ttl: UInt8) -> TimeInterval {
        // If the value of the TTL field of the message is 0, the initial value
        // of the timer shall be set to the unicast retransmissions interval step.
        if ttl == 0 {
            return unicastRetransmissionsIntervalStep
        }
        return unicastRetransmissionsIntervalStep + unicastRetransmissionsIntervalIncrement * Double(ttl - 1)
    }
    
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
    public var sarMulticastRetransmissionsCount: UInt8 {
        get { return _sarMulticastRetransmissionsCount }
        set { _sarMulticastRetransmissionsCount = min(newValue, 0b1111) } // Valid range: 0-15
    }
    
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
    public var sarMulticastRetransmissionsIntervalStep: UInt8 {
        get { return _sarMulticastRetransmissionsIntervalStep }
        set { _sarMulticastRetransmissionsIntervalStep = min(newValue, 0b1111) } // Valid range: 0-15
    }
    
    /// The interval between retransmissions of segments of a segmented message for
    /// a destination that is a Group Address or a Virtual Address.
    ///
    /// Valid range is from 25 ms to 400 ms with 25 ms interval.
    ///
    /// - seeAlso: ``sarMulticastRetransmissionsIntervalStep``
    public var multicastRetransmissionsInterval: TimeInterval {
        get { return Double(_sarMulticastRetransmissionsIntervalStep + 1) * 0.025 }
        set { _sarMulticastRetransmissionsIntervalStep = UInt8(min(0.4, max(newValue, 0.025)) * 40) - 1 }
    }
    
    /// This property used to control the time within which a Segment Acknowledgment
    /// message was expected to be received after a segment of a segmented message has
    /// been sent.
    ///
    /// When the timer was fired, the non-acknowledged segments were repeated, at most
    /// ``retransmissionLimit`` times.
    ///
    /// Bluetooth Mesh Protocol 1.1 replaces the property with two states:
    /// * **SAR Unicast Retransmissions Interval Step**
    /// * **SAR Unicast Retransmissions Interval Increment**
    ///
    /// which control both the fixed part, and the part depending on the TTL value.
    ///
    /// - note: For segmented messages targeting a Group or Virtual Address, the value
    ///         used to be fixed to 2, and now can be controller with **SAR Multicast
    ///         Retransmissions Interval Step**.
    /// - seeAlso: ``sarUnicastRetransmissionsIntervalStep``
    /// - seeAlso: ``sarUnicastRetransmissionsIntervalIncrement``
    /// - seeAlso: ``sarMulticastRetransmissionsIntervalStep``
    @available(*, deprecated, renamed: "unicastRetransmissionsIntervalStep")
    public var transmissionTimerInterval: TimeInterval {
        get { return unicastRetransmissionsIntervalStep }
        set { _sarUnicastRetransmissionsIntervalStep = UInt8(min(0.4, max(newValue, 0.025)) * 40) - 1 }
    }
    
    /// This property used to control the number of times a non-acknowledged segment
    /// of a segmented message was retransmitted before the message has been cancelled.
    ///
    /// In Bluetooth Mesh Protocol 1.1 it has been replaced with two states:
    /// * **SAR Unicast Retransmissions Count**
    /// * **SAR Unicast Retransmissions Without Progress Count**
    ///
    /// - note: For a multicast transfer (to a Group or Virtual Address) the retransmission
    ///         limit was fixed to 2. Now it can be controlled with
    ///         ``sarMulticastRetransmissionsCount``.
    ///
    /// - seeAlso: ``sarUnicastRetransmissionsCount``
    /// - seeAlso: ``sarUnicastRetransmissionsWithoutProgressCount``
    /// - seeAlso: ``sarMulticastRetransmissionsCount``
    @available(*, deprecated, renamed: "sarUnicastRetransmissionsCount")
    public var retransmissionLimit: Int {
        get { return Int(_sarUnicastRetransmissionsCount) }
        set { _sarUnicastRetransmissionsCount = UInt8(max(0b1111, min(newValue - 1, 0))) }
    }
    
    // MARK: - Acknowledged messages configuration implementation
    
    /// If the Element does not receive a response within a period of time known
    /// as the acknowledged message timeout, then the Element may consider the
    /// message has not been delivered, without sending any additional messages.
    ///
    /// The ``MeshNetworkDelegate/meshNetworkManager(_:failedToSendMessage:from:to:error:)-7iylf``
    /// callback will be called on timeout.
    ///
    /// The acknowledged message timeout should be set to a minimum of 30 seconds.
    public var acknowledgmentMessageTimeout: TimeInterval {
        get { return _acknowledgmentMessageTimeout }
        set { _acknowledgmentMessageTimeout = max(30.0, newValue) }
    }
    
    /// The base time after which the acknowledged message will be repeated.
    ///
    /// The repeat timer will be set using the following formula:
    /// ```
    /// acknowledgment message interval + 50 ms * TTL + 50 ms * number of segments
    /// ```
    /// The TTL and segment count dependent parts are added
    /// automatically, and this value shall specify only the constant part.
    public var acknowledgmentMessageInterval: TimeInterval {
        get { return _acknowledgmentMessageInterval }
        set { _acknowledgmentMessageInterval = max(2.0, newValue) }
    }
    
    internal func acknowledgmentMessageInterval(forTtl ttl: UInt8, andSegmentCount segmentCount: Int) -> TimeInterval {
        return _acknowledgmentMessageInterval + Double(ttl) * 0.050 + Double(segmentCount) * 0.050
    }
    
    // MARK: - Advanced configuration
    
    /// According to Bluetooth Mesh Profile 1.0.1, section 3.10.5, if the IV Index
    /// of the mesh network increased by more than 42 since the last connection
    /// (which can take at least 48 weeks), the Node should be re-provisioned.
    /// However, as this library can be used to provision other Nodes, it should not
    /// be blocked from sending messages to the network only because the phone wasn't
    /// connected to the network for that time. This flag can disable this check,
    /// effectively allowing such connection.
    ///
    /// The same can be achieved by clearing the app data (uninstalling and reinstalling
    /// the app) and importing the mesh network. With no "previous" IV Index, the
    /// library will accept any IV Index received in the Secure Network beacon upon
    /// connection to the GATT Proxy Node.
    public var allowIvIndexRecoveryOver42: Bool = false
    
    /// IV Update Test Mode enables efficient testing of the IV Update procedure.
    /// The IV Update test mode removes the 96-hour limit; all other behavior of the device
    /// are unchanged.
    ///
    /// - seeAlso: Bluetooth Mesh Profile 1.0.1, section 3.10.5.1.
    public var ivUpdateTestMode: Bool = false
    
    // MARK: - Initializers
    
    /// A builder for custom configuration.
    ///
    /// - parameter with: The configuration builder.
    /// - returns: The built network parameters object.
    public static func custom(_ builder: Builder) -> NetworkParameters {
        var provider = NetworkParameters()
        builder(&provider)
        return provider
    }
    
    /// A set of default network parameters.
    public static let `default` = NetworkParameters()
        
    private init() {
        // Private constructor.
    }
}

/// The network parameters provider.
public protocol NetworkParametersProvider: AnyObject {
    
    /// Network parameters.
    var networkParameters: NetworkParameters { get }
    
}
