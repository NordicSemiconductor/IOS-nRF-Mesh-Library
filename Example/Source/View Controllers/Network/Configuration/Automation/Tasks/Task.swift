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

import nRFMeshProvision

enum Task {
    case readRelayStatus
    case readNetworkTransitStatus
    case readBeaconStatus
    case readGATTProxyStatus
    case readFriendStatus
    case readNodeIdentityStatus(_ networkKey: NetworkKey)
    case readHeartbeatPublication
    case readHeartbeatSubscription
    
    case sendNetworkKey(_ networkKey: NetworkKey)
    case sendApplicationKey(_ applicationKey: ApplicationKey)
    case bind(_ applicationKey: ApplicationKey, to: Model)
    case subscribe(_ model: Model, to: Group)
    
    var title: String {
        switch self {
        case .readRelayStatus:
            return "Read Relay Status"
        case .readNetworkTransitStatus:
            return "Read Network Transit Status"
        case .readBeaconStatus:
            return "Read Beacon Status"
        case .readGATTProxyStatus:
            return "Read GATT Proxy Status"
        case .readFriendStatus:
            return "Read Friend Status"
        case .readNodeIdentityStatus(let key):
            return "Read Node Identity Status for \(key.name)"
        case .readHeartbeatPublication:
            return "Read Heartbeat Publication"
        case .readHeartbeatSubscription:
            return "Read Heartbeat Subscription"
        case .sendNetworkKey(let key):
            return "Send \(key.name)"
        case .sendApplicationKey(let key):
            return "Send \(key.name)"
        case .bind(let key, to: let model):
            return "Bind \(key.name) to \(model)"
        case .subscribe(let model, to: let group):
            return "Subscribe \(model) to \(group.name)"
        }
    }
    
    var message: AcknowledgedConfigMessage {
        switch self {
        case .readRelayStatus:
            return ConfigRelayGet()
        case .readNetworkTransitStatus:
            return ConfigNetworkTransmitGet()
        case .readBeaconStatus:
            return ConfigBeaconGet()
        case .readGATTProxyStatus:
            return ConfigGATTProxyGet()
        case .readFriendStatus:
            return ConfigFriendGet()
        case .readNodeIdentityStatus(let key):
            return ConfigNodeIdentityGet(networkKey: key)
        case .readHeartbeatPublication:
            return ConfigHeartbeatPublicationGet()
        case .readHeartbeatSubscription:
            return ConfigHeartbeatSubscriptionGet()
        case .sendNetworkKey(let key):
            return ConfigNetKeyAdd(networkKey: key)
        case .sendApplicationKey(let key):
            return ConfigAppKeyAdd(applicationKey: key)
        case .bind(let key, to: let model):
            return ConfigModelAppBind(applicationKey: key, to: model)!
        case .subscribe(let model, to: let group):
            if let message = ConfigModelSubscriptionAdd(group: group, to: model) {
                return message
            } else {
                return ConfigModelSubscriptionVirtualAddressAdd(group: group, to: model)!
            }
        }
    }
}
