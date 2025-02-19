/*
* Copyright (c) 2024, Nordic Semiconductor
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
import NordicMesh

class LightLCViewCell: ModelViewCell {
    
    // MARK: - Light LC Mode
    
    @IBOutlet weak var modeAckSwitch: UISwitch!
    @IBOutlet weak var modeOnButton: UIButton!
    @IBAction func modeOnTapped(_ sender: UIButton) {
        setLightLCMode(on: true)
    }
    @IBOutlet weak var modeOffButton: UIButton!
    @IBAction func modeOffTapped(_ sender: UIButton) {
        setLightLCMode(on: false)
    }
    
    @IBOutlet weak var modeStatus: UILabel!
    @IBOutlet weak var modeReadModeButton: UIButton!
    @IBAction func modeReadTapped(_ sender: UIButton) {
        readLightLCMode()
    }
    
    // MARK: - Light LC Occupancy Mode
    
    @IBOutlet weak var occupancyModeAckSwitch: UISwitch!
    @IBOutlet weak var occupancyModeOnButton: UIButton!
    @IBAction func occupancyModeOnTapped(_ sender: UIButton) {
        setLightLCOccupancyMode(on: true)
    }
    @IBOutlet weak var occupancyModeOffButton: UIButton!
    @IBAction func occupancyModeOffTapped(_ sender: UIButton) {
        setLightLCOccupancyMode(on: false)
    }
    
    @IBOutlet weak var occupancyModeStatus: UILabel!
    @IBOutlet weak var occupancyModeReadButton: UIButton!
    @IBAction func occupancyModeReadTapped(_ sender: UIButton) {
        readLightLCOccupancyMode()
    }
    
    // MARK: - Light LC OnOff
    
    @IBOutlet weak var defaultTransitionTimeSwitch: UISwitch!
    @IBAction func defaultTransitionTimeModeChanged(_ sender: UISwitch) {
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
    @IBAction func transitionTimeDidChange(_ sender: UISlider) {
        transitionTimeSelected(sender.value)
    }
    @IBOutlet weak var transitionTimeLabel: UILabel!
    
    @IBOutlet weak var delaySlider: UISlider!
    @IBAction func delayDidChange(_ sender: UISlider) {
        delaySelected(sender.value)
    }
    @IBOutlet weak var delayLabel: UILabel!
    
    @IBOutlet weak var lightOnOffAckSwitch: UISwitch!
    
    @IBOutlet weak var lightOnButton: UIButton!
    @IBAction func lightOnTapped(_ sender: UIButton) {
        setLightLCLightOnOffState(turnOn: true)
    }
    @IBOutlet weak var lightOffButton: UIButton!
    @IBAction func lightOffTapped(_ sender: UIButton) {
        setLightLCLightOnOffState(turnOn: false)
    }
    
    @IBOutlet weak var currentLightStatusLabel: UILabel!
    @IBOutlet weak var targetLightStatusLabel: UILabel!
    
    @IBOutlet weak var lightStatusReadButton: UIButton!
    @IBAction func lightStatusReadTapped(_ sender: UIButton) {
        readLightLCLightOnOffState()
    }
    
    // MARK: Properties
    
    private var steps: UInt8 = 0
    private var stepResolution: StepResolution = .hundredsOfMilliseconds
    private var delay: UInt8 = 0
    
    // MARK: - Implementation
    
    override func reload(using model: Model) {
        let localProvisioner = MeshNetworkManager.instance.meshNetwork?.localProvisioner
        let isEnabled = localProvisioner?.hasConfigurationCapabilities ?? false
        
        modeAckSwitch.isEnabled = isEnabled
        modeOnButton.isEnabled = isEnabled
        modeOffButton.isEnabled = isEnabled
        modeReadModeButton.isEnabled = isEnabled
        
        occupancyModeAckSwitch.isEnabled = isEnabled
        occupancyModeOnButton.isEnabled = isEnabled
        occupancyModeOffButton.isEnabled = isEnabled
        occupancyModeReadButton.isEnabled = isEnabled
        
        defaultTransitionTimeSwitch.isEnabled = isEnabled
        lightOnOffAckSwitch.isEnabled = isEnabled
        lightOnButton.isEnabled = isEnabled
        lightOffButton.isEnabled = isEnabled
        lightStatusReadButton.isEnabled = isEnabled
    }
    
    override func startRefreshing() -> Bool {
        if !model.boundApplicationKeys.isEmpty {
            readLightLCMode()
            return true
        }
        return false
    }
    
    override func supports(_ messageType: MeshMessage.Type) -> Bool {
        return messageType == LightLCModeStatus.self ||
               messageType == LightLCOccupancyModeStatus.self ||
               messageType == LightLCLightOnOffStatus.self
    }
    
    override func meshNetworkManager(_ manager: MeshNetworkManager,
                                     didReceiveMessage message: MeshMessage,
                                     sentFrom source: Address, to destination: MeshAddress) -> Bool {
        switch message {
        case let status as LightLCModeStatus:
            modeStatus.text = status.controllerStatus ? "ON" : "OFF"
            
            if delegate?.isRefreshing ?? false {
                readLightLCOccupancyMode()
                return true
            }
            return false
            
        case let status as LightLCOccupancyModeStatus:
            occupancyModeStatus.text = status.occupancyMode ? "ON" : "OFF"
            
            if delegate?.isRefreshing ?? false {
                readLightLCLightOnOffState()
                return true
            }
            return false
            
        case let status as LightLCLightOnOffStatus:
            currentLightStatusLabel.text = status.isOn ? "ON" : "OFF"
            if let targetStatus = status.targetState, let remainingTime = status.remainingTime {
                if let interval = remainingTime.interval {
                    targetLightStatusLabel.text = "\(targetStatus ? "ON" : "OFF") in \(interval) sec"
                } else {
                    targetLightStatusLabel.text = "\(targetStatus ? "ON" : "OFF") in unknown time"
                }
            } else {
                targetLightStatusLabel.text = "N/A"
            }
            return false
            
        default:
            fatalError()
        }
    }
}

// MARK: - Light LC Mode Implementation

private extension LightLCViewCell {
    
    func setLightLCMode(on: Bool) {
        guard !model.boundApplicationKeys.isEmpty else {
            parentViewController?.presentAlert(
                title: "Bound key required",
                message: "Bind at least one Application Key before sending the message.")
            return
        }
        
        // Clear the response field.
        modeStatus.text = nil
        
        var message: MeshMessage!
        
        if modeAckSwitch.isOn {
            message = LightLCModeSet(on)
        } else {
            message = LightLCModeSetUnacknowledged(on)
        }
            
        delegate?.send(message, description: "Sending...")
    }
    
    func readLightLCMode() {
        guard !model.boundApplicationKeys.isEmpty else {
            parentViewController?.presentAlert(
                title: "Bound key required",
                message: "Bind at least one Application Key before sending the message.")
            return
        }
        
        delegate?.send(LightLCModeGet(), description: "Reading state...")
    }
    
}

// MARK: - Light LC Occupancy Mode Implementation

private extension LightLCViewCell {
    
    func setLightLCOccupancyMode(on: Bool) {
        guard !model.boundApplicationKeys.isEmpty else {
            parentViewController?.presentAlert(
                title: "Bound key required",
                message: "Bind at least one Application Key before sending the message.")
            return
        }
        
        // Clear the response field.
        occupancyModeStatus.text = nil
        
        var message: MeshMessage!
        
        if occupancyModeAckSwitch.isOn {
            message = LightLCOccupancyModeSet(on)
        } else {
            message = LightLCOccupancyModeSetUnacknowledged(on)
        }
            
        delegate?.send(message, description: "Sending...")
    }
    
    func readLightLCOccupancyMode() {
        guard !model.boundApplicationKeys.isEmpty else {
            parentViewController?.presentAlert(
                title: "Bound key required",
                message: "Bind at least one Application Key before sending the message.")
            return
        }
        
        delegate?.send(LightLCOccupancyModeGet(), description: "Reading state...")
    }
    
}

// MARK: - Light LC OnOff Implementation

private extension LightLCViewCell {
    
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
    
    func setLightLCLightOnOffState(turnOn: Bool) {
        guard !model.boundApplicationKeys.isEmpty else {
            parentViewController?.presentAlert(
                title: "Bound key required",
                message: "Bind at least one Application Key before sending the message.")
            return
        }
        
        // Clear the response fields.
        currentLightStatusLabel.text = nil
        targetLightStatusLabel.text = nil
        
        var message: MeshMessage!
        
        if lightOnOffAckSwitch.isOn {
            if defaultTransitionTimeSwitch.isOn {
                message = LightLCLightOnOffSet(turnOn)
            } else {
                let transitionTime = TransitionTime(steps: steps, stepResolution: stepResolution)
                message = LightLCLightOnOffSet(turnOn, transitionTime: transitionTime, delay: delay)
            }
        } else {
            if defaultTransitionTimeSwitch.isOn {
                message = LightLCLightOnOffSetUnacknowledged(turnOn)
            } else {
                let transitionTime = TransitionTime(steps: steps, stepResolution: stepResolution)
                message = LightLCLightOnOffSetUnacknowledged(turnOn, transitionTime: transitionTime, delay: delay)
            }
        }
            
        delegate?.send(message, description: "Sending...")
    }
    
    func readLightLCLightOnOffState() {
        guard !model.boundApplicationKeys.isEmpty else {
            parentViewController?.presentAlert(
                title: "Bound key required",
                message: "Bind at least one Application Key before sending the message.")
            return
        }
        
        delegate?.send(LightLCLightOnOffGet(), description: "Reading state...")
    }
}
