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

@IBDesignable
class RangeView: UIView {
    
    @IBInspectable var lowerBound: UInt16 = 0x0001
    @IBInspectable var upperBound: UInt16 = 0xFFFF
    @IBInspectable var rangesColor:      UIColor = UIColor.nordicLake
    @IBInspectable var otherRangesColor: UIColor = UIColor.nordicMediumGray
    @IBInspectable var collisionColor:   UIColor = UIColor.nordicRed
    @IBInspectable var unallocatedColor: UIColor = UIColor.nordicLightGray
    
    private var ranges:      [ClosedRange<UInt16>] = []
    private var otherRanges: [ClosedRange<UInt16>] = []
    
    func setBounds(_ range: ClosedRange<UInt16>) {
        lowerBound = range.lowerBound
        upperBound = range.upperBound
        setNeedsDisplay()
    }
    
    func clearRanges() {
        ranges.removeAll()
        setNeedsDisplay()
    }
    
    func clearOtherRanges() {
        otherRanges.removeAll()
        setNeedsDisplay()
    }
    
    func addRange(_ range: ClosedRange<UInt16>) {
        if range.lowerBound >= lowerBound && range.upperBound <= upperBound {
            ranges.append(range)
            setNeedsDisplay()
        }
    }
    
    func addRanges(_ newRanges: [ClosedRange<UInt16>]) {
        newRanges.forEach { range in
            addRange(range)
        }
    }
    
    func addOtherRange(_ range: ClosedRange<UInt16>) {
        if range.lowerBound >= lowerBound && range.upperBound <= upperBound {
            otherRanges.append(range)
            setNeedsDisplay()
        }
    }
    
    func addOtherRanges(_ newRanges: [ClosedRange<UInt16>]) {
        newRanges.forEach { range in
            addOtherRange(range)
        }
    }

    func addRange(_ range: RangeObject) {
        if range.lowerBound >= lowerBound && range.upperBound <= upperBound {
            ranges.append(range.range)
            setNeedsDisplay()
        }
    }
    
    func addRanges(_ newRanges: [RangeObject]) {
        newRanges.forEach { range in
            addRange(range)
        }
    }
    
    func addOtherRange(_ range: RangeObject) {
        if range.lowerBound >= lowerBound && range.upperBound <= upperBound {
            otherRanges.append(range.range)
            setNeedsDisplay()
        }
    }
    
    func addOtherRanges(_ newRanges: [RangeObject]) {
        newRanges.forEach { range in
            addOtherRange(range)
        }
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        // Draw background
        context.setFillColor(unallocatedColor.cgColor)
        context.fill(bounds)
        
        // Draw ranges
        context.setFillColor(rangesColor.cgColor)
        for range in ranges {
            if range.lowerBound >= lowerBound && range.upperBound <= upperBound {
                context.addRect(region(for: range, in: rect))
            }
        }
        context.fillPath()
        
        // Draw "other" ranges
        context.setFillColor(otherRangesColor.cgColor)
        for range in otherRanges {
            if range.lowerBound >= lowerBound && range.upperBound <= upperBound {
                context.addRect(region(for: range, in: rect))
            }
        }
        context.fillPath()
        
        // Draw collisions
        context.setFillColor(collisionColor.cgColor)
        for range in ranges {
            for other in otherRanges {
                if range.overlaps(other) {
                    let part = range.clamped(to: other)
                    if part.lowerBound >= lowerBound && part.upperBound <= upperBound {
                        context.addRect(region(for: part, in: rect))
                    }
                }
            }
        }
        context.fillPath()
        
        // Draw border
        context.setStrokeColor(UIColor.tableViewSeparator.cgColor)
        context.setLineWidth(0.5)
        context.addRect(rect)
        context.strokePath()
    }
    
    /// Returns a CGRect with a region for the given range.
    ///
    /// - parameter range: The range to calculated the CGRect from.
    /// - parameter rect:  The UIView boundaries.
    private func region(for range: ClosedRange<UInt16>, in rect: CGRect) -> CGRect {
        let unit = rect.width / CGFloat(upperBound - lowerBound)
        let x = CGFloat(range.lowerBound - lowerBound) * unit
        let y = CGFloat(range.upperBound - lowerBound) * unit
        return CGRect(x: x, y: 0, width: y - x, height: rect.height)
    }
}
