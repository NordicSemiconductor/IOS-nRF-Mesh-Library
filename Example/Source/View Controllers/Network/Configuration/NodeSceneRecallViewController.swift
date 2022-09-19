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

protocol SceneRecallDelegate {
    /// Recalls the given scene.
    ///
    /// - parameters:
    ///   - scene: Scene number to be recalled.
    ///   - transitionTime: Optional transition time.
    ///   - delay: Optional message execution delay in 5 millisecond steps.
    func recallScene(_ scene: SceneNumber, transitionTime: TransitionTime?, delay: UInt8?)
}

class NodeSceneRecallViewController: UITableViewController {
    
    // MARK: - Outlets and Actions
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    @IBAction func recallTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true) {
            self.recallScene()
        }
    }
    
    @IBOutlet weak var modeSwitch: UISwitch!
    @IBOutlet weak var transitionTimeSlider: UISlider!
    @IBOutlet weak var transitionTimeLabel: UILabel!
    @IBOutlet weak var delaySlider: UISlider!
    @IBOutlet weak var delayLabel: UILabel!
    
    @IBAction func modeSwitchDidChange(_ sender: UISwitch) {
        transitionTimeSlider.isEnabled = sender.isOn
        delaySlider.isEnabled = sender.isOn
        
        if sender.isOn {
            transitionTimeSelected(transitionTimeSlider.value)
            delaySelected(delaySlider.value)
        } else {
            transitionTimeLabel.text = "N/A"
            delayLabel.text = "N/A"
        }
    }
    @IBAction func transitionTimeDidChange(_ sender: UISlider) {
        transitionTimeSelected(sender.value)
    }
    @IBAction func delayDidChange(_ sender: UISlider) {
        delaySelected(sender.value)
    }
    
    // MARK: - Properties
    
    var scene: Scene!
    var delegate: SceneRecallDelegate?
    
    // MARK: - Private properties
    
    private var steps: UInt8 = 0
    private var stepResolution: StepResolution = .hundredsOfMilliseconds
    private var delay: UInt8 = 0

    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = scene.name
    }

}

private extension NodeSceneRecallViewController {
    
    func recallScene() {
        if modeSwitch.isOn {
            let transitionTime = TransitionTime(steps: steps, stepResolution: stepResolution)
            delegate?.recallScene(scene.number, transitionTime: transitionTime, delay: delay)
        } else {
            delegate?.recallScene(scene.number, transitionTime: nil, delay: nil)
        }
    }
    
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
    
}
