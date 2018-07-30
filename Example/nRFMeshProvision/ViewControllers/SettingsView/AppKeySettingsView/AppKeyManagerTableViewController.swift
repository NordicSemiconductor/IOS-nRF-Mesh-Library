//
//  AppKeyManagerTableViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 04/04/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class AppKeyManagerTableViewController: UITableViewController, UITextFieldDelegate {

    // MARK: - Properties
    private var meshState: MeshStateManager!
    private var appKeyNameInputTextField: UITextField?
    private var appKeyValueInputTextField: UITextField?

    // MARK: - Outlets and actions
    @IBAction func addKeyTapped(_ sender: Any) {
        handleGenerateNewAppKeyButtonTapped()
    }
    @IBOutlet weak var noKeysView: UIView!
    @IBOutlet weak var addKey: UIBarButtonItem!

    // MARK: - Implementation
    public func setMeshState(_ aState: MeshStateManager) {
        meshState = aState
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if !self.navigationItem.rightBarButtonItems!.contains(self.editButtonItem) {
            self.navigationItem.rightBarButtonItems!.append(self.editButtonItem)
        }
    }

    func generateNewAppKey() -> Data {
        let helper = OpenSSLHelper()
        let newKey = helper.generateRandom()
        return newKey!
    }

    func storeKeyWithName(_ aKeyName: String, withData someKeyData: Data) {
        self.meshState.state().appKeys.append([aKeyName: someKeyData])
        self.meshState.saveState()
        tableView.reloadData()
    }

    func handleGenerateNewAppKeyButtonTapped() {
        presentAppKeyAddAlert(withCompletion: { (aKeyName, aKeyData) in
            if let keyName = aKeyName {
                self.storeKeyWithName(keyName, withData: aKeyData)
            } else {
                print("Cancelled")
            }
        })
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Configured Keys"
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = meshState.state().appKeys.count
        self.noKeysView.isHidden = (count > 0)
        return count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AppKeyCell", for: indexPath)
        let keyValue = meshState.state().appKeys[indexPath.row]
        cell.textLabel?.text = keyValue.keys.first!
        cell.detailTextLabel?.text = "0x\(keyValue.values.first!.hexString())"
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let keyTitle = tableView.cellForRow(at: indexPath)?.textLabel?.text
        let keyData = tableView.cellForRow(at: indexPath)?.detailTextLabel?.text
        presentAppKeyAddAlert(keyTitle!, body: keyData!)
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCellEditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            meshState.state().appKeys.remove(at: indexPath.row)
            meshState.saveState()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == appKeyNameInputTextField {
            appKeyValueInputTextField?.becomeFirstResponder()
            return false
        }else{
            textField.resignFirstResponder()
            return true
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == appKeyValueInputTextField {
            if string == "" {
                return true
            } else {
                if let values = string.data(using: .utf8) {
                    var shouldReturn = true
                    for aValue in values {
                        //Only allow HexaDecimal values 0->9, a->f and A->F or x
                        shouldReturn = shouldReturn && (aValue == 120 || aValue >= 48 && aValue <= 57) || (aValue >= 65 && aValue <= 70) || (aValue >= 97 && aValue <= 102)
                    }
                    return shouldReturn
                } else {
                    return false
                }
            }
        } else {
            return true
        }
    }
    // MARK: - Alert helpers
    func presentAppKeyAddAlert(withCompletion aCompletionHandler : @escaping (String?, Data) -> Void) {
        let inputAlertView = UIAlertController(title: "New key",
                                               message: "Enter a friendly name and value, additionally, the key can be generated automatically.",
                                               preferredStyle: .alert)
        inputAlertView.addTextField { (aTextField) in
            self.appKeyNameInputTextField = aTextField
            aTextField.keyboardType = UIKeyboardType.alphabet
            aTextField.returnKeyType = .next
            aTextField.delegate = self
            aTextField.clearButtonMode = .whileEditing
            //Give a placeholder that shows this upcoming key index
            aTextField.placeholder = "Enter a key name"
        }
        inputAlertView.addTextField { (aTextField) in
            self.appKeyValueInputTextField = aTextField
            aTextField.keyboardType = UIKeyboardType.alphabet
            aTextField.returnKeyType = .done
            aTextField.delegate = self
            aTextField.clearButtonMode = .whileEditing
            aTextField.placeholder = "Paste value or tap \"Generate\""
        }

        let generateAction = UIAlertAction(title: "Generate & Save", style: .default) { (_) in
            if let newKey = OpenSSLHelper().generateRandom() {
                self.appKeyValueInputTextField?.text = "0x\(newKey.hexString())"
                if let text = self.appKeyNameInputTextField!.text {
                    if text.count > 0 {
                        aCompletionHandler(text, newKey)
                    } else {
                        let keyName = "AppKey \(self.meshState.state().appKeys.count + 1)"
                        aCompletionHandler(keyName, newKey)
                    }
                }
            }
        }

        let createAction = UIAlertAction(title: "Save", style: .default) { (_) in
            DispatchQueue.main.async {
                //Convert AppKey hex string to Data object
                var keyBytes: Data? = nil
                if var appKeyValue = self.appKeyValueInputTextField!.text {
                    if appKeyValue.contains("0x") {
                        appKeyValue = appKeyValue.replacingOccurrences(of: "0x", with: "")
                    }
                    if let keyValueBytes = Data.init(hexString: appKeyValue) {
                        if keyValueBytes.count == 16 {
                            keyBytes = keyValueBytes
                        }
                    }
                }
                
                if keyBytes != nil {
                    if let text = self.appKeyNameInputTextField!.text {
                        if text.count > 0 {
                            aCompletionHandler(text, keyBytes!)
                        } else {
                            let keyName = "AppKey \(self.meshState.state().appKeys.count + 1)"
                            aCompletionHandler(keyName, keyBytes!)
                        }
                    }
                } else {
                    aCompletionHandler(nil, Data())
                }
            }
        }

        let cancelACtion = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            DispatchQueue.main.async {
                aCompletionHandler(nil, Data())
            }
        }

        inputAlertView.addAction(createAction)
        inputAlertView.addAction(generateAction)
        inputAlertView.addAction(cancelACtion)
        present(inputAlertView, animated: true, completion: nil)
    }

    func presentAppKeyAddAlert(_ aTitle: String,
                            body aBody: String) {
        let inputAlertView = UIAlertController(title: aTitle, message: aBody, preferredStyle: .alert)
        let copyAction = UIAlertAction(title: "Copy to clipboard", style: .default) { (_) in
            let timestamp = DateFormatter.localizedString(from: Date(),
                                                          dateStyle: DateFormatter.Style.short,
                                                          timeStyle: DateFormatter.Style.medium)
            let exportedString = """
            AppKey name: \(aTitle)
            Key: \(aBody)
            Network name: \(self.meshState.meshState.name)
            Exported on: \(timestamp)
            """

            UIPasteboard.general.string = exportedString
            self.dismiss(animated: true, completion: nil)
        }

        let doneAction = UIAlertAction(title: "Done", style: .cancel) { (_) in
            self.dismiss(animated: true, completion: nil)
        }

        inputAlertView.addAction(copyAction)
        inputAlertView.addAction(doneAction)
        present(inputAlertView, animated: true, completion: nil)
    }
}
