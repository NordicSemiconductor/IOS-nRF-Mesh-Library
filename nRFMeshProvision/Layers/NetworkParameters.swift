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
/// Network parameters configure the transmission and retransmission intervals,
/// acknowledge message timeout, the default Time To Live (TTL) and other.
///
/// Use one of the following builders to create an instance of this structure:
/// - ``NetworkParameters/default`` - the default configuration
/// - ``NetworkParameters/basic(_:)`` - using verbose builder
/// - ``NetworkParameters/advanced(_:)`` - for advanced users
///
/// - since: 4.0.0
public struct NetworkParameters {
    
    /// The builder allows easy configuration of ``NetworkParameters``.
    public class Config {
        private var networkParameters: NetworkParameters = .default
        
        // MARK: - TTL Configuration
        
        /// Sets the default Time To Live (TTL) which will be used for sending messages if the value has
        /// not been set for the Provisioner's Node.
        ///
        /// In Bluetooth Mesh each message is sent with a TTL value. When a relay
        /// Node receives such message, it decrements the TTL value by 1, re-encrypts it
        /// using the same Network Key and retransmits further. If the received TTL value is
        /// 1 or 0 the message is no longer retransmitted.
        ///
        /// By default default TTL is set to 5, which is a reasonable value. The TTL shall be in range 2...127.
        ///
        /// - seeAlso: ``NetworkParameters/defaultTtl``
        public func setDefaultTtl(_ ttl: UInt8) {
            networkParameters.defaultTtl = ttl
        }
        
        // MARK: - SAR Received Configuration
        
        /// Sets the time after which an incomplete segmented message is discarded when no new segment
        /// is received. The timer is restarted each time a new segment is received.
        ///
        /// - parameter timeout: The time since last received segment, after which segmented
        ///                      message is discarded.
        ///                      Valid range for the timeout is from 5 seconds to 1 minute and 20 seconds
        ///                      (80 seconds) with 5 second step. Default value is 10 seconds.
        /// - seeAlso: ``NetworkParameters/sarDiscardTimeout``
        public func discardIncompleteSegmentedMessages(after timeout: TimeInterval) {
            networkParameters.sarDiscardTimeout = UInt8(min(5.0, timeout) / 5.0) - 1
        }
        
        /// Sets the parameters for calculating the interval between receiving a new segment of a segmented
        /// message for a destination that is a Unicast Address and sending a Segment Acknowledgment message.
        ///
        /// The Segment Acknowledgment message contains information about which segments have been
        /// received until the moment of sending the message. Upon receiving, the transmitter should retransmit
        /// all missing segments.
        ///
        /// The initial value of the timer for a given message depends on number of segments and is calculated
        /// using the following formula:
        /// ```
        /// min(number of segment - 0.5, acknowledgment delay increment) * segment reception interval (ms)
        /// ```
        ///
        /// Number of retransmissions of the Segment Acknowledgment message can be set using
        /// ``retransmitSegmentAcknowledgmentMessages(exactly:timesWhenNumberOfSegmentsIsGreaterThan:)``.
        ///
        /// - parameters:
        ///   - segmentReceptionInterval: A value that indicates the interval between received segments
        ///                               of a segmented message.
        ///                               Available values are in range 10 ms - 160 ms with 10 ms step
        ///                               with default value 60 ms.
        ///   - acknowledgmentDelayIncrement: The minimum delay increment is a value that controls the
        ///                                   interval between the reception of a new segment of a
        ///                                   segmented message for a destination that is a Unicast Address
        ///                                   and the transmission of the Segment Acknowledgment for
        ///                                   that message.
        ///                                   Valid values are 1.5, 2.5, ... until 8.5 with the default value being 1.5.
        /// - seeAlso: ``NetworkParameters/sarReceiverSegmentIntervalStep``
        /// - seeAlso: ``NetworkParameters/sarAcknowledgmentDelayIncrement``
        public func transmitSegmentAcknowledgmentMessage(
                usingSegmentReceptionInterval segmentReceptionInterval: TimeInterval,
                multipliedByMinimumDelayIncrement acknowledgmentDelayIncrement: Double) {
            // Valid range: 10-160 ms
            networkParameters.sarReceiverSegmentIntervalStep = UInt8((max(0.01, min(0.16, segmentReceptionInterval)) * 100) - 1)
            // Valid range: 1.5-8.5 segment transmission interval steps
            networkParameters.sarAcknowledgmentDelayIncrement = UInt8(max(0, max(1.5, min(8.5, acknowledgmentDelayIncrement)) - 1.5))
        }
        
