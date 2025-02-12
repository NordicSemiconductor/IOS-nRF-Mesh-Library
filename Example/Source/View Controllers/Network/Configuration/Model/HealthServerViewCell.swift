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
import NordicMesh

class HealthServerViewCell: ModelViewCell, UITextFieldDelegate {
    
    @IBOutlet weak var attentionTimerSlider: UISlider!
    @IBAction func attentionTimerDidChange(_ sender: UISlider) {
        let value = sender.value
        attentionTimerLabel.text = "\(Int(value)) sec"
    }
    @IBOutlet weak var attentionTimerLabel: UILabel!
    @IBOutlet weak var attentionTimerAckSwitch: UISwitch!
    @IBAction func setAttentionTimer(_ sender: UIButton) {
        let value = UInt8(attentionTimerSlider.value)
        setAttentionTimer(value)
    }
    
    @IBOutlet weak var currentAttentionTimerValue: UILabel!
    @IBAction func getAttentionTimer(_ sender: UIButton) {
        readAttentionTimerDuration()
    }
    
    @IBOutlet weak var periodSlider: UISlider!
    @IBAction func periodDidChange(_ sender: UISlider) {
        let value = sender.value
        periodLabel.text = "\(pow(2, Int(value)))"
    }
    @IBOutlet weak var periodLabel: UILabel!
    @IBOutlet weak var periodAckSwitch: UISwitch!
    @IBAction func setPeriod(_ sender: UIButton) {
        let value = UInt8(periodSlider.value)
        setPeriod(value)
    }
    
    @IBOutlet weak var periodValue: UILabel!
    @IBAction func getPeriod(_ sender: UIButton) {
        readPeriod()
    }
    
    @IBOutlet weak var testIdField: UITextField!
    @IBOutlet weak var testCompanyIdField: UITextField!
    @IBOutlet weak var testAckSwitch: UISwitch!
    @IBAction func startTest(_ sender: UIButton) {
        startTest()
    }
    
    @IBOutlet weak var companyIdField: UITextField!
    @IBAction func getFaults(_ sender: UIButton) {
        readFaults()
    }
    @IBAction func clearFaults(_ sender: UIButton) {
        clearFaults()
    }
    @IBOutlet weak var mostRecentTestId: UILabel!
    
    override func reload(using model: Model) {
        let companyIdString = model.companyIdentifier?.hex ??
                              model.parentElement?.parentNode?.companyIdentifier?.hex ??
                              UInt16.nordicSemiconductorCompanyId.hex
        if companyIdField.text?.isEmpty ?? true {
            companyIdField.text = companyIdString
        }
        if testCompanyIdField.text?.isEmpty ?? true {
            testCompanyIdField.text = companyIdString
        }
    }
    
    override func startRefreshing() -> Bool {
        readAttentionTimerDuration()
        return true
    }
    
    override func supports(_ messageType: any MeshMessage.Type) -> Bool {
        return messageType == HealthPeriodStatus.self
            || messageType == HealthAttentionStatus.self
            || messageType == HealthFaultStatus.self
    }
    
    override func meshNetworkManager(_ manager: MeshNetworkManager,
                                     didReceiveMessage message: any MeshMessage,
                                     sentFrom source: Address, to destination: MeshAddress) -> Bool {
        switch message {
            
        case let status as HealthAttentionStatus:
            currentAttentionTimerValue.text = "\(status.attentionTimer) sec"
            if delegate?.isRefreshing ?? false {
                readPeriod()
                return true
            }
            return false
            
        case let status as HealthPeriodStatus:
            periodValue.text = "\(pow(2, Int(status.fastPeriodDivisor)))"
            if delegate?.isRefreshing ?? false {
                return readFaults()
            }
            return false
            
        case let status as HealthFaultStatus:
            mostRecentTestId.text = "\(status.testId)"
            return false
            
        default:
            fatalError()
        }
    }
}

private extension HealthServerViewCell {
    
    func readAttentionTimerDuration() {
        let message = HealthAttentionGet()
        delegate?.send(message, description: "Reading Attention Timer...")
    }
    
    func setAttentionTimer(_ value: UInt8) {
        let duration = TimeInterval(value)
        if attentionTimerAckSwitch.isOn {
            let request = HealthAttentionSet(duration)
            delegate?.send(request, description: "Setting Attention Timer...")
        } else {
            let request = HealthAttentionSetUnacknowledged(duration)
            delegate?.send(request, description: "Setting Attention Timer...")
        }
    }
    
    func readPeriod() {
        let message = HealthPeriodGet()
        delegate?.send(message, description: "Reading Fast Period Divider...")
    }
    
    func setPeriod(_ value: UInt8) {
        if periodAckSwitch.isOn {
            let request = HealthPeriodSet(fastPeriodDivisor: value)
            delegate?.send(request, description: "Setting Fast Period Divider...")
        } else {
            let request = HealthPeriodSetUnacknowledged(fastPeriodDivisor: value)
            delegate?.send(request, description: "Setting Fast Period Divider...")
        }
    }
    
    func startTest() {
        guard let companyId = UInt16(testCompanyIdField.text!, radix: 16),
              let testId = UInt8(testIdField.text!) else {
            return
        }
        if testAckSwitch.isOn {
            let message = HealthFaultTest(testId: testId, for: companyId)
            delegate?.send(message, description: "Starting Test...")
        } else {
            let message = HealthFaultTestUnacknowledged(testId: testId, for: companyId)
            delegate?.send(message, description: "Starting Test...")
        }
    }
    
    @discardableResult
    func readFaults() -> Bool {
        guard let companyId = UInt16(companyIdField.text!, radix: 16) else {
            return false
        }
        let message = HealthFaultGet(for: companyId)
        delegate?.send(message, description: "Reading Faults...")
        return true
    }
    
    func clearFaults() {
        guard let companyId = UInt16(companyIdField.text!, radix: 16) else {
            return
        }
        let message = HealthFaultClear(for: companyId)
        delegate?.send(message, description: "Clearing Faults...")
        return
    }
    
}
