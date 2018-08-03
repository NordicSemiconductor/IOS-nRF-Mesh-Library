//
//  ModelPublicationConfigurationTableViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 02/08/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

class ModelPublicationConfigurationTableViewController: UITableViewController {
    
    //MARK: - Outlets and actions
    
    //NavigationBar Items
    @IBOutlet weak var applyButton: UIBarButtonItem!
    @IBAction func applyButtonTapped(_ sender: Any) {
        handleApplyButtonTapped()
    }
    //Address Section
    @IBOutlet weak var publicationAddressLabel: UILabel!
    //Retransmission Section
    @IBOutlet weak var retransmitCountLabel: UILabel!
    @IBOutlet weak var retransmitIntervalStepsLabel: UILabel!
    //Period Section
    @IBOutlet weak var periodStepsLabel: UILabel!
    @IBOutlet weak var periodResolutionLabel: UILabel!
    //AppKeyIndex Section
    @IBOutlet weak var appKeyIndexLabel: UILabel!
    //TTL Section
    @IBOutlet weak var publishTTLLabel: UILabel!
    //Save Section
    @IBOutlet weak var clearPublicationButtonLabel: UILabel!

    //MARK: - Implemetnation
    func handleApplyButtonTapped(){
        
    }
    func handleRemovePublicationRowTapped() {
        
    }
    
    //MARK: - Row handlers, to aviod complexity in didSelectRow method
    func handleRowTappedInPublicationSection(_ aRow: Int) {
        /*Stopped working on setting up the row handlers:
         1 Setup the input popups and validation.
         2 Pre-populate publication settings view with defaults or currently stored data.
         3 Setup the delegate to receive callback from the node configuration view
         4 Update the node configuration view to show the publication settings with the address in a specialized row.
         5 Add a delete button beside the publication settings display view to easily disable publication.
         */
        
    }
    func handleRowTappedInRetransmissionSection(_ aRow: Int) {
        
    }
    func handleRowTappedInPeriodSection(_ aRow: Int) {
        
    }
    func handleRowTappedInAppKeySection(_ aRow: Int) {
        
    }
    func handleRowTappedInTTLSection(_ aRow: Int) {
        
    }
    func handleRowTappedInSaveSection(_ aRow: Int) {
        if aRow == 0 {
            //This is the delete button
            handleRemovePublicationRowTapped()
        }
    }

    //MARK: - UIViewController
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    //MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Immediate deselection before taking action
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
            case 0: self.handleRowTappedInPublicationSection(indexPath.row)
            case 1: self.handleRowTappedInRetransmissionSection(indexPath.row)
            case 2: self.handleRowTappedInPeriodSection(indexPath.row)
            case 3: self.handleRowTappedInAppKeySection(indexPath.row)
            case 4: self.handleRowTappedInTTLSection(indexPath.row)
            case 5: self.handleRowTappedInSaveSection(indexPath.row)
            default:
                break
        }
    }
}
