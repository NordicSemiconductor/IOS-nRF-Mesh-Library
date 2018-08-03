//
//  ModelPublicationConfigurationTableViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 02/08/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

enum PublishPeriodResolution: UInt8 {
    case hundredsOfMilliseconds = 0x00
    case seconds                = 0x01
    case tensOfSeconds          = 0x02
    case tensOfMinutes          = 0x03
    
    func description() -> String {
        switch self {
        case .hundredsOfMilliseconds:
            return "100s of Milliseconds"
        case .seconds:
            return "seconds"
        case .tensOfSeconds:
            return "10s of Seconds"
        case .tensOfMinutes:
            return "10s of Minutes"
        }
    }
}

class ModelPublicationConfigurationTableViewController: UITableViewController, UITextFieldDelegate {
    
    // MARK: - Properties
    var publicationAddress: Data = Data([0x00, 0x00])
    var appKeyIndex: UInt8 = 0
    var credentialFlag: Bool = false
    var ttl: UInt8 = 0xFF
    var publishPeriodSteps: UInt8 = 0x00 //Disabled
    var publishPeriodResolution: PublishPeriodResolution = .hundredsOfMilliseconds
    var publishRetransmission = 0x00

    //Input validation
    var currentMinLength: Int?
    var currentMaxLength: Int?
    var currentSaveACtion: UIAlertAction?
    
    // MARK: - Outlets and actions
    
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
    func handleApplyButtonTapped() {
        
    }
    func handleRemovePublicationRowTapped() {
        
    }
    
    //MARK: - Row handlers, to aviod complexity in didSelectRow method
    func handleRowTappedInPublicationSection(_ aRow: Int) {
        self.presentInputAlert(withTitle: "Publication Address", message: "Enter desired publication address", placeHolder: "0xCEEF", minLength: 4, maxLength: 4) { (anAddress) in
            if let anAddress = anAddress {
                print("Selected publication address: \(anAddress)")
            } else {
                print("Addres not selected, NOOP")
            }
        }
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
        if aRow == 0 {
            self.presentInputAlert(withTitle: "Publication Period Steps", message: "Enter desidred number of steps for publication period", placeHolder: "3", minLength: 1, maxLength: 4) { (steps) in
                if let steps = steps {
                    print("Selected \(steps) steps")
                } else {
                    print("None selected")
                }
            }
        }
        if aRow == 1 {
            self.presentSelectionInput(withTitle: "Resolution", message: "Select desired resolution for publish period", andSelectionContent: [
                "100s of Milliseconds",
                "Seconds",
                "10s of Seconds",
                "10s of Minutes"]) { (aResolution) in
                    guard aResolution != nil else {
                        print("No value set")
                        return
                    }
                    
                    if let resolution = PublishPeriodResolution(rawValue: UInt8(aResolution!)) {
                        print("Selected resolution: \(resolution.description())")
                    } else {
                        print("Unknown resolution, NOOP")
                    }
            }
        }
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
    
    //MARK: - Input Alert view
    // MARK: - Input Alerts
    func presentSelectionInput(withTitle aTitle: String, message aMessage: String, andSelectionContent someContent: [String], andCompletion aCompletionHandler: @escaping (Int?) -> Void) {
        let inputAlertView = UIAlertController(title: aTitle,
                                               message: aMessage,
                                               preferredStyle: .actionSheet)
        
        for anItem in someContent {
            let aSelection = UIAlertAction(title: anItem, style: .default) { (_) in
                aCompletionHandler(someContent.index(of: anItem))
            }
            inputAlertView.addAction(aSelection)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            DispatchQueue.main.async {
                aCompletionHandler(nil)
            }
        }
        inputAlertView.addAction(cancelAction)
        present(inputAlertView, animated: true, completion: nil)

    }
    
    func presentInputAlert(withTitle aTitle: String, message aMessage: String, placeHolder aPlaceHolder: String, minLength: Int, maxLength: Int, andCompletion aCompletionHandler : @escaping (String?) -> Void) {
        let inputAlertView = UIAlertController(title: aTitle,
                                               message: aMessage,
                                               preferredStyle: .alert)
        inputAlertView.addTextField { (aTextField) in
            aTextField.keyboardType = UIKeyboardType.alphabet
            aTextField.returnKeyType = .done
            aTextField.delegate = self
            aTextField.clearButtonMode = UITextFieldViewMode.whileEditing
            self.currentMinLength = minLength
            self.currentMaxLength = maxLength
            //Give a placeholder that shows this upcoming key index
            aTextField.placeholder = aPlaceHolder
        }
        
        let addAction = UIAlertAction(title: "Set", style: .default) { (_) in
            DispatchQueue.main.async {
                if var text = inputAlertView.textFields![0].text {
                    if text.lowercased().contains("0x") {
                        //0x is just a formatting style and shouldn't count as the actual data
                        text = text.lowercased().replacingOccurrences(of: "0x", with: "")
                    }
                    if text.count <= minLength && text.count >= maxLength {
                        aCompletionHandler(text)
                    } else {
                        aCompletionHandler(nil)
                    }
                } else {
                    aCompletionHandler(nil)
                }
            }
            self.currentSaveACtion = nil
            self.currentMinLength = nil
            self.currentMaxLength = nil
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            DispatchQueue.main.async {
                aCompletionHandler(nil)
            }
            self.currentSaveACtion = nil
            self.currentMinLength = nil
            self.currentMaxLength = nil
        }
        inputAlertView.addAction(addAction)
        inputAlertView.addAction(cancelAction)
        self.currentSaveACtion = addAction
        present(inputAlertView, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard textField.text != nil else {
            return false
        }
        let currentString = self.stripHexFormattingFromString(textField.text! as NSString)
        let currentTextLength = currentString.length
        if currentTextLength >= currentMinLength! && currentTextLength <= currentMaxLength! {
            return true
        } else {
            return false
        }
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var shouldReplace: Bool = false
        if string == "" {
            shouldReplace = true
        } else {
            if let values = string.data(using: .utf8) {
                shouldReplace = true
                for aValue in values {
                    //Only allow HexaDecimal values 0->9, a->f and A->F or x
                    shouldReplace = shouldReplace && (aValue == 120 || aValue >= 48 && aValue <= 57) || (aValue >= 65 && aValue <= 70) || (aValue >= 97 && aValue <= 102)
                }
            } else {
                shouldReplace = false
            }
        }

        var currentString = textField.text! as NSString
        currentString = self.stripHexFormattingFromString(currentString.replacingCharacters(in: range, with: string) as NSString)
        let currentTextLength = currentString.length
        if currentTextLength >= currentMinLength! && currentTextLength <= currentMaxLength! {
            textField.textColor = .black
            self.currentSaveACtion?.isEnabled = true
        } else {
            textField.textColor = .red
            self.currentSaveACtion?.isEnabled = false
        }
        return shouldReplace
    }
    
    private func stripHexFormattingFromString(_ aString : NSString) -> NSString {
        if aString.lowercased.contains("0x") {
            //0x is just a formatting style and shouldn't count as the actual data
            return (aString.lowercased.replacingOccurrences(of: "0x", with: "")).uppercased() as NSString
        } else {
            return aString.uppercased as NSString
        }
    }
}
