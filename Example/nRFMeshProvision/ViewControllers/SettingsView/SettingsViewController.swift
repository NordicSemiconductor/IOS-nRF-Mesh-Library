//
//  SettingsViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 06/03/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class SettingsViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Properties
    var meshStateManager: MeshStateManager!
    let reuseIdentifier = "SettingsTableViewCell"
    let sectionTitles = ["Global Settings", "Network Settings", "App keys"]
    let rowTitles   = [["Network Name", "Global TTL"],
                       ["NetKey", "Key index", "Flags", "IVIndex", "Unicast Address"],
                       ["Manage App Keys"]]

    // MARK: - Outlets and actions
    @IBOutlet weak var settingsTable: UITableView!

    // MARK: - Implementaiton
    private func setupProvisioningData() {
        if MeshStateManager.stateExists() {
            meshStateManager = MeshStateManager.restoreState()
        } else {
            let networkKey = generateNewKey()
            let keyIndex = Data([0x00, 0x00])
            let flags = Data([0x00])
            let ivIndex = Data([0x00, 0x00, 0x00, 0x00])
            let unicastAddress = Data([0x01, 0x23])
            let globalTTL: UInt8 = 5
            let networkName = "My Network"
            let appKeys = [["AppKey 1": generateNewKey()],
                           ["AppKey 2": generateNewKey()],
                           ["AppKey 3": generateNewKey()]]
            let state = MeshState(withNodeList: [], netKey: networkKey, keyIndex: keyIndex,
                                  IVIndex: ivIndex, globalTTL: globalTTL, unicastAddress: unicastAddress,
                                  flags: flags, appKeys: appKeys, andName: networkName)
            meshStateManager = MeshStateManager(withState: state)
        }
   }

    private func updateProvisioningDataUI() {
        //Update provisioning Data UI with default values
        settingsTable.reloadData()
    }

    func didSelectNetworkNameCell() {
        presentInputViewWithTitle("Enter a network name", message: "20 charcters",
                                  placeholder: meshStateManager.state().name,
                                  generationEnabled: false) { (aName) -> Void in
                                    if let aName = aName {
                                        if aName.count <= 20 {
                                            self.meshStateManager.state().name = aName
                                            self.updateProvisioningDataUI()
                                        } else {
                                            print("Name must shorter than 20 characters")
                                        }
                                    }
        }
    }
    func didSelectGlobalTTLCell() {
        presentInputViewWithTitle("Enter a TTL value", message: "1 Byte",
                                  placeholder: meshStateManager.state().globalTTL.hexString(),
                                  generationEnabled: false) { (aTTL) -> Void in
                                    if let aTTL = aTTL {
                                        if aTTL.count == 2 {
                                            self.meshStateManager.state().globalTTL = Data(hexString: aTTL)!
                                            self.updateProvisioningDataUI()
                                        } else {
                                            print("TTL must 1 byte")
                                        }
                                    }
        }
   }

    func didSelectAppKeysCell() {
        performSegue(withIdentifier: "showKeyManagerView", sender: nil)
    }

    func didSelectKeyCell() {
        presentInputViewWithTitle("Please enter a Key",
                                  message: "16 Bytes",
                                  placeholder: meshStateManager.state().netKey.hexString(),
                                  generationEnabled: true) { (aKey) -> Void in
                                    if let aKey = aKey {
                                        if aKey.count == 32 {
                                            self.meshStateManager.state().netKey = Data(hexString: aKey)!
                                            self.updateProvisioningDataUI()
                                        } else {
                                            print("Key must be exactly 16 bytes")
                                        }
                                    }
        }
   }

    func didSelectKeyIndexCell() {
        presentInputViewWithTitle("Please enter a Key Index",
                                  message: "2 Bytes",
                                  placeholder: meshStateManager.state().keyIndex.hexString(),
                                  generationEnabled: false) { (aKeyIndex) -> Void in
            if let aKeyIndex = aKeyIndex {
                if aKeyIndex.count == 4 {
                    self.meshStateManager.state().keyIndex = Data(hexString: aKeyIndex)!
                    print("New Key index = \(self.meshStateManager.state().keyIndex.hexString())")
                    self.updateProvisioningDataUI()
                } else {
                    print("Key index must be exactly 2 bytes")
                }
       }
    }
   }

    func generateNewKey() -> Data {
        let helper = OpenSSLHelper()
        let newKey = helper.generateRandom()
        return newKey!
    }

    func didSelectFlagsCell() {
        presentInputViewWithTitle("Please enter flags",
                                  message: "1 Byte",
                                  placeholder: meshStateManager.state().flags.hexString(),
                                  generationEnabled: false) { (someFlags) -> Void in
                                    if let someFlags = someFlags {
                                        if someFlags.count == 2 {
                                            self.meshStateManager.state().flags = Data(hexString: someFlags)!
                                            self.updateProvisioningDataUI()
                                        } else {
                                            print("Flags must be exactly 1 byte")
                                        }
                                    }
        }
   }

    func didSelectIVIndexCell() {
        presentInputViewWithTitle("Please enter IV Index",
                                  message: "4 Bytes",
                                  placeholder: meshStateManager.state().IVIndex.hexString(),
                                  generationEnabled: false) { (anIVIndex) -> Void in
            if let anIVIndex = anIVIndex {
                if anIVIndex.count == 8 {
                    self.meshStateManager.state().IVIndex = Data(hexString: anIVIndex)!
                    self.updateProvisioningDataUI()
                } else {
                    print("IV Index must be exactly 4 bytes")
                }
       }
    }
   }

    func didSelectUnicastAddressCell() {
        presentInputViewWithTitle("Please enter Unicast Address",
                                  message: "2 Bytes, > 0x0000",
                                  placeholder: meshStateManager.state().unicastAddress.hexString(),
                                  generationEnabled: false) { (anAddress) -> Void in
            if let anAddress = anAddress {
                if anAddress.count == 4 {
                    if anAddress == "0000" {
                        print("Adderss cannot be 0x0000, minimum possible address is 0x0001")
                    } else {
                        self.meshStateManager.state().unicastAddress = Data(hexString: anAddress)!
                        self.updateProvisioningDataUI()
                    }
           } else {
                    print("Unicast address must be exactly 2 bytes")
                }
       }
    }
   }

    // MARK: - Input Alert
    func presentInputViewWithTitle(_ aTitle: String,
                                   message aMessage: String, placeholder aPlaceholder: String?,
                                   generationEnabled generationFlag: Bool,
                                   andCompletionHandler aHandler : @escaping (String?) -> Void) {
        let inputAlertView = UIAlertController(title: aTitle, message: aMessage, preferredStyle: .alert)
        inputAlertView.addTextField { (aTextField) in
            aTextField.keyboardType = UIKeyboardType.asciiCapable
            aTextField.returnKeyType = .done
            aTextField.delegate = self
            //Show clear button button when user is not editing
            aTextField.clearButtonMode = UITextFieldViewMode.whileEditing
            if let aPlaceholder = aPlaceholder {
                aTextField.text = aPlaceholder
            }
        }
        let saveAction = UIAlertAction(title: "Save", style: .default) { (_) in
            DispatchQueue.main.async {
                if let text = inputAlertView.textFields![0].text {
                    if text.count > 0 {
                        if let selectedIndexPath = self.settingsTable.indexPathForSelectedRow {
                            self.deselectSelectedRow()
                            if selectedIndexPath.row == 0 && selectedIndexPath.section == 0 {
                                aHandler(text)
                            } else {
                                aHandler(text.uppercased())
                            }
                   } else {
                            aHandler(text.uppercased())
                        }
                    }
                }
            }
        }

        var generateAction: UIAlertAction!
        if generationFlag {
            generateAction = UIAlertAction(title: "Generate new key", style: .default) { (_) in
                DispatchQueue.main.async {
                    let newKey = self.generateNewKey()
                    self.deselectSelectedRow()
                    aHandler(newKey.hexString())
                }
            }
        }

        let cancelACtion = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            DispatchQueue.main.async {
                self.deselectSelectedRow()
                aHandler(nil)
            }
        }

        inputAlertView.addAction(saveAction)

        if generationFlag {
            inputAlertView.addAction(generateAction)
        }

        inputAlertView.addAction(cancelACtion)
        present(inputAlertView, animated: true, completion: nil)
    }

    private func deselectSelectedRow() {
        if let indexPath = self.settingsTable.indexPathForSelectedRow {
            self.settingsTable.deselectRow(at: indexPath, animated: true)
        }
   }
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if range.length > 0 {
            //Going backwards, always allow deletion
            return true
        } else {
            if let selectedPath = settingsTable.indexPathForSelectedRow {
                if selectedPath.row == 0 && selectedPath.section == 0 {
                    //Name field can be of any value
                    return true
                } else {
                    return validateStringIsHexaDecimal(string)
                }
       } else {
                return validateStringIsHexaDecimal(string)
            }
    }
   }

    private func validateStringIsHexaDecimal(_ someText: String ) -> Bool {
        let value = someText.data(using: .utf8)![0]
        //Only allow HexaDecimal values 0->9, a->f and A->F
        return (value >= 48 && value <= 57) || (value >= 65 && value <= 70) || (value >= 97 && value <= 102)
    }

    // MARK: - Motion callbacks
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        //Shaking the iOS device will generate a new Key
        if motion == .motionShake {
            let newKey = generateNewKey()
            meshStateManager.state().netKey = newKey
            self.updateProvisioningDataUI()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupProvisioningData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if meshStateManager == nil {
            setupProvisioningData()
        }
        updateProvisioningDataUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        meshStateManager.saveState()
        super.viewWillDisappear(animated)
    }

    // MARK: - UITableView delegates
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return 5
        case 2: return 1
        default: return 0
        }
   }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aCell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        aCell.textLabel?.text = rowTitles[indexPath.section][indexPath.row]
        aCell.detailTextLabel?.text = self.contentForRowAtIndexPath(indexPath)
        return aCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        if section == 0 {
            if row == 0 {
                didSelectNetworkNameCell()
            } else {
                didSelectGlobalTTLCell()
            }
        } else if section == 1 {
            if row == 0 {
                didSelectKeyCell()
            } else if row == 1 {
                didSelectKeyIndexCell()
            } else if row == 2 {
                didSelectFlagsCell()
            } else if row == 3 {
                didSelectIVIndexCell()
            } else {
                didSelectUnicastAddressCell()
            }
        } else {
            didSelectAppKeysCell()
        }
    }

    func contentForRowAtIndexPath(_ indexPath: IndexPath) -> String {
        let section = indexPath.section
        let row = indexPath.row
        if section == 0 {
            if row == 0 {
                return meshStateManager.state().name
            } else if row == 1 {
                return "0x\(meshStateManager.state().globalTTL.hexString())"
            } else {
                return "N/A"
            }
        } else if section == 1 {
            if row == 0 {
                return "0x\(meshStateManager.state().netKey.hexString())"
            } else if row == 1 {
                return "0x\(meshStateManager.state().keyIndex.hexString())"
            } else if row == 2 {
                return "0x\(meshStateManager.state().flags.hexString())"
            } else if row == 3 {
                return "0x\(meshStateManager.state().IVIndex.hexString())"
            } else if row == 4 {
                return "0x\(meshStateManager.state().unicastAddress.hexString())"
            } else {
                return "N/A"
            }
        } else {
            if row == 0 {
                let keyCount = meshStateManager.state().appKeys.count
                return "\(keyCount) \(keyCount != 1 ? "keys" : "key")"
            }
            return "N/A"
        }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showKeyManagerView" {
            if let destination = segue.destination as? AppKeyManagerTableViewController {
                destination.setMeshState(meshStateManager)
            }
        }
    }
}