        /// Sets the parameters controlling retransmission of Segment Acknowledgment messages
        /// for incomplete messages.
        ///
        /// When a receiver receives a segment of a segmented message composed of 2 or more
        /// segments it starts the SAR Acknowledgment timer. The initial value of this timer
        /// is controller by ``transmitSegmentAcknowledgmentMessage(usingSegmentReceptionInterval:multipliedByMinimumDelayIncrement:)``
        /// and depends on the number of segments. Each time a new segment is received, the timer
        /// is restarted. When the timer expires, a Segment Acknowledgment message is sent to the
        /// transmitter indicating which segments were received until that point.
        ///
        /// When the number of segments of the message is greater than the `threshold` and
        /// the `count` parameter is greater than 0 the Segment Acknowledgment message is
        /// retransmitted `count` times.
        ///
        /// By default retransmissions of Segment Acknowledgment messages are disabled.
        ///
        /// - parameters:
        ///   - count: Number of retransmissions of Segment Acknowledgment.
        ///            Valid values are 0-3, where 0 disables retransmissions.
        ///            By default retransmissions are disabled.
        ///   - threshold: The number of segments above which the retransmissions of
        ///                Segment Acknowledgment messages are enabled.
        ///                By default, the threshold is set to 3 segments.
        /// - seeAlso: ``NetworkParameters/sarAcknowledgmentRetransmissionsCount``
        /// - seeAlso: ``NetworkParameters/sarSegmentsThreshold``
        public func retransmitSegmentAcknowledgmentMessages(exactly count: UInt8,
                timesWhenNumberOfSegmentsIsGreaterThan threshold: UInt8) {
            networkParameters.sarAcknowledgmentRetransmissionsCount = count
            networkParameters.sarSegmentsThreshold = threshold
        }
        
        // MARK: - SAR Transmitter Configuration
        
        /// Sets the interval between transmissions of segments of a segmented message.
        ///
        /// - parameter interval: The interval in seconds, in range 10 - 160 ms with 10 ms step.
        ///                       The default interval is 60 ms.
        /// - seeAlso: ``NetworkParameters/sarSegmentIntervalStep``
        public func transmitSegments(withInterval interval: TimeInterval) {
            networkParameters.sarSegmentIntervalStep = UInt8(max(0.01, interval) / 0.01) - 1
        }
        
        /// Sets the parameters of retransmissions of segments of a segmented message
        /// for a destination that is a Unicast Address.
        /// 
        /// The number of retransmissions and number of retransmissions without progress  indicate the
        /// maximum number of retransmissions before sending the message is cancelled.
        /// The count without progress is reset each time a Segment Acknowledgment message indicating
        /// a progress in transfer is received.
        ///
        /// The `interval` and `increment`define the interval between retransmissions in case no
        /// Segment Acknowledgment message is received. When an acknowledgment is received, the
        /// missing segments are transmitted immediately.
        ///
        /// The `interval` indicates the fixed interval added to a product of the `increment` and a value
        /// calculated using the formula: `TTL - 1`, where the TTL is the Time To Live value with which the
        /// message is sent.
        ///
        /// - parameters:
        ///   - retransmissionsCount: Maximum number of retransmissions of segments of a segmented 
        ///            message. Default value is 2 retransmissions (3 transmissions, including the initial one).
        ///   - retransmissionsWithoutProgressCount: Maximum number of retransmissions of segments
        ///            of a segmented message in case no new segments were acknowledged.
        ///            Default value is 2 retransmissions (3 transmissions, including the initial one).
        ///   - interval: The constant component of the interval between retransmissions.
        ///               Default interval is 200 ms. Valid range is from 25 ms to 400 ms with 25 ms interval.
        ///   - increment: The increment component the the interval, which is multiplied by `TTL - 1`.
        ///                Default increment is 50 ms. Valid range is from 25 ms to 400 ms with 25 ms interval.
        /// - seeAlso: ``NetworkParameters/sarUnicastRetransmissionsCount``
        /// - seeAlso: ``NetworkParameters/sarUnicastRetransmissionsWithoutProgressCount``
        /// - seeAlso: ``NetworkParameters/sarUnicastRetransmissionsIntervalStep``
        /// - seeAlso: ``NetworkParameters/sarUnicastRetransmissionsIntervalIncrement``
        public func retransmitUnacknowledgedSegmentsToUnicastAddress(
                atMost retransmissionsCount: UInt8,
                timesAndWithoutProgress retransmissionsWithoutProgressCount: UInt8,
                timesWithRetransmissionInterval interval: TimeInterval, andIncrement increment: TimeInterval) {
            networkParameters.sarUnicastRetransmissionsCount = retransmissionsCount
            networkParameters.sarUnicastRetransmissionsWithoutProgressCount = retransmissionsWithoutProgressCount
            networkParameters.sarUnicastRetransmissionsIntervalStep = UInt8(min(0.4, max(interval, 0.025)) * 40) - 1
            networkParameters.sarUnicastRetransmissionsIntervalIncrement = UInt8(min(0.4, max(increment, 0.025)) * 40) - 1
        }
        
