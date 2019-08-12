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
        relayCountLabel.text = "\(Int(sender.value + 1)) transmissions"
    }
    @IBAction func relayIntervalDidChange(_ sender: UISlider) {
        relayIntervalLabel.text = "\(Int(sender.value + 1) * 10) ms"
    }
    @IBAction func setRelayTapped(_ sender: UIButton) {
    }
    
    // Network Transmit
    @IBOutlet weak var networkTransmitCountSlider: UISlider!
    @IBOutlet weak var networkTransmitIntervalSlider: UISlider!
    @IBOutlet weak var networkTransmitCountLabel: UILabel!
    @IBOutlet weak var networkTransmitIntervalLabel: UILabel!
    
    @IBAction func networkTransmitCountDidChange(_ sender: UISlider) {
        networkTransmitCountLabel.text = "\(Int(sender.value + 1)) transmissions"
    }
    @IBAction func networkTransmitIntervalDidChange(_ sender: UISlider) {
        networkTransmitIntervalLabel.text = "\(Int(sender.value + 1) * 10) ms"
    }
    @IBAction func setNetworkTransmitTapped(_ sender: UIButton) {
    }
    
    // Secure Network Beacon
    @IBOutlet weak var secureNetworkBeaconSwitch: UISwitch!
    @IBAction func secureNetworkBeaconDidChange(_ sender: UISwitch) {
    }
    
    // GATT Proxy
    @IBOutlet weak var gattProxySwitch: UISwitch!
    @IBAction func gattProxyDidChange(_ sender: UISwitch) {
    }
    
    // Friend Feature
    @IBOutlet weak var friendFeatureSwitch: UISwitch!
    @IBAction func friendFeatureDidChange(_ sender: UISwitch) {
    }
    
    override func reload(using model: Model) {
        if let node = model.parentElement?.parentNode {
            if let relay = node.relayRetransmit {
                relayCountSlider.value = Float(relay.count)
                relayIntervalSlider.value = Float(relay.steps)
            }
            if let networkTransmit = node.networkTransmit {
                networkTransmitCountSlider.value = Float(networkTransmit.count)
                networkTransmitIntervalSlider.value = Float(networkTransmit.steps)
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
    
    override func startRefreshing() {
        readRelay()
    }
    
    override func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, from source: Address) -> Bool {
        switch message {
            
        case let status as ConfigRelayStatus:
            relayCountSlider.value = Float(status.count + 1)
            relayIntervalSlider.value = Float(status.steps)
            
            if delegate?.isRefreshing ?? false {
                readNetworkTransmit()
                return true
            }
            return false
            
        case let status as ConfigNetworkTransmitStatus:
            networkTransmitCountSlider.value = Float(status.count)
            networkTransmitIntervalSlider.value = Float(status.steps)
            
            if delegate?.isRefreshing ?? false {
                readSecureNetworkBeaconStatus()
                return true
            }
            return false
            
        case let status as ConfigBeaconStatus:
            secureNetworkBeaconSwitch.isOn = status.isEnabled
            
            if delegate?.isRefreshing ?? false {
                readGattProxyStatus()
                return true
            }
            return false
            
        case let status as ConfigGATTProxyStatus:
            gattProxySwitch.isOn = status.state == .enabled
            gattProxySwitch.isEnabled = status.state != .notSupported
            
            if delegate?.isRefreshing ?? false {
                readGattProxyStatus()
                return true
            }
            return false
            
        case let status as ConfigFriendStatus:
            friendFeatureSwitch.isOn = status.state == .enabled
            friendFeatureSwitch.isEnabled = status.state != .notSupported
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
    
    func readNetworkTransmit() {
        delegate?.send(ConfigNetworkTransmitGet(), description: "Reading Network Transmit status...")
    }
    
    func readSecureNetworkBeaconStatus() {
        delegate?.send(ConfigBeaconGet(), description: "Reading Secure Beacon Network status...")
    }
    
    func readGattProxyStatus() {
        delegate?.send(ConfigBeaconGet(), description: "Reading GATT Proxy status...")
    }
    
    func readFriendFeatureStatus() {
        delegate?.send(ConfigBeaconGet(), description: "Reading Friend Feature status...")
    }
    
}
