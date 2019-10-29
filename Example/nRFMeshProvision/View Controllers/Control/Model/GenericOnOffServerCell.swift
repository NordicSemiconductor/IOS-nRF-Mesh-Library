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

class GenericOnOffServerCell: BaseModelControlCell<GenericOnOffServerDelegate> {
    
    @IBOutlet weak var icon: UIImageView!
    
    override func setup(_ model: GenericOnOffServerDelegate?) {
        icon.tintColor = .nordicSun
        icon.tintAdjustmentMode = .dimmed
        
        model?.observe { [weak self] state in
            guard let self = self else { return }
            self.icon.tintAdjustmentMode = state.value ? .normal : .dimmed
            if let transition = state.transition {
                let delay = max(transition.startTime.timeIntervalSinceNow, 0.0)
                self.icon.layer.removeAllAnimations()
                UIView.animate(withDuration: transition.remainingTime - delay,
                               delay: delay,
                               animations: { [weak self] in
                    guard let self = self else { return }
                    self.icon.tintAdjustmentMode = transition.targetValue ? .normal : .dimmed
                })
            }
        }
    }
}
