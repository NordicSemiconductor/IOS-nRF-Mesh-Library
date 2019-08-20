//
//  ConfigurationServerViewCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 12/08/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

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
    @IBAction func setRelayTapped(_ sender: UIButton) {
        setRelay()
    }
    
    // Network Transmit
    @IBOutlet weak var networkTransmitCountSlider: UISlider!
    @IBOutlet weak var networkTransmitIntervalSlider: UISlider!
    @IBOutlet weak var networkTransmitCountLabel: UILabel!
    @IBOutlet weak var networkTransmitIntervalLabel: UILabel!
    
    @IBAction func networkTransmitCountDidChange(_ sender: UISlider) {
        let value = Int(sender.value + 1)
        networkTransmitIntervalLabel.isEnabled = value > 1
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
                relayIntervalDidChange(relayIntervalSlider)
                relayCountSlider.value = Float(relay.count)
                relayCountDidChange(relayCountSlider)
            }
            if let networkTransmit = node.networkTransmit {
                // Interval needs to be set first, as Count may override its Label to N/A.
                networkTransmitIntervalSlider.value = Float(networkTransmit.steps)
                networkTransmitIntervalDidChange(networkTransmitIntervalSlider)
                networkTransmitCountSlider.value = Float(networkTransmit.count)
                networkTransmitCountDidChange(networkTransmitCountSlider)
            }
            secureNetworkBeaconSwitch.isOn = node.secureNetworkBeacon ?? false
            if let features = node.features {
                gattProxySwitch.isOn = features.proxy != nil && features.proxy! == .enabled
                gattProxySwitch.isEnabled = features.proxy != nil && features.proxy! != .notSupported
                friendFeatureSwitch.isOn = features.friend != nil && features.friend! == .enabled
                friendFeatureSwitch.isEnabled = features.friend != nil && features.friend! != .notSupported
            }
        }
    }
    
    override func startRefreshing() -> Bool {
        readRelay()
        return true
    }
    
    override func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, from source: Address) -> Bool {
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
            return false
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