        /// Sets number and interval of retransmissions of segments of a segmented message for
        /// a destination that is a Group Address or a Virtual Address.
        ///
        /// - parameters:
        ///   - total: Number of retransmissions of segments of a segmented message
        ///            for a multicast destination. The default value is 3.
        ///   - interval: The interval between retransmissions of segments.
        ///               The default interval is 250 ms.
        /// - seeAlso: ``NetworkParameters/sarMulticastRetransmissionsCount``
        /// - seeAlso: ``NetworkParameters/sarMulticastRetransmissionsIntervalStep``
        public func retransmitAllSegmentsToGroupAddress(
                exactly total: Int, timesWithInterval interval: TimeInterval) {
            networkParameters.sarMulticastRetransmissionsCount = UInt8(total)
            networkParameters.sarMulticastRetransmissionsIntervalStep = UInt8(min(0.4, max(interval, 0.025)) * 40) - 1
        }
        
        // MARK: - Access Layer
        
        /// Sets the timeout for receiving a response to an acknowledged access message.
        ///
        /// The ``MeshNetworkDelegate/meshNetworkManager(_:failedToSendMessage:from:to:error:)-7iylf``
        /// callback will be called when the response is not received before the timeout expires..
        ///
        /// - parameter timeout: The timeout after which the ``AccessError/timeout``
        ///                      is reported. This shall be set to a minimum of 30 seconds,
        ///                      which is also the default value.
        /// - seeAlso: ``NetworkParameters/acknowledgmentMessageTimeout``
        public func discardAcknowledgedMessages(after timeout: TimeInterval) {
            networkParameters.acknowledgmentMessageTimeout = timeout
        }
        
        /// Sets the base time after which the acknowledged message is repeated.
        ///
        /// The repeat timer will be set using the following formula:
        /// ```
        /// acknowledgment message interval + 50 ms * TTL + 50 ms * number of segments
        /// ```
        /// TTL and the component dependent on number of segments are added
        /// automatically. This method adjusts only the constant component.
        ///
        /// The interval is doubled each time the request is retransmitted until the
        /// response is received or the timeout set using ``discardAcknowledgedMessages(after:)``
        /// expires.
        /// - seeAlso: ``NetworkParameters/acknowledgmentMessageInterval``
        public func retransmitAcknowledgedMessage(after interval: TimeInterval) {
            networkParameters.acknowledgmentMessageInterval = interval
        }
        
        /// Builds the ``NetworkParameters`` structure.
        fileprivate func build() -> NetworkParameters {
            return networkParameters
        }
    }
    
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
    
