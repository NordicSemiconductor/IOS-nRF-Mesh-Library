/*
* Copyright (c) 2026, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import UIKit
import Security

private let links: [(title: String, link: String)] = [
    ("nRF Cloud", "https://nrfcloud.com/"),
    ("Over-the-Air Updates (OTA)", "https://docs.memfault.com/docs/platform/ota"),
    ("Project Keys (Data Routes)", "https://docs.memfault.com/docs/platform/data-routes")
]

protocol ProjectKeyDelegate: AnyObject {
    func didSelectProjectKey(_ projectKey: ProjectKey)
}

class ProfileViewController: UITableViewController, ProjectKeyDelegate {
    
    // MARK: - Outlets

    @IBOutlet weak var loginButton: UIBarButtonItem!
    @IBAction func loginDidTap(_ sender: UIBarButtonItem) {
        if !isSignedIn {
            showSignInAlertDialog()
        } else {
            signOut()
        }
    }
    
    /// User API Key.
    private var userApiKey: UserApiKey?
    /// User profile.
    private var user: User?
    /// Selected Project Key.
    private var projectKey: ProjectKey?
    
    /// This is the blue background, which is drawn behind the NavBar.
    ///
    /// The ``scrollViewDidScroll(_:)`` method expands and collapses it during scrolling/.
    private let topBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .dynamicColor(
            light: UIColor(red: 0, green: 116.0 / 255.0, blue: 193.0 / 255.0, alpha: 1),
            dark: .clear
        )
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userApiKey = try? Keychain.loadUserApiKey()
        if isSignedIn {
            loginButton.title = "Sign Out"
        }
        let userData = try? Keychain.loadUserProfile()
        if let userData = userData {
            user = try? JSONDecoder().decode(User.self, from: userData)
        }
        projectKey = try? Keychain.loadProjectKey()
        
        // And and update the blue background (light theme only).
        tableView.addSubview(topBackgroundView)
        updateTopViewFrame()
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Keep the blue background (in light theme) visible when scrolling.
        updateTopViewFrame()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return !isSignedIn ? 2 : 3
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == IndexPath.sectionAbout else { return nil }

        // This code draws the row with the nRF Cloud logo and description in the header of the section.
        let container = UITableViewHeaderFooterView()
        container.contentView.backgroundColor = .dynamicColor(
            light: UIColor(red: 0, green: 116.0 / 255.0, blue: 193.0 / 255.0, alpha: 1),
            dark: .clear
        )

        let image = #imageLiteral(resourceName: "nrfcloud")
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.preferredFont(forTextStyle: .callout)
        titleLabel.text = "Authenticate and configure devices, send data, deploy OTA updates, diagnose issues, and monitor performance, all with nRF Cloud."
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        container.contentView.addSubview(imageView)
        container.contentView.addSubview(titleLabel)

        let guide = container.contentView.layoutMarginsGuide

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: guide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 130),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -10),
            titleLabel.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -32)
        ])

        return container
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !isSignedIn {
            if section == IndexPath.sectionDocs {
                return "Read More"
            }
        } else {
            switch section {
            case IndexPath.sectionUser:
                return "Profile"
            case IndexPath.sectionProjectKey:
                return "Project Key"
            default:
                break
            }
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if !isSignedIn {
            if section == IndexPath.sectionAbout {
                return """
                    By signing in, you let nRF Mesh access your nRF Cloud projects details.
                                       
                    Signing in is optional, and only needed for updating firmware Over-the-Air on mesh nodes which do not provide a Project Key, configured to use nRF Cloud as the OTA provider.
                    
                    
                    """
            }
        } else {
            if section == IndexPath.sectionProjectKey {
                return "The Project Key will be used for Firmware Over-the-Air updates (OTA) and Observability for nodes without a designated vendor model."
            }
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == IndexPath.sectionAbout {
            return 1 // Link to nRF Cloud
        }
        if !isSignedIn {
            return links.count - 1 // Remaining links
        } else {
            if user == nil {
                return 0
            }
            switch section {
            case IndexPath.sectionUser:
                if user?.isNordicEmployee == true {
                    return 3 // Name, email, isNordicEmployee
                }
                return 2 // Name, email
            case IndexPath.sectionProjectKey:
                if projectKey == nil {
                    return 1
                }
                return 3 // Organization, Project, Project Key
            default:
                return 0
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: indexPath.cellIdentifier(signedIn: isSignedIn), for: indexPath)
        if !isSignedIn || indexPath.section == IndexPath.sectionAbout {
            cell.textLabel?.text = links[indexPath.row + indexPath.section].title
            cell.detailTextLabel?.text = links[indexPath.row + indexPath.section].link
            return cell
        }
        
        switch indexPath.section {
        case IndexPath.sectionUser:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Name"
                cell.detailTextLabel?.text = user?.name
            case 1:
                cell.textLabel?.text = "E-mail"
                cell.detailTextLabel?.text = user?.email
            case 2:
                cell.textLabel?.text = "Nordic Employee"
                cell.detailTextLabel?.text = user?.isNordicEmployee == true ? "Yes" : "No"
            default:
                fatalError("Invalid row index")
            }
        case IndexPath.sectionProjectKey:
            if let projectKey = projectKey {
                switch indexPath.row {
                case 0:
                    cell.textLabel?.text = "Organization"
                    cell.detailTextLabel?.text = projectKey.organizationName
                    cell.accessoryType = .none
                    cell.selectionStyle = .none
                case 1:
                    cell.textLabel?.text = "Project"
                    cell.detailTextLabel?.text = projectKey.projectName
                    cell.accessoryType = .none
                    cell.selectionStyle = .none
                case 2:
                    cell.textLabel?.text = "Project Key"
                    cell.detailTextLabel?.text = projectKey.shortened
                    
                    let hasMoreProjectKeys = UserDefaults.standard.bool(forKey: "hasMultipleProjectKeys")
                    if hasMoreProjectKeys {
                        cell.accessoryType = .disclosureIndicator
                        cell.selectionStyle = .default
                    } else {
                        cell.accessoryType = .none
                        cell.selectionStyle = .none
                    }
                default:
                    fatalError("Invalid row index")
                }
                cell.isEnabled = true
            } else {
                cell.textLabel?.text = "Loading..."
                cell.detailTextLabel?.text = nil
                cell.accessoryType = .none
                cell.isEnabled = false
            }
        default:
            break
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if !isSignedIn || indexPath.section == IndexPath.sectionAbout,
           let url = URL(string: links[indexPath.row].link) {
            UIApplication.shared.open(url)
        }
        if indexPath.section == IndexPath.sectionProjectKey && indexPath.row == 2 {
            performSegue(withIdentifier: "change", sender: self)
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "change" {
            let hasMoreProjectKeys = UserDefaults.standard.bool(forKey: "hasMultipleProjectKeys")
            return hasMoreProjectKeys
        }
        return true // Links
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navigationController = segue.destination as! UINavigationController
        let destination = navigationController.topViewController as! OrganizationsViewController
        destination.user = user
        destination.userApiKey = userApiKey
        destination.delegate = self
    }
    
    func didSelectProjectKey(_ projectKey: ProjectKey) {
        try? Keychain.saveProjectKey(projectKey)
        self.projectKey = projectKey
        tableView.reloadSections(IndexSet(integer: IndexPath.sectionProjectKey), with: .automatic)
    }
    
    // MARK: Helper methods
    
    private func updateTopViewFrame() {
        let yOffset = tableView.contentOffset.y
        let width = tableView.bounds.width
        
        if yOffset < 0 {
            // When pulling down:
            // Move the view's Y to match the offset and expand the height
            topBackgroundView.frame = CGRect(x: 0, y: yOffset, width: width, height: abs(yOffset))
        } else {
            // When scrolling up:
            // Keep it at 0 height so it doesn't overlap cells
            topBackgroundView.frame = CGRect(x: 0, y: 0, width: width, height: 0)
        }
    }
    
    private func showSignInAlertDialog(withMessage message: String? = nil) {
        let alert = UIAlertController(title: "Sign In", message: message, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Email"
            textField.keyboardType = .emailAddress
        }
        alert.addTextField { textField in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Sign In", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let email = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let password = alert.textFields?.last?.text ?? ""

            alert.dismiss(animated: true) {
                let progress = UIAlertController(title: "Signing in…", message: nil, preferredStyle: .alert)
                self.present(progress, animated: true)

                Task {
                    do {
                        let apiKey = try await nRFCloud.getUserApiKey(email: email, password: password)
                        let user = try await nRFCloud.getUser(using: apiKey)
                        
                        // Store User Profile as Data for future use.
                        let userData = try JSONEncoder().encode(user)

                        await MainActor.run {
                            do { try Keychain.saveUserApiKey(apiKey) } catch { /* ignore save error */ }
                            self.userApiKey = apiKey
                            self.loginButton.title = "Sign Out"
                            
                            do { try Keychain.saveUserProfile(userData) } catch { /* ignore save error */ }
                            self.user = user
                            
                            self.tableView.reloadData()
                        }
                        
                        // Read the Project Key of the first project of the default organization.
                        // This is needed so that we didn't have to download it each time,
                        // and to make a Project Key selected initially.
                        var moreProjectKeys = user.organizations.count > 1
                        if let defaultOrg = user.organizations.first(where: { $0.isDefault == true }) ?? user.organizations.first {
                            let projects = try await nRFCloud.getProjects(in: defaultOrg, using: apiKey)
                            moreProjectKeys = moreProjectKeys || projects.count > 1
                            if let firstProject = projects.first {
                                let projectKeys = try await nRFCloud.getProjectKeys(for: firstProject, in: defaultOrg, using: apiKey)
                                moreProjectKeys = moreProjectKeys || projectKeys.count > 1
                                if let first = projectKeys.first {
                                    await MainActor.run {
                                        do { try Keychain.saveProjectKey(first) } catch { /* ignore save error */ }
                                        self.projectKey = first
                                        self.tableView.reloadSections(IndexSet(integer: IndexPath.sectionProjectKey), with: .automatic)
                                    }
                                }
                            }
                        }
                        UserDefaults.standard.set(moreProjectKeys, forKey: "hasMultipleProjectKeys")
                        await MainActor.run {
                            progress.dismiss(animated: true)
                        }
                    } catch {
                        NSLog("Request failed with error: \(error)")
                        let message: String
                        if let reqError = error as? URLRequest.Error, case .unauthorized = reqError {
                            message = "Invalid email or password."
                        } else {
                            message = "Could not sign in. Please try again. (\(error.localizedDescription))"
                        }
                        await MainActor.run {
                            progress.dismiss(animated: true) {
                                self.showSignInAlertDialog(withMessage: message)
                            }
                        }
                    }
                }
            }
        })
        present(alert, animated: true, completion: nil)
    }
    
    private var isSignedIn: Bool {
        return userApiKey != nil
    }
    
    private func signOut() {
        userApiKey = nil
        user = nil
        try? Keychain.deleteUserApiKey()
        try? Keychain.deleteUserProfile()
        try? Keychain.deleteProjectKey()
        loginButton.title = "Sign In"
        tableView.reloadData()
    }
    
    // MARK: - API methods

}

private extension IndexPath {
    
    static let sectionAbout = 0
    
    // Signed out
    static let sectionDocs  = 1
    
    // Signed in
    static let sectionUser       = 1
    static let sectionProjectKey = 2
    
    func cellIdentifier(signedIn: Bool) -> String {
        // The about section is always shown.
        if !signedIn {
            return "link"
        }
        switch section {
        case IndexPath.sectionAbout:
            return "link"
        case IndexPath.sectionUser:
            return "value"
        default:
            return "value"
        }
    }
    
}
