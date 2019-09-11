//
//  GenericOnOffViewCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 22/08/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class GenericOnOffViewCell: ModelViewCell {
    
    // MARK: - Outlets and Actinos

    @IBOutlet weak var defaultTransitionSettingsSwitch: UISwitch!
    @IBAction func defaultTransitionSettingsDidChange(_ sender: UISwitch) {
        transitionTimeSlider.isEnabled = !sender.isOn
        delaySlider.isEnabled = !sender.isOn
        
        if sender.isOn {
            transitionTimeLabel.text = "Default"
            delayLabel.text = "No delay"
        } else {
            transitionTimeSelected(transitionTimeSlider.value)
            delaySelected(delaySlider.value)
        }
    }
    
    @IBOutlet weak var transitionTimeSlider: UISlider!
    @IBOutlet weak var delaySlider: UISlider!
    
    @IBOutlet weak var transitionTimeLabel: UILabel!
    @IBOutlet weak var delayLabel: UILabel!
    @IBOutlet weak var currentStatusLabel: UILabel!
    @IBOutlet weak var targetStatusLabel: UILabel!
    
    @IBAction func transitionTimeDidChange(_ sender: UISlider) {
        transitionTimeSelected(sender.value)
    }
    @IBAction func delayDidChange(_ sender: UISlider) {
        delaySelected(sender.value)
    }
    
    @IBOutlet weak var acknowledgmentSwitch: UISwitch!
    
    @IBOutlet weak var onButton: UIButton!
    @IBAction func onTapped(_ sender: UIButton) {
        sendGenericOnOffMessage(turnOn: true)
    }
    @IBOutlet weak var offButton: UIButton!
    @IBAction func offTapped(_ sender: UIButton) {
        sendGenericOnOffMessage(turnOn: false)
    }
    @IBOutlet weak var readButton: UIButton!
    @IBAction func readTapped(_ sender: UIButton) {
        readGenericOnOffState()
    }
    
    // MARK: - Properties
    
    private var steps: UInt8 = 0
    private var stepResolution: StepResolution = .hundredsOfMilliseconds
    private var delay: UInt8 = 0
    
    // MARK: - Implementation
    
    override func reload(using model: Model) {
        let localProvisioner = MeshNetworkManager.instance.meshNetwork?.localProvisioner
        let isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
        
        defaultTransitionSettingsSwitch.isEnabled = isEnabled
        acknowledgmentSwitch.isEnabled = isEnabled
        onButton.isEnabled = isEnabled
        offButton.isEnabled = isEnabled
        readButton.isEnabled = isEnabled
    }
    
    override func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage,
                              sentFrom source: Address, to destination: Address) -> Bool {
        switch message {
        case let status as GenericOnOffStatus:
            currentStatusLabel.text = status.isOn ? "ON" : "OFF"
            if let targetStatus = status.targetState, let remainingTime = status.remainingTime {
                if remainingTime.isKnown {
                    targetStatusLabel.text = "\(targetStatus ? "ON" : "OFF") in \(remainingTime.interval) sec"
                } else {
                    targetStatusLabel.text = "\(targetStatus ? "ON" : "OFF") in unknown time"
                }
            } else {
                targetStatusLabel.text = "N/A"
            }
            
        default:
            break
        }
        return false
    }
    
    override func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage,
                              sentFrom localElement: Element, to destination: Address) -> Bool {
        // For acknowledged messages wait for the Acknowledgement Message.
        return acknowledgmentSwitch.isOn
    }
}

private extension GenericOnOffViewCell {
    
    func transitionTimeSelected(_ value: Float) {
        switch value {
        case let period where period < 1.0:
            transitionTimeLabel.text = "Immediate"
            steps = 0
            stepResolution = .hundredsOfMilliseconds
        case let period where period >= 1 && period < 10:
            transitionTimeLabel.text = "\(Int(period) * 100) ms"
            steps = UInt8(period)
            stepResolution = .hundredsOfMilliseconds
        case let period where period >= 10 && period < 63:
            transitionTimeLabel.text = String(format: "%.1f sec", floorf(period) / 10)
            steps = UInt8(period)
            stepResolution = .hundredsOfMilliseconds
        case let period where period >= 63 && period < 116:
            transitionTimeLabel.text = "\(Int(period) - 56) sec"
            steps = UInt8(period) - 56
            stepResolution = .seconds
        case let period where period >= 116 && period < 119:
            transitionTimeLabel.text = "\(Int((period + 4) / 60) - 1) min 0\(Int(period + 4) % 60) sec"
            steps = UInt8(period) - 56
            stepResolution = .seconds
        case let period where period >= 119 && period < 175:
            let sec = (Int(period + 2) % 6) * 10
            let secString = sec == 0 ? "00" : "\(sec)"
            transitionTimeLabel.text = "\(Int(period + 2) / 6 - 19) min \(secString) sec"
            steps = UInt8(period) - 112
            stepResolution = .tensOfSeconds
        case let period where period >= 175 && period < 179:
            transitionTimeLabel.text = "\((Int(period) - 173) * 10) min"
            steps = UInt8(period) - 173
            stepResolution = .tensOfMinutes
        case let period where period >= 179:
            let min = (Int(period) - 173) % 6 * 10
            let minString = min == 0 ? "00" : "\(min)"
            transitionTimeLabel.text = "\(Int(period + 1) / 6 - 29) h \(minString) min"
            steps = UInt8(period) - 173
            stepResolution = .tensOfMinutes
        default:
            break
        }
    }
    
    func delaySelected(_ value: Float) {
        delay = UInt8(value)
        if delay == 0 {
            delayLabel.text = "No delay"
        } else {
            delayLabel.text = "Delay \(Int(delay) * 5) ms"
        }
    }
    
    func sendGenericOnOffMessage(turnOn: Bool) {
        guard !model.boundApplicationKeys.isEmpty else {
            parentViewController?.presentAlert(
                title: "Bound key required",
                message: "Bind at least one Application Key before sending the message.")
            return
        }
        
        // Clear the response fields.
        currentStatusLabel.text = nil
        targetStatusLabel.text = nil
        
        var message: MeshMessage!
        
        if acknowledgmentSwitch.isOn {
            if defaultTransitionSettingsSwitch.isOn {
                message = GenericOnOffSet(turnOn)
            } else {
                let transitionTime = TransitionTime(steps: steps, stepResolution: stepResolution)
                message = GenericOnOffSet(turnOn, transitionTime: transitionTime, delay: delay)
            }
        } else {
            if defaultTransitionSettingsSwitch.isOn {
                message = GenericOnOffSetUnacknowledged(turnOn)
            } else {
                let transitionTime = TransitionTime(steps: steps, stepResolution: stepResolution)
                message = GenericOnOffSetUnacknowledged(turnOn, transitionTime: transitionTime, delay: delay)
            }
        }
            
        delegate?.send(message, description: "Sending...")
    }
    
    func readGenericOnOffState() {
        guard !model.boundApplicationKeys.isEmpty else {
            parentViewController?.presentAlert(
                title: "Bound key required",
                message: "Bind at least one Application Key before sending the message.")
            return
        }
        
        delegate?.send(GenericOnOffGet(), description: "Reading state...")
    }
}
