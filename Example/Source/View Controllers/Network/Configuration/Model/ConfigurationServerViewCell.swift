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

import UIKit
import nRFMeshProvision

class ConfigurationServerViewCell: ModelViewCell {
    
    // MARK: - Outlets and Actions
    
    // Relay
    @IBOutlet weak var relayCountSlider: UISlider!
    @IBOutlet weak var relayIntervalSlider: UISlider!
    @IBOutlet weak var relayCountLabel: UILabel!
    @IBOutlet weak var relayIntervalLabel: UILabel!
    
    @IBAction func relayCountDidChange(_ sender: UISlider) {
        let value = Int(sender.value + 1)
        relayIntervalSlider.isEnabled = value > 1
        if value == 1 {
            relayCountLabel.text = "\(value) transmission"
            relayIntervalLabel.text = "N/A"
        } else {
            relayCountLabel.text = "\(value) transmissions"
            relayIntervalLabel.text = "\(Int(relayIntervalSlider.value + 1) * 10) ms"
        }
    }
    @IBAction func relayIntervalDidChange(_ sender: UISlider) {
        relayIntervalLabel.text = "\(Int(sender.value + 1) * 10) ms"
    }
    @IBOutlet weak var setRelayButton: UIButton!
    @IBAction func setRelayTapped(_ sender: UIButton) {
        setRelay()
    }
    
    // Network Transmit
    @IBOutlet weak var networkTransmitCountSlider: UISlider!
    @IBOutlet weak var networkTransmitIntervalSlider: UISlider!
    @IBOutlet weak var networkTransmitCountLabel: UILabel!
    @IBOutlet weak var networkTransmitIntervalLabel: UILabel!
    
    @IBOutlet weak var networkTransmitButton: UIButton!
    @IBAction func networkTransmitCountDidChange(_ sender: UISlider) {
        let value = Int(sender.value + 1)
        networkTransmitIntervalSlider.isEnabled = value > 1
        if value == 1 {
            networkTransmitCountLabel.text = "\(value) transmission"
            networkTransmitIntervalLabel.text = "N/A"
        } else {
            networkTransmitCountLabel.text = "\(value) transmissions"
            networkTransmitIntervalLabel.text = "\(Int(networkTransmitIntervalSlider.value + 1) * 10) ms"
        }
    }
    @IBAction func networkTransmitIntervalDidChange(_ sender: UISlider) {
        networkTransmitIntervalLabel.text = "\(Int(sender.value + 1) * 10) ms"
    }
    @IBAction func setNetworkTransmitTapped(_ sender: UIButton) {
        setNetworkTransmit()
    }
    
    // Secure Network Beacon
    @IBOutlet weak var secureNetworkBeaconSwitch: UISwitch!
    @IBAction func secureNetworkBeaconDidChange(_ sender: UISwitch) {
        setSecureNetworkBeaconStatus(enable: sender.isOn)
    }
    
    // GATT Proxy
    @IBOutlet weak var gattProxySwitch: UISwitch!
    @IBAction func gattProxyDidChange(_ sender: UISwitch) {
        setGATTProxyStatus(enable: sender.isOn)
    }
    
    // Friend Feature
    @IBOutlet weak var friendFeatureSwitch: UISwitch!
    @IBAction func friendFeatureDidChange(_ sender: UISwitch) {
        setFriendFeatureStatus(enable: sender.isOn)
    }
    
    override func reload(using model: Model) {
        if let node = model.parentElement?.parentNode {
            if let relay = node.relayRetransmit {
                // Interval needs to be set first, as Count may override its Label to N/A.
                relayIntervalSlider.value = Float(relay.steps)
                relayIntervalSlider.isEnabled = true
                relayIntervalDidChange(relayIntervalSlider)
                relayCountSlider.value = Float(relay.count - 1)
                relayCountDidChange(relayCountSlider)
            } else if delegate.isRefreshing {
                relayCountLabel.text = "Not supported"
                relayIntervalLabel.text = "N/A"
                relayCountSlider.isEnabled = false
                relayIntervalSlider.isEnabled = false
            }
            if let networkTransmit = node.networkTransmit {
                // Interval needs to be set first, as Count may override its Label to N/A.
                networkTransmitIntervalSlider.value = Float(networkTransmit.steps)
                networkTransmitIntervalDidChange(networkTransmitIntervalSlider)
                networkTransmitCountSlider.value = Float(networkTransmit.count - 1)
                networkTransmitCountDidChange(networkTransmitCountSlider)
            }
            let localProvisioner = MeshNetworkManager.instance.meshNetwork?.localProvisioner
            let isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
            setRelayButton.isEnabled = isEnabled && node.relayRetransmit != nil
            networkTransmitButton.isEnabled = isEnabled
            
            secureNetworkBeaconSwitch.isOn = node.secureNetworkBeacon ?? false
            secureNetworkBeaconSwitch.isEnabled = isEnabled
            if let features = node.features {
                gattProxySwitch.isOn = features.proxy != nil && features.proxy! == .enabled
                gattProxySwitch.isEnabled = isEnabled && features.proxy != nil && features.proxy! != .notSupported
                friendFeatureSwitch.isOn = features.friend != nil && features.friend! == .enabled
                friendFeatureSwitch.isEnabled = isEnabled && features.friend != nil && features.friend! != .notSupported
            }
        }
    }
    
