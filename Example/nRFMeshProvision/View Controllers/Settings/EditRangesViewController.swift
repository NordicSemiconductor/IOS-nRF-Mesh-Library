//
//  EditRangesViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 08/04/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class EditRangesViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var rangeSummary: RangeView!
    @IBOutlet weak var lowerBoundLabel: UILabel!
    @IBOutlet weak var upperBoundLabel: UILabel!
    
    // MARK: - Actions
    
    @IBAction func addTapped(_ sender: UIBarButtonItem) {
        showRangeAlert()
    }
    
    // MARK: - View Controller parameters
    
    var bounds: ClosedRange<UInt16>!
    var ranges: [RangeObject]!
    var otherProvisionerRanges: [RangeObject]! = []
    
    override func viewDidLoad() {
        tableView.delegate = self
        tableView.dataSource = self
        
        rangeSummary.setBounds(bounds)
        rangeSummary.addRanges(ranges)
        rangeSummary.addOtherRanges(otherProvisionerRanges)
        lowerBoundLabel.text = bounds.lowerBound.asString()
        upperBoundLabel.text = bounds.upperBound.asString()
    }
    
}

// MARK: - Table View Delegate

extension EditRangesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ranges.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rangeCell", for: indexPath) as! RangeCell
        cell.rangeView.setBounds(bounds)
        let range = ranges[indexPath.row]
        cell.range = range
        cell.otherRanges = ranges.filter({ $0 != range }) + otherProvisionerRanges
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        showRangeAlert(for: indexPath)
    }
}

// MARK: - Private API

extension EditRangesViewController {
    
    func showRangeAlert(for indexPath: IndexPath? = nil) {
        let edit = indexPath != nil
        let title = edit ? "Edit Range" : "New Range"
        let message = "Enter lower and upper bounds as 4-character hexadecimal strings.\nValid range: \(bounds.asString())."
        
        var range: RangeObject? = nil
        if let indexPath = indexPath {
            range = ranges[indexPath.row]
        }
        presentRangeAlert(title: title, message: message, range: range) { newRange in
            guard newRange.isInside(self.bounds) else {
                self.presentAlert(title: "Invalid range", message: "Given range is outside of valid range.")
                return
            }
            
            if let indexPath = indexPath {
                self.ranges.remove(at: indexPath.row)
            }
            self.ranges.append(AddressRange(newRange))
            self.ranges.merge()
            
            self.tableView.reloadData()
            
            self.rangeSummary.clearRanges()
            self.rangeSummary.addRanges(self.ranges)
        }
    }
}