    /// The default value of Time To Live (TTL), which is used for sending messages if the
    /// value is not set for the Provisioner's Node.
    ///
    /// In Bluetooth Mesh each message is sent with a given TTL value. When a relay
    /// Node receives such message it decrements the TTL value by 1, re-encrypts it
    /// using the same Network Key and retransmits further. If the received TTL value is
    /// 1 or 0 the message is no longer retransmitted.
    ///
    /// By default TTL is set to 5, which is a reasonable value. The TTL shall be in range 2...127.
    public var defaultTtl: UInt8 {
        get { return _defaultTtl }
        set { _defaultTtl = max(2, min(newValue, 127)) }
    }
    
    // MARK: - SAR Receiver state implementation
    
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
    public var sarDiscardTimeout: UInt8 {
        get { return _sarDiscardTimeout }
        set { _sarDiscardTimeout = min(newValue, 0b1111) } // Valid range: 0-15
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
    /// - note: Retransmission of Segment Acknowledgment messages is controlled by
    ///         ``sarSegmentsThreshold``.
    ///
    /// - seeAlso: ``sarSegmentsThreshold``
    public var sarAcknowledgmentRetransmissionsCount: UInt8 {
        get { return _sarAcknowledgmentRetransmissionsCount }
        set { _sarAcknowledgmentRetransmissionsCount = min(newValue, 0b11) } // Valid range: 0-3
    }
    
    // MARK: - SAR Transmitter state implementation
    
    /// The **SAR Segment Interval Step state** is a 4-bit value that controls
    /// the interval between transmissions of segments of a segmented message.
    ///
    /// The segment transmission interval is the number of milliseconds calculated
    /// using the following formula:
    /// ```
    /// (SAR Segment Interval Step + 1) * 10 ms
    /// ```
    /// The default value of the **SAR Segment Interval Step state** is `0b0101`
    /// (60 milliseconds).
    public var sarSegmentIntervalStep: UInt8 {
        get { return _sarSegmentIntervalStep }
        set { _sarSegmentIntervalStep = min(newValue, 0b1111) } // Valid range: 0-15
    }
    
    /// The **SAR Unicast Retransmissions Count state** is a 4-bit value that
    /// controls the maximum number of transmissions of segments of segmented
    /// messages to a Unicast Address destination.
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
    ///
    /// - seeAlso: ``sarUnicastRetransmissionsWithoutProgressCount``
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
    ///
    /// - seeAlso: ``sarUnicastRetransmissionsCount``
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
    /// - seeAlso: ``sarUnicastRetransmissionsIntervalIncrement``
    public var sarUnicastRetransmissionsIntervalStep: UInt8 {
        get { return _sarUnicastRetransmissionsIntervalStep }
        set { _sarUnicastRetransmissionsIntervalStep = min(newValue, 0b1111) } // Valid range: 0-15
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
    ///
    /// - seeAlso: ``sarUnicastRetransmissionsIntervalStep``
    public var sarUnicastRetransmissionsIntervalIncrement: UInt8 {
        get { return _sarUnicastRetransmissionsIntervalIncrement }
        set { _sarUnicastRetransmissionsIntervalIncrement = min(newValue, 0b1111) } // Valid range: 0-15
    }
    
    /// The **SAR Multicast Retransmissions Count state** is a 4-bit value that
    /// controls the maximum number of transmissions of segments of segmented
    /// messages to a group address or a virtual address.
    ///
    /// The maximum number of transmissions of a segment is calculated with the 
    /// following formula:
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
    public var sarMulticastRetransmissionsIntervalStep: UInt8 {
        get { return _sarMulticastRetransmissionsIntervalStep }
        set { _sarMulticastRetransmissionsIntervalStep = min(newValue, 0b1111) } // Valid range: 0-15
    }
    
    // MARK: - Acknowledged messages configuration implementation
    
    /// If the Element does not receive a response within a period of time known
    /// as the acknowledged message timeout, then the Element may consider the
    /// message has not been delivered, without sending any additional messages.
    ///
    /// The ``MeshNetworkDelegate/meshNetworkManager(_:failedToSendMessage:from:to:error:)-7iylf``
    /// callback will be called on timeout.
    ///
    /// The acknowledged message timeout should be set to a minimum of 30 seconds,
    /// which is the default value.
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
    ///
    /// The interval is doubled each time a request is retransmitted.
    ///
    /// The default value is 2 seconds.
    public var acknowledgmentMessageInterval: TimeInterval {
        get { return _acknowledgmentMessageInterval }
        set { _acknowledgmentMessageInterval = max(2.0, newValue) }
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
    /// This snippet shows how to set the configuration using default values as an example:
    /// ```swift
    /// meshNetworkManager.networkParameters = .basic { builder in
    ///     builder.setDefaultTtl(5)
    ///     // Configure SAR Receiver properties
    ///     builder.discardIncompleteSegmentedMessages(after: 10.0)
    ///     builder.transmitSegmentAcknowledgmentMessage(
    ///         usingSegmentReceptionInterval: 0.06,
    ///         multipliedByMinimumDelayIncrement: 2.5)
    ///     builder.retransmitSegmentAcknowledgmentMessages(
    ///         exactly: 1, timesWhenNumberOfSegmentsIsGreaterThan: 3)
    ///     // Configure SAR Transmitter properties
    ///     builder.transmitSegments(withInterval: 0.06)
    ///     builder.retransmitUnacknowledgedSegmentsToUnicastAddress(
    ///         atMost: 2, timesAndWithoutProgress: 2,
    ///         timesWithRetransmissionInterval: 0.200, andIncrement: 2.5)
    ///     builder.retransmitAllSegmentsToGroupAddress(exactly: 3, timesWithInterval: 0.250)
    ///     // Configure acknowledged message timeouts
    ///     builder.retransmitAcknowledgedMessage(after: 2.0)
    ///     builder.discardAcknowledgedMessages(after: 30.0)
    /// }
    /// ```
    ///
    /// - parameter builder: The configuration builder.
    /// - returns: The ``NetworkParameters`` structure.
    public static func basic(_ builder: (inout NetworkParameters.Config) -> ()) -> NetworkParameters {
        var config = NetworkParameters.Config()
        builder(&config)
        return config.build()
    }
    
    /// A builder for advanced configuration.
    ///
    /// The builder allows to set SAR parameters and other advanced network parameters.
    ///
    /// This snippet shows how to set the configuration using default values as an example:
    /// ```swift
    /// // This snippet is using default values as an example.
    /// meshNetworkManager.networkParameters = .advanced { parameters in
    ///     parameters.defaultTtl = 5
    ///     // Configure SAR Receiver properties
    ///     parameters.sarDiscardTimeout = 0b0001
    ///     parameters.sarAcknowledgmentDelayIncrement = 0b001
    ///     parameters.sarReceiverSegmentIntervalStep = 0b101
    ///     parameters.sarSegmentsThreshold = 1
    ///     parameters.sarAcknowledgmentRetransmissionsCount = 3
    ///     // Configure SAR Transmitter properties
    ///     parameters.sarSegmentIntervalStep = 0b0101
    ///     parameters.sarUnicastRetransmissionsCount = 0b0111
    ///     parameters.sarUnicastRetransmissionsWithoutProgressCount = 0b0010
    ///     parameters.sarUnicastRetransmissionsIntervalStep = 0b0111
    ///     parameters.sarUnicastRetransmissionsIntervalIncrement = 0b0001
    ///     parameters.sarMulticastRetransmissionsCount = 0b0010
    ///     parameters.sarMulticastRetransmissionsIntervalStep = 0b1001
    ///     // Configure acknowledged message timeouts
    ///     parameters.acknowledgmentMessageInterval = 2.0
    ///     parameters.acknowledgmentMessageTimeout = 30.0
    /// }
    /// ```
    ///
    /// - parameter builder: The configuration builder.
    /// - returns: The ``NetworkParameters`` structure.
    public static func advanced(_ builder: (inout NetworkParameters) -> ()) -> NetworkParameters {
        var networkParameters = NetworkParameters.default
        builder(&networkParameters)
        return networkParameters
    }
    
    /// A set of default network parameters.
    ///
    /// Example:
    /// ```swift
    /// meshNetworkManager.networkParameters = .default
    /// ```
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

internal extension NetworkParameters {
    
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
    var discardTimeout: TimeInterval {
        return TimeInterval(_sarDiscardTimeout + 1) * 5.0
    }
    
    /// A value indicated by the **SAR Acknowledgment Delay Increment state**.
    ///
    /// - seeAlso ``sarAcknowledgmentDelayIncrement``
    /// - seeAlso ``setAcknowledgmentTimerInterval(_:andMinimumDelayIncrement:)``
    private var acknowledgmentDelayIncrement: Double {
        return Double(_sarAcknowledgmentDelayIncrement) + 1.5
    }
    
    /// A value indicated by the **SAR Receiver Segment Interval Step state**.
    ///
    /// - seeAlso ``sarReceiverSegmentIntervalStep``
    /// - seeAlso ``setAcknowledgmentTimerInterval(_:andMinimumDelayIncrement:)``
    var segmentReceptionInterval: TimeInterval {
        return Double(_sarReceiverSegmentIntervalStep + 1) * 0.01
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
    func acknowledgmentTimerInterval(forLastSegmentNumber segN: UInt8) -> TimeInterval {
        return min(Double(segN) + 0.5, acknowledgmentDelayIncrement) * segmentReceptionInterval
    }
    
    /// The initial value of the timer ensuring that no more than one Segment Acknowledgment message
    /// is sent for the same SeqAuth value in a period of:
    /// ```
    /// acknowledgment delay increment * segment reception interval (ms)
    /// ```
    var completeAcknowledgmentTimerInterval: TimeInterval {
        return acknowledgmentDelayIncrement * segmentReceptionInterval
    }
    
    /// The interval between transmissions of segments of a segmented message.
    ///
    /// The value of this interval is indicated by **SAR Segment Interval Step state**.
    ///
    /// - seeAlso: ``sarSegmentIntervalStep``
    var segmentTransmissionInterval: TimeInterval {
        return Double(_sarSegmentIntervalStep + 1) * 0.01
    }
    
    /// The interval between retransmissions of segments of a segmented
    /// message for a destination that is a Unicast Address.
    ///
    /// Valid range is from 25 ms to 400 ms with 25 ms interval.
    /// - seeAlso: ``sarUnicastRetransmissionsIntervalStep``
    private var unicastRetransmissionsIntervalStep: TimeInterval {
        return Double(_sarUnicastRetransmissionsIntervalStep + 1) * 0.025
    }
    
    /// The incremental component of the interval between retransmissions of segments
    /// of a segmented message for a destination that is a Unicast Address.
    ///
    /// The increment component is multiplied by `TTL - 1` when calculating the
    /// initial value of the SAR Unicast Retransmissions timer.
    ///
    /// Valid range is from 25 ms to 400 ms with 25 ms interval.
    /// - seeAlso: ``sarUnicastRetransmissionsIntervalIncrement``
    private var unicastRetransmissionsIntervalIncrement: TimeInterval {
        return Double(_sarUnicastRetransmissionsIntervalIncrement + 1) * 0.025
    }
    
    /// The initial value of the SAR Unicast Retransmissions timer.
    ///
    /// - parameter ttl: The TTL value with the message is being sent.
    /// - returns: The initial value of the SAR Unicast Retransmissions timer.
    func unicastRetransmissionsInterval(for ttl: UInt8) -> TimeInterval {
        // If the value of the TTL field of the message is 0, the initial value
        // of the timer shall be set to the unicast retransmissions interval step.
        if ttl == 0 {
            return unicastRetransmissionsIntervalStep
        }
        return unicastRetransmissionsIntervalStep + unicastRetransmissionsIntervalIncrement * Double(ttl - 1)
    }
    
    /// The interval between retransmissions of segments of a segmented message for
    /// a destination that is a Group Address or a Virtual Address.
    ///
    /// Valid range is from 25 ms to 400 ms with 25 ms interval.
    ///
    /// - seeAlso: ``sarMulticastRetransmissionsIntervalStep``
    var multicastRetransmissionsInterval: TimeInterval {
        return Double(_sarMulticastRetransmissionsIntervalStep + 1) * 0.025
    }
    
    // TODO: Doc
    func acknowledgmentMessageInterval(forTtl ttl: UInt8,
                                       andSegmentCount segmentCount: Int) -> TimeInterval {
        return _acknowledgmentMessageInterval + Double(ttl) * 0.050 + Double(segmentCount) * 0.050
    }
}