    override func startRefreshing() -> Bool {
        readRelay()
        return true
    }
    
    override func supports(_ messageType: MeshMessage.Type) -> Bool {
        return messageType == ConfigRelayStatus.self
            || messageType == ConfigNetworkTransmitStatus.self
            || messageType == ConfigBeaconStatus.self
            || messageType == ConfigGATTProxyStatus.self
            || messageType == ConfigFriendStatus.self
    }
    
    override func meshNetworkManager(_ manager: MeshNetworkManager,
                                     didReceiveMessage message: MeshMessage,
                                     sentFrom source: Address, to destination: MeshAddress) -> Bool {
        switch message {
            
        case is ConfigRelayStatus:
            reload(using: model)
            
            if delegate?.isRefreshing ?? false {
                readNetworkTransmit()
                return true
            }
            return false
            
        case is ConfigNetworkTransmitStatus:
            reload(using: model)
            
            if delegate?.isRefreshing ?? false {
                readSecureNetworkBeaconStatus()
                return true
            }
            return false
            
        case is ConfigBeaconStatus:
            reload(using: model)
            
            if delegate?.isRefreshing ?? false {
                readGATTProxyStatus()
                return true
            }
            return false
            
        case is ConfigGATTProxyStatus:
            reload(using: model)
            
            if delegate?.isRefreshing ?? false {
                readFriendFeatureStatus()
                return true
            }
            return false
            
        case is ConfigFriendStatus:
            reload(using: model)
            return false
            
        default:
            fatalError()
        }
    }

}

private extension ConfigurationServerViewCell {
    
    func readRelay() {
        delegate?.send(ConfigRelayGet(), description: "Reading Relay status...")
    }
    
    func setRelay() {
        let count = UInt8(relayCountSlider.value)
        let steps = UInt8(relayIntervalSlider.value)
        delegate?.send(ConfigRelaySet(count: count, steps: steps), description: "Sending Relay settings...")
    }
    
    func readNetworkTransmit() {
        delegate?.send(ConfigNetworkTransmitGet(), description: "Reading Network Transmit status...")
    }
    
    func setNetworkTransmit() {
        let count = UInt8(networkTransmitCountSlider.value)
        let steps = UInt8(networkTransmitIntervalSlider.value)
        delegate?.send(ConfigNetworkTransmitSet(count: count, steps: steps), description: "Sending Network Transmit settings...")
    }
    
    func readSecureNetworkBeaconStatus() {
        delegate?.send(ConfigBeaconGet(), description: "Reading Secure Beacon Network status...")
    }
    
    func setSecureNetworkBeaconStatus(enable: Bool) {
        let message = "\(enable ? "Enabling" : "Disabling") Secure Network Beacons..."
        delegate?.send(ConfigBeaconSet(enable: enable), description: message)
    }
    
    func readGATTProxyStatus() {
        delegate?.send(ConfigGATTProxyGet(), description: "Reading GATT Proxy status...")
    }
    
    func setGATTProxyStatus(enable: Bool) {
        let message = "\(enable ? "Enabling" : "Disabling") GATT Proxy..."
        delegate?.send(ConfigGATTProxySet(enable: enable), description: message)
    }
    
    func readFriendFeatureStatus() {
        delegate?.send(ConfigFriendGet(), description: "Reading Friend Feature status...")
    }
    
    func setFriendFeatureStatus(enable: Bool) {
        let message = "\(enable ? "Enabling" : "Disabling") Friend feature..."
        delegate?.send(ConfigFriendSet(enable: enable), description: message)
    }
    
}
