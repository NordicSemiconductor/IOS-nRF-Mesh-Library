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

enum MeshTask {
    case getCompositionData(page: UInt8)
    case getDefaultTtl
    case setDefaultTtl(_ ttl: UInt8)
    case readRelayStatus
    case setRelay(_ relayRetransmit: Node.RelayRetransmit)
    case disableRelayFeature
    case readNetworkTransitStatus
    case setNetworkTransit(_ networkTransmit: Node.NetworkTransmit)
    case readBeaconStatus
    case setBeacon(enabled: Bool)
    case readGATTProxyStatus
    case setGATTProxy(enabled: Bool)
    case readFriendStatus
    case setFriend(enabled: Bool)
    case readNodeIdentityStatus(_ networkKey: NetworkKey)
    case readHeartbeatPublication
    case setHeartbeatPublication(countLog: UInt8,
                                 periodLog: UInt8,
                                 destination: Address,
                                 ttl: UInt8, networkKey: NetworkKey,
                                 triggerFeatures: NodeFeatures)
    case readHeartbeatSubscription
    case setHeartbeatSubscription(source: Address, destination: Address, periodLog: UInt8)
    case sendNetworkKey(_ networkKey: NetworkKey)
    case sendApplicationKey(_ applicationKey: ApplicationKey)
    case bind(_ applicationKey: ApplicationKey, to: Model)
    case subscribe(_ model: Model, to: Group)
    case setPublication(_ publish: Publish, to: Model)
    
    var title: String {
        switch self {
        case .getCompositionData(page: let page):
            return "Get Composition Page \(page)"
        case .getDefaultTtl:
            return "Read default TTL"
        case .setDefaultTtl(let ttl):
            return "Set Default TTL to \(ttl)"
        case .readRelayStatus:
            return "Read Relay Status"
        case .setRelay:
            return "Set Relay"
        case .disableRelayFeature:
            return "Disabling Relay Retransmission"
        case .readNetworkTransitStatus:
            return "Read Network Transit Status"
        case .setNetworkTransit:
            return "Set Network Transmit"
        case .readBeaconStatus:
            return "Read Beacon Status"
        case .setBeacon(let enable):
            return "\(enable ? "Enable" : "Disable") Secure Network Beacons"
        case .readGATTProxyStatus:
            return "Read GATT Proxy Status"
        case .setGATTProxy(enabled: let enable):
            return "\(enable ? "Enable" : "Disable") GATT Proxy Feature"
        case .readFriendStatus:
            return "Read Friend Status"
        case .setFriend(enabled: let enable):
            return "\(enable ? "Enable" : "Disable") Friend Feature"
        case .readNodeIdentityStatus(let key):
            return "Read Node Identity Status for \(key.name)"
        case .readHeartbeatPublication:
            return "Read Heartbeat Publication"
        case .setHeartbeatPublication:
            return "Set Heartbeat Publication"
        case .readHeartbeatSubscription:
            return "Read Heartbeat Subscription"
        case .setHeartbeatSubscription:
            return "Set Heartbeat Subscription"
        case .sendNetworkKey(let key):
            return "Add \(key.name)"
        case .sendApplicationKey(let key):
            return "Add \(key.name)"
        case .bind(let key, to: let model):
            return "Bind \(key.name) to \(model)"
        case .subscribe(let model, to: let group):
            return "Subscribe \(model) to \(group.name)"
        case .setPublication(_, let model):
            return "Set Publication to \(model)"
        }
    }
    
    var icon: UIImage {
        switch self {
        case .getCompositionData,
             .getDefaultTtl,
             .setDefaultTtl,
             .readNodeIdentityStatus:
            return #imageLiteral(resourceName: "ic_settings_24pt")
        case .readBeaconStatus,
             .setBeacon:
            return #imageLiteral(resourceName: "ic_beacon_24pt")
        case .readFriendStatus,
             .setFriend:
            return #imageLiteral(resourceName: "ic_friend_24pt")
        case .readRelayStatus,
             .setRelay,
             .disableRelayFeature,
             .readGATTProxyStatus,
             .setGATTProxy,
             .readNetworkTransitStatus,
             .setNetworkTransit:
            return #imageLiteral(resourceName: "ic_transfer_24pt")
        case .sendNetworkKey,
             .sendApplicationKey:
            return #imageLiteral(resourceName: "ic_vpn_key_24pt")
        case .bind:
            return #imageLiteral(resourceName: "ic_bind_24pt")
        case .subscribe:
            return #imageLiteral(resourceName: "ic_group_24pt")
        case .setPublication:
            return #imageLiteral(resourceName: "ic_broadcast_24pt")
        case .readHeartbeatSubscription,
             .setHeartbeatSubscription,
             .readHeartbeatPublication,
             .setHeartbeatPublication:
            return #imageLiteral(resourceName: "ic_heartbeat_24pt")
        }
    }
    
    var message: AcknowledgedConfigMessage {
        switch self {
        case .getCompositionData(page: let page):
            return ConfigCompositionDataGet(page: page)
        case .getDefaultTtl:
            return ConfigDefaultTtlGet()
        case .setDefaultTtl(let ttl):
            return ConfigDefaultTtlSet(ttl: ttl)
        case .readRelayStatus:
            return ConfigRelayGet()
        case .setRelay(let relayRetransmit):
            return ConfigRelaySet(relayRetransmit)
        case .disableRelayFeature:
            return ConfigRelaySet()
        case .readNetworkTransitStatus:
            return ConfigNetworkTransmitGet()
        case .setNetworkTransit(let networkTransmit):
            return ConfigNetworkTransmitSet(networkTransmit)
        case .readBeaconStatus:
            return ConfigBeaconGet()
        case .setBeacon(enabled: let enable):
            return ConfigBeaconSet(enable: enable)
        case .readGATTProxyStatus:
            return ConfigGATTProxyGet()
        case .setGATTProxy(enabled: let enable):
            return ConfigGATTProxySet(enable: enable)
        case .readFriendStatus:
            return ConfigFriendGet()
        case .setFriend(enabled: let enable):
            return ConfigFriendSet(enable: enable)
        case .readNodeIdentityStatus(let key):
            return ConfigNodeIdentityGet(networkKey: key)
        case .readHeartbeatPublication:
            return ConfigHeartbeatPublicationGet()
        case .setHeartbeatPublication(countLog: let countLog,
                                      periodLog: let periodLog,
                                      destination: let destination,
                                      ttl: let ttl,
                                      networkKey: let networkKey,
                                      triggerFeatures: let features):
            return ConfigHeartbeatPublicationSet(startSending: countLog, heartbeatMessagesEvery: periodLog,
                                                 secondsTo: destination,
                                                 usingTtl: ttl, andNetworkKey: networkKey,
                                                 andEnableHeartbeatMessagesTriggeredByChangeOf: features)
                ?? ConfigHeartbeatPublicationSet()
        case .readHeartbeatSubscription:
            return ConfigHeartbeatSubscriptionGet()
        case .setHeartbeatSubscription(source: let source, destination: let destination, periodLog: let periodLog):
            return ConfigHeartbeatSubscriptionSet(startProcessingHeartbeatMessagesFor: periodLog,
                                                  secondsSentFrom: source, to: destination)
                ?? ConfigHeartbeatSubscriptionSet()
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
        case .setPublication(let publish, let model):
            if let message = ConfigModelPublicationSet(publish, to: model) {
                return message
            } else {
                return ConfigModelPublicationVirtualAddressSet(publish, to: model)!
            }
        }
    }
}
