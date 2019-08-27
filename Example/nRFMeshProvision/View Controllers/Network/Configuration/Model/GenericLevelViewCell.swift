//
//  GenericLevelViewCell.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 26/08/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class GenericLevelViewCell: ModelViewCell {

    // MARK: - Outlets and Actions
    
    @IBOutlet weak var levelSlider: UISlider!
    @IBAction func levelDidChange(_ sender: UISlider) {
        switch segmentControl.selectedSegmentIndex {
        case 0:
            let value = Int(sender.value / 2) // 0...100 (%)
            levelLabel.text = "\(value)%"
        case 1:
            let value = Int(sender.value) - 100 // -100...100 (%)
            levelLabel.text = "\(value)%"
        default:
            let value = Int(sender.value) - 100 // -100...100 (%)
            levelLabel.text = "\(value)%"
        }
    }
    @IBOutlet weak var levelLabel: UILabel!
    
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
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBAction func segmentDidChange(_ sender: UISegmentedControl) {
        levelDidChange(levelSlider)
    }
    
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
    
    @IBAction func setTapped(_ sender: UIButton) {
        switch segmentControl.selectedSegmentIndex {
        case 0:
            let percent = floorf(levelSlider.value / 2)              // 0...100
            let value = Int16(min(32767, -32768 + 655.36 * percent)) // -32768...32767
            sendGenericLevelSetMessage(level: value)
        case 1:
            let percent = floorf(levelSlider.value - 100)   // -100...100
            let value = Int32(min(65535, 655.36 * percent)) // -65536...65535
            sendGenericDeltaSetMessage(level: value)
        case 2:
            let percent = floorf(levelSlider.value - 100)   // -100...100
            let value = Int16(min(32767, 327.68 * percent)) // -32768...32767
            sendGenericMoveSetMessage(level: Int16(value))
        default:
            break
        }
    }
    @IBAction func readTapped(_ sender: UIButton) {
        readGenericLevelState()
    }
    
    // MARK: - Properties
    
    private var steps: UInt8 = 0
    private var stepResolution: StepResolution = .hundredsOfMilliseconds
    private var delay: UInt8 = 0
    
    // MARK: - Implementation
    
    override func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, from source: Address) -> Bool {
        switch message {
        case let status as GenericLevelStatus:
            let level = floorf(0.1 + (Float(status.level) + 32768.0) / 655.35)
            currentStatusLabel.text = "\(Int(level))%"
            if let targetLevel = status.targetLevel, let remainingTime = status.remainingTime {
                let level = floorf(0.1 + (Float(targetLevel) + 32768.0) / 655.35)
                if remainingTime.isKnown {
                    targetStatusLabel.text = "\(Int(level))% in \(remainingTime.interval) sec"
                } else {
                    targetStatusLabel.text = "\(Int(level))% in unknown time"
                }
            } else {
                targetStatusLabel.text = "N/A"
            }
            
        default:
            break
        }
        return false
    }
    
    override func meshNetwork(_ meshNetwork: MeshNetwork, didDeliverMessage message: MeshMessage, to destination: Address) -> Bool {
        // For acknowledged messages wait for the Acknowledgement Message.
        return acknowledgmentSwitch.isOn
    }
}

private extension GenericLevelViewCell {
    
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
    
    /// Sends Generic Level Set message, either acknowledged or not, depending
    /// on the switch position, with or without the Transition Time settings.
    ///
    /// - parameter level: The target level of Generic Level state.
    func sendGenericLevelSetMessage(level: Int16) {
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
                message = GenericLevelSet(level: level)
            } else {
                let transitionTime = TransitionTime(steps: steps, stepResolution: stepResolution)
                message = GenericLevelSet(level: level, transitionTime: transitionTime, delay: delay)
            }
        } else {
            if defaultTransitionSettingsSwitch.isOn {
                message = GenericLevelSetUnacknowledged(level: level)
            } else {
                let transitionTime = TransitionTime(steps: steps, stepResolution: stepResolution)
                message = GenericLevelSetUnacknowledged(level: level, transitionTime: transitionTime, delay: delay)
            }
        }
        
        delegate?.send(message, description: "Sending Level Set...")
    }
    
    /// Sends Generic Delta Set message, either acknowledged or not, depending
    /// on the switch position, with or without the Transition Time settings.
    ///
    /// - parameter level: The relative level of Generic Level state.
    func sendGenericDeltaSetMessage(level: Int32) {
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
                message = GenericDeltaSet(level: level)
            } else {
                let transitionTime = TransitionTime(steps: steps, stepResolution: stepResolution)
                message = GenericDeltaSet(level: level, transitionTime: transitionTime, delay: delay)
            }
        } else {
            if defaultTransitionSettingsSwitch.isOn {
                message = GenericDeltaSetUnacknowledged(level: level)
            } else {
                let transitionTime = TransitionTime(steps: steps, stepResolution: stepResolution)
                message = GenericDeltaSetUnacknowledged(level: level, transitionTime: transitionTime, delay: delay)
            }
        }
        
        delegate?.send(message, description: "Sending Delta Set...")
    }
    
    /// Sends Generic Move Set message, either acknowledged or not, depending
    /// on the switch position, with or without the Transition Time settings.
    ///
    /// - parameter level: The Delta Level step to calculate Move speed for
    ///                    the Generic Level state.
    func sendGenericMoveSetMessage(level: Int16) {
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
                message = GenericMoveSet(deltaLevel: level)
            } else {
                let transitionTime = TransitionTime(steps: steps, stepResolution: stepResolution)
                message = GenericMoveSet(deltaLevel: level, transitionTime: transitionTime, delay: delay)
            }
        } else {
            if defaultTransitionSettingsSwitch.isOn {
                message = GenericMoveSetUnacknowledged(deltaLevel: level)
            } else {
                let transitionTime = TransitionTime(steps: steps, stepResolution: stepResolution)
                message = GenericMoveSetUnacknowledged(deltaLevel: level, transitionTime: transitionTime, delay: delay)
            }
        }
        
        delegate?.send(message, description: "Sending Move Set...")
    }
    
    /// Sends Generic Level Get message.
    func readGenericLevelState() {
        guard !model.boundApplicationKeys.isEmpty else {
            parentViewController?.presentAlert(
                title: "Bound key required",
                message: "Bind at least one Application Key before sending the message.")
            return
        }
        
        delegate?.send(GenericLevelGet(), description: "Reading state...")
    }
}
