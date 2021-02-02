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

protocol HeartbeatSubscriptionPeriodDelegate {
    func periodDidChange(_ periodLog: UInt8)
}

class HeartbeatSubscriptionPeriodCell: UITableViewCell {
    
    // MARK: - Outlets & Actions

    @IBAction func periodDidChange(_ sender: UISlider) {
        periodSelected(sender.value)
    }
    
    @IBOutlet weak var periodSlider: UISlider!
    @IBOutlet weak var periodLabel: UILabel!

    // MARK: - Properties
    
    // The periodLog property starts from 1, as 0 would disable subscriptions.
    var periodLog: UInt8 = 1 {
        didSet {
            periodSlider.value = Float(periodLog - 1)
            periodLabel.text = periodLog.periodString
        }
    }
    var delegate: HeartbeatSubscriptionPeriodDelegate?

    // MARK: - Implementation
    
    private func periodSelected(_ value: Float) {
        periodLog = UInt8(value + 1)
        delegate?.periodDidChange(periodLog)
    }
}

private extension UInt8 {
    
    var periodString: String {
        assert(self > 0)
        let value = self < 0x11 ? Int(pow(2.0, Double(self - 1))) : 0xFFFF
        if value / 3600 > 0 {
            return "\(value / 3600) h \((value % 3600) / 60) min \(value % 60) sec"
        }
        if value / 60 > 0 {
            return "\(value / 60) min \(value % 60) sec"
        }
        if value == 1 {
            return "1 second"
        }
        return "\(value) seconds"
    }
    
}
