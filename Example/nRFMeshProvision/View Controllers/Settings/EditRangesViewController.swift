//
//  EditRangesViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 08/04/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

enum RangeType {
    case unicastAddress
    case groupAddress
    case scene
    
    var validator: Selector {
        switch self {
        case .unicastAddress: return .unicastAddressRequired
        case .groupAddress:   return .groupAddressRequired
        case .scene:          return .sceneRequired
        }
    }
}

protocol EditRangesDelegate {
    /// Method called when user has added, deleted or modified any range.
    ///
    /// - parameter type:   The range type.
    /// - parameter ranges: The new ranges.
    func ranges(ofType type: RangeType, haveChangeTo ranges: [RangeObject])
}

class EditRangesViewController: UIViewController, Editable {
    
    // MARK: - Outlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var rangeSummary: RangeView!
    @IBOutlet weak var lowerBoundLabel: UILabel!
    @IBOutlet weak var upperBoundLabel: UILabel!
    @IBOutlet weak var resolveConflictsFab: UIButton!
    
    // MARK: - Actions
    
    @IBAction func addTapped(_ sender: UIBarButtonItem) {
        presentRangeDialog()
    }
    @IBAction func resolveConflitsTapped(_ sender: UIButton) {
        removeConflictingRanges()
        
        UIView.animate(withDuration: 0.5) {
            self.resolveConflictsFab.alpha = 0
        }
    }
    
    // MARK: - Public parameters
    
    var delegate: EditRangesDelegate?
    var type: RangeType!
    var modified = false
    
    var bounds: ClosedRange<UInt16>!
    var ranges: [RangeObject]!
    var otherProvisionerRanges: [RangeObject]! = []
    
    // MARK: - View Controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setEmptyView(title: "No ranges allocated", message: "Click + to allocate a range.", messageImage: #imageLiteral(resourceName: "baseline-range"))
        
        tableView.delegate = self
        tableView.dataSource = self
        
        rangeSummary.setBounds(bounds)
        rangeSummary.addRanges(ranges)
        rangeSummary.addOtherRanges(otherProvisionerRanges)
        lowerBoundLabel.text = bounds.lowerBound.asString()
        upperBoundLabel.text = bounds.upperBound.asString()
        
        if ranges.isEmpty {
            showEmptyView()
        } else {
            hideEmptyView()
        }
        
        // Show Resolve Conflicts button when some conflicts were found.
        resolveConflictsFab.isHidden = !ranges.overlaps(otherProvisionerRanges)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if modified {
            delegate?.ranges(ofType: type, haveChangeTo: ranges)
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        // This enables the editing mode in the table view.
        tableView.setEditing(editing, animated: animated)
    }
    
}

// MARK: - Table View Delegate

extension EditRangesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return ranges.isEmpty ? 0 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ranges.count
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "Ovelapping ranges merge automatically."
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
        presentRangeDialog(for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            ranges.remove(at: indexPath.row)
            modified = true
            
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            if ranges.isEmpty {
                tableView.deleteSections(IndexSet(integer: 0), with: .fade)
            }
            tableView.endUpdates()
            
            rangeSummary.clearRanges()
            rangeSummary.addRanges(self.ranges)
            
            if ranges.isEmpty {
                showEmptyView()
            }
        }
    }
    
}

// MARK: - Private API

private extension EditRangesViewController {
    
    func presentRangeDialog(for indexPath: IndexPath? = nil) {
        let edit = indexPath != nil
        let title = edit ? "Edit Range" : "New Range"
        let message = "Enter lower and upper bounds as 4-character hexadecimal strings.\nValid range: \(bounds.asString())."
        
        var range: RangeObject? = nil
        if let indexPath = indexPath {
            range = ranges[indexPath.row]
        }
        presentRangeAlert(title: title, message: message, range: range, type: type.validator) { newRange in
            guard newRange.isInside(self.bounds) else {
                self.presentAlert(title: "Invalid range", message: "Given range is outside of valid range.")
                return
            }
            self.modified = true
            
            // When a range was modified, remove the old one.
            if let indexPath = indexPath {
                self.ranges.remove(at: indexPath.row)
            }
            // Add the new range. It will be added to the end, but the `merge()` will sort them again.
            switch self.type! {
            case .unicastAddress, .groupAddress:
                self.ranges.append(AddressRange(newRange))
            case .scene:
                self.ranges.append(SceneRange(newRange))
            }
            // Sort ranges.
            self.ranges.merge()
            
            // And refresh the table view.
            self.tableView.reloadData()
            self.hideEmptyView()
            
            // Update the range summary at the bottom.
            self.rangeSummary.clearRanges()
            self.rangeSummary.addRanges(self.ranges)
            
            self.resolveConflictsFab.isHidden = !self.ranges.overlaps(self.otherProvisionerRanges)
        }
    }
    
    func removeConflictingRanges() {
        // Try removing other Provisioner's ranges form ranges
        // if they are Address Ranges.
        if var addressRanges = ranges as? [AddressRange] {
            otherProvisionerRanges.forEach {
                addressRanges -= $0 as! AddressRange
            }
            ranges = addressRanges
        } else
        // Try removing other Provisioner's ranges form ranges
        // if they are Scene Ranges.
        if var sceneRanges = ranges as? [SceneRange] {
            otherProvisionerRanges.forEach {
                sceneRanges -= $0 as! SceneRange
            }
            ranges = sceneRanges
        }
        modified = true
        
        // Reload views.
        tableView.reloadData()
        if ranges.isEmpty {
            showEmptyView()
        }
        
        rangeSummary.clearRanges()
        rangeSummary.addRanges(ranges)
    }
    
}
