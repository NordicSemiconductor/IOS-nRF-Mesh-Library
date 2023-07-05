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
    ///     builder.defaultTtl = ...
    ///     builder.incompleteMessageTimeout = ...
    ///     builder.acknowledgmentTimerInterval = ...
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
    
    private var _defaultTtl: UInt8 = 5
    private var _incompleteMessageTimeout: TimeInterval = 10.0
    private var _acknowledgmentTimerInterval: TimeInterval = 0.150
    private var _transmissionTimerInterval: TimeInterval = 0.200
    private var _retransmissionLimit: Int = 5
    private var _acknowledgmentMessageTimeout: TimeInterval = 30.0
    private var _acknowledgmentMessageInterval: TimeInterval = 2.0
    
    /// The Default TTL will be used for sending messages, if the value has
    /// not been set in the Provisioner's Node. By default it is set to 5,
    /// which is a reasonable value. The TTL shall be in range 2...127.
    public var defaultTtl: UInt8 {
        get { return _defaultTtl }
        set { _defaultTtl = max(2, min(newValue, 127)) }
    }
    
    /// The timeout after which an incomplete segmented message will be
    /// abandoned. The timer is restarted each time a segment of this
    /// message is received.
    ///
    /// The incomplete timeout should be set to at least 10 seconds.
    public var incompleteMessageTimeout: TimeInterval {
        get { return _incompleteMessageTimeout }
        set { _incompleteMessageTimeout = max(10.0, newValue) }
    }
    
    /// The amount of time after which the lower transport layer sends a
    /// Segment Acknowledgment message after receiving a segment of a
    /// multi-segment message where the destination is a Unicast Address
    /// of the Provisioner's Element.
    ///
    /// The acknowledgment timer shall be set to a minimum of
    /// 150 + 50 * TTL milliseconds. The TTL dependent part is added
    /// automatically, and this value shall specify only the constant part.
    public var acknowledgmentTimerInterval: TimeInterval {
        get { return _acknowledgmentTimerInterval }
        set { _acknowledgmentTimerInterval = max(0.150, newValue) }
    }
    
    func acknowledgmentTimerInterval(forTtl ttl: UInt8) -> TimeInterval {
        return _acknowledgmentTimerInterval + Double(ttl) * 0.050
    }
    
    /// The time within which a Segment Acknowledgment message is
    /// expected to be received after a segment of a segmented message has
    /// been sent. When the timer is fired, the non-acknowledged segments
    /// are repeated, at most ``retransmissionLimit`` times.
    ///
    /// The transmission timer shall be set to a minimum of
    /// 200 + 50 * TTL milliseconds. The TTL dependent part is added
    /// automatically, and this value shall specify only the constant part.
    ///
    /// If the bearer is using GATT, it is recommended to set the transmission
    /// interval longer than the connection interval, so that the acknowledgment
    /// had a chance to be received.
    public var transmissionTimerInterval: TimeInterval {
        get { return _transmissionTimerInterval }
        set { _transmissionTimerInterval = max(0.200, newValue) }
    }
    
    func transmissionTimerInterval(forTtl ttl: UInt8) -> TimeInterval {
        return _transmissionTimerInterval + Double(ttl) * 0.050
    }
    
    /// Number of times a non-acknowledged segment of a segmented message
    /// will be retransmitted before the message will be cancelled.
    ///
    /// The limit may be decreased with increasing of ``transmissionTimerInterval``
    /// as the target Node has more time to reply with the Segment
    /// Acknowledgment message.
    public var retransmissionLimit: Int {
        get { return _retransmissionLimit }
        set { _retransmissionLimit = max(2, newValue) }
    }
    
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
    /// The repeat timer will be set to the base time + 50 * TTL milliseconds +
    /// 50 * segment count. The TTL and segment count dependent parts are added
    /// automatically, and this value shall specify only the constant part.
    public var acknowledgmentMessageInterval: TimeInterval {
        get { return _acknowledgmentMessageInterval }
        set { _acknowledgmentMessageInterval = max(2.0, newValue) }
    }
    
    func acknowledgmentMessageInterval(forTtl ttl: UInt8, andSegmentCount segmentCount: Int) -> TimeInterval {
        return _acknowledgmentMessageInterval + Double(ttl) * 0.050 + Double(segmentCount) * 0.050
    }
    
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
