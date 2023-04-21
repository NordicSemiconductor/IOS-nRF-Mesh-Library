/*
* Copyright (c) 2023, Nordic Semiconductor
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

@IBDesignable
class MulticolorProgressView: UIView {
    
    @IBInspectable var successColor: UIColor = .green
    @IBInspectable var failColor: UIColor = .nordicRed
    @IBInspectable var skippedColor: UIColor = .nordicFall
    
    private var max: Int = 0
    private var success: Int = 0
    private var fail: Int = 0
    private var skipped: Int = 0
    
    func setMax(_ max: Int) {
        self.max = max
    }
    
    func addSuccess() {
        self.success += 1
        setNeedsDisplay()
    }
    
    func addFail() {
        self.fail += 1
        setNeedsDisplay()
    }
    
    func addSkipped() {
        self.skipped += 1
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        // Draw background.
        context.setFillColor(backgroundColor?.cgColor ?? UIColor.nordicLightGray.cgColor)
        context.fill(bounds)
        
        // Draw successes.
        let successWidth = bounds.width * CGFloat(success) / CGFloat(max)
        context.setFillColor(successColor.cgColor)
        context.fill(CGRect(x: bounds.minX, y: bounds.minY, width: successWidth, height: bounds.height))
        
        // Draw failures.
        let failWidth = bounds.width * CGFloat(fail) / CGFloat(max)
        context.setFillColor(failColor.cgColor)
        context.fill(CGRect(x: successWidth, y: bounds.minY, width: failWidth, height: bounds.height))
        
        // Draw skipped.
        let skippedWidth = bounds.width * CGFloat(skipped) / CGFloat(max)
        context.setFillColor(skippedColor.cgColor)
        context.fill(CGRect(x: successWidth + failWidth, y: bounds.minY, width: skippedWidth, height: bounds.height))
    }

}
