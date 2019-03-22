//
//  AppInfoswift
//  nRFMeshProvision_Example
//
//  Created by Aleksander Nowakowski on 19/03/2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

struct AppInfo {
    
    // Non-instantiable.
    private init() {}
        
    /// Returns Application version as String.
    static var version: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }
    
    /// Returns Build Number as String.
    static var buildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "N/A"
    }
}
