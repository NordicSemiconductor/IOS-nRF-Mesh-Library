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
        let newKey = generateNewAppKey()
        presentAppKeyNameAlert(withCompletion: { (aKeyName) in
            if let keyName = aKeyName {
                self.storeKeyWithName(keyName, withData: newKey)
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
        presentAppKeyAlert(keyTitle!, body: keyData!)
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
        return true
    }

    // MARK: - Alert helpers
    func presentAppKeyNameAlert(withCompletion aCompletionHandler : @escaping (String?) -> Void) {
        let inputAlertView = UIAlertController(title: "Please give the new key a name",
                                               message: nil,
                                               preferredStyle: .alert)
        inputAlertView.addTextField { (aTextField) in
            aTextField.keyboardType = UIKeyboardType.alphabet
            aTextField.returnKeyType = .done
            aTextField.delegate = self
            aTextField.clearButtonMode = UITextFieldViewMode.whileEditing
            //Give a placeholder that shows this upcoming key index
            aTextField.placeholder = "AppKey \(self.meshState.state().appKeys.count + 1)"
        }

        let createAction = UIAlertAction(title: "Create", style: .default) { (_) in
            DispatchQueue.main.async {
                if let text = inputAlertView.textFields![0].text {
                    if text.count > 0 {
                        aCompletionHandler(text)
                    } else {
                        let keyName = "AppKey \(self.meshState.state().appKeys.count + 1)"
                        aCompletionHandler(keyName)
                    }
                }
            }
        }

        let cancelACtion = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            DispatchQueue.main.async {
                aCompletionHandler(nil)
            }
        }

        inputAlertView.addAction(createAction)
        inputAlertView.addAction(cancelACtion)
        present(inputAlertView, animated: true, completion: nil)
    }

    func presentAppKeyAlert(_ aTitle: String,
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
