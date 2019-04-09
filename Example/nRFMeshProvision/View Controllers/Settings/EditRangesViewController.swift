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
    var addressRanges: [AddressRange]?
    var sceneRanges: [SceneRange]?
    var otherProvisionerRanges: [ClosedRange<UInt16>]! = []
    
    override func viewDidLoad() {
        tableView.delegate = self
        tableView.dataSource = self
        
        rangeSummary.setBounds(bounds)
        if let addressRanges = addressRanges {
            rangeSummary.addRanges(addressRanges)
        }
        if let sceneRanges = sceneRanges {
            rangeSummary.addRanges(sceneRanges)
        }
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
        return addressRanges?.count ?? sceneRanges?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rangeCell", for: indexPath) as! RangeCell
        cell.rangeView.setBounds(bounds)
        if let addressRanges = addressRanges {
            let range = addressRanges[indexPath.row]
            cell.range = range.range
            cell.otherRanges = addressRanges.filter({ $0 != range }).map({ $0.range }) + otherProvisionerRanges
        } else {
            let range = sceneRanges![indexPath.row]
            cell.range = range.range
            cell.otherRanges = sceneRanges!.filter({ $0 != range }).map({ $0.range }) + otherProvisionerRanges
        }
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
        
        var range: ClosedRange<UInt16>? = nil
        if let indexPath = indexPath {
            if let addressRanges = addressRanges {
                range = addressRanges[indexPath.row].range
            } else if let sceneRanges = sceneRanges {
                range = sceneRanges[indexPath.row].range
            }
        }
        presentRangeAlert(title: title, message: message, range: range) { newRange in
            guard newRange.isInside(self.bounds) else {
                self.presentAlert(title: "Invalid range", message: "Given range is outside of valid range.")
                return
            }
            
            if let indexPath = indexPath {
                self.addressRanges?.remove(at: indexPath.row)
                self.sceneRanges?.remove(at: indexPath.row)
            }
            self.addressRanges?.append(AddressRange(newRange))
            self.addressRanges?.merge()
            self.sceneRanges?.append(SceneRange(newRange))
            self.sceneRanges?.merge()
            
            self.tableView.reloadData()
            
            self.rangeSummary.clearRanges()
            if let addressRanges = self.addressRanges {
                self.rangeSummary.addRanges(addressRanges)
            }
            if let sceneRanges = self.sceneRanges {
                self.rangeSummary.addRanges(sceneRanges)
            }
        }
    }
}
