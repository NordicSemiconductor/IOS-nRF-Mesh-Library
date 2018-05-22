//
//  ProvisioningLogTableViewController.swift
//  nRFMeshProvision_Example
//
//  Created by Mostafa Berg on 22/05/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import nRFMeshProvision

class ProvisioningLogTableViewController: UITableViewController {

    private var logEntries: [LogEntry]!

    public func initialLogEntries(entries: [LogEntry]) {
        logEntries = entries
    }

    public func logEntriesDidUpdate(newEntries: [LogEntry]) {
        logEntries = newEntries
        self.tableView.reloadData()
        if logEntries.count > 0 {
            //Scroll to bottom of table view when we start getting data
            //(.bottom places the last row to the bottom of tableview)
            tableView?.scrollToRow(at: IndexPath(row: logEntries.count - 1, section: 0),
                                                  at: .bottom, animated: true)
        }
    }

    func showFullLogMessageForItemAtIndexPath(_ anIndexPath: IndexPath) {
        let logEntry = logEntries[anIndexPath.row]
        let formattedTimestamp = DateFormatter.localizedString(from: logEntry.timestamp,
                                                               dateStyle: .none,
                                                               timeStyle: .medium)
        let alertView = UIAlertController(title: formattedTimestamp,
                                          message: logEntry.message,
                                          preferredStyle: UIAlertControllerStyle.alert)
        let copyAction = UIAlertAction(title: "Copy to clipboard", style: .default) { (_) in
            UIPasteboard.general.string = "\(formattedTimestamp): \(logEntry.message)"
            self.dismiss(animated: true, completion: nil)
        }
        let doneAction = UIAlertAction(title: "Done", style: .cancel) { (_) in
            self.dismiss(animated: true, completion: nil)
        }
        alertView.addAction(copyAction)
        alertView.addAction(doneAction)
        self.present(alertView, animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logEntries.count
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.showFullLogMessageForItemAtIndexPath(indexPath)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LogCell", for: indexPath) as! MeshNodeLogTableViewCell
        let logEntry = logEntries[indexPath.row]
        cell.setLogMessage(logEntry.message, withTimestamp: logEntry.timestamp)
        return cell
    }
}
