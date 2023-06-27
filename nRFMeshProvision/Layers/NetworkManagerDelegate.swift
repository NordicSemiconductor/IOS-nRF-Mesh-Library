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

/// The delegate handles events from the `NetworkManager`.
internal protocol NetworkManagerDelegate: AnyObject {
    
    /// A callback called whenever a Mesh Message has been received
    /// from the mesh network.
    ///
    /// The `source` is given as an Address, instead of an Element, as
    /// the message may be sent by an unknown Node, or a Node which
    /// Elements are unknown.
    ///
    /// The `destination` address may be a Unicast Address of a local
    /// Element, a Group or Virtual Address, but also any other address
    /// if it was added to the Proxy Filter, e.g. a Unicast Address of
    /// an Element on a remote Node.
    ///
    /// - parameters:
    ///   - manager:     The manager which has received the message.
    ///   - message:     The received message.
    ///   - source:      The Unicast Address of the Element from which
    ///                  the message was sent.
    ///   - destination: The address to which the message was sent.
    func networkManager(_ manager: NetworkManager,
                        didReceiveMessage message: MeshMessage,
                        sentFrom source: Address, to destination: MeshAddress)
    
    /// A callback called when an unsegmented message was sent to the
    /// ``Transmitter``, or when all segments of a segmented message targeting
    /// a Unicast Address were acknowledged by the target Node.
    ///
    /// - parameters:
    ///   - manager:      The manager used to send the message.
    ///   - message:      The message that has been sent.
    ///   - localElement: The local Element used as a source of this message.
    ///   - destination:  The address to which the message was sent.
    func networkManager(_ manager: NetworkManager,
                        didSendMessage message: MeshMessage,
                        from localElement: Element, to destination: MeshAddress)
    
    /// A callback called when a message failed to be sent to the target
    /// Node, or the response for an acknowledged message hasn't been received
    /// before the time run out.
    ///
    /// For unsegmented unacknowledged messages this callback will be invoked when
    /// the ``MeshNetworkManager/transmitter`` was set to `nil`, or has thrown an
    /// exception from ``Transmitter/send(_:ofType:)``.
    ///
    /// For segmented unacknowledged messages targeting a Unicast Address,
    /// besides that, it may also be called when sending timed out before all of
    /// the segments were acknowledged by the target Node, or when the target
    /// Node is busy and not able to proceed the message at the moment.
    ///
    /// For acknowledged messages the callback will be called when the response
    /// has not been received before the time set by
    /// ``NetworkParameters/acknowledgmentMessageTimeout`` run out.
    /// The message might have been retransmitted multiple times and might have
    /// been received by the target Node. For acknowledged messages sent to
    /// a Group or Virtual Address this will be called when the response has not
    /// been received from any Node.
    ///
    /// Possible errors are:
    /// - Any error thrown by the ``Transmitter``.
    /// - ``BearerError/bearerClosed`` - when the ``MeshNetworkManager/transmitter``
    ///   object was not set.
    /// - ``LowerTransportError/busy`` - when the target Node is busy and can't
    ///   accept the message.
    /// - ``LowerTransportError/timeout`` - when the segmented message targeting
    ///   a Unicast Address was not acknowledged before the
    ///   ``NetworkParameters/retransmissionLimit`` was reached
    ///   (for unacknowledged messages only).
    /// - ``AccessError/timeout`` - when the response for an acknowledged message
    ///   has not been received before the time run out (for acknowledged messages
    ///   only).
    ///
    /// - parameters:
    ///   - manager:      The manager used to send the message.
    ///   - message:      The message that has failed to be delivered.
    ///   - localElement: The local Element used as a source of this message.
    ///   - destination:  The address to which the message was sent.
    ///   - error:        The error that occurred.
    func networkManager(_ manager: NetworkManager,
                        failedToSendMessage message: MeshMessage,
                        from localElement: Element, to destination: MeshAddress,
                        error: Error)
    
    /// A callback called when the network configuration has changed.
    func networkDidChange()
    
    /// A callback called when the ``ConfigNodeReset`` message was received for the
    /// local Node.
    ///
    /// The Node should forget the mesh network, all the keys, nodes, groups and scenes.
    ///
    /// A new network may be created.
    func networkDidReset()
    
}
