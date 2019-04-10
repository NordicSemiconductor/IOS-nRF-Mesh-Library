//
//  RangeView.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 08/04/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

@IBDesignable
class RangeView: UIView {
    
    @IBInspectable var lowerBound: UInt16 = 0x0001
    @IBInspectable var upperBound: UInt16 = 0xFFFF
    @IBInspectable var rangesColor:      UIColor = UIColor.nordicLake
    @IBInspectable var otherRangesColor: UIColor = UIColor.lightGray
    @IBInspectable var collisionColor:   UIColor = UIColor.nordicRed
    
    private var ranges:      [ClosedRange<UInt16>] = []
    private var otherRanges: [ClosedRange<UInt16>] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
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
        context.setFillColor(UIColor.tableViewBackground.cgColor)
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
    
    /// Returs a CGRect with a region for the given range.
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
