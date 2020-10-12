// Copyright (c) 2020 Nomad5. All rights reserved.

import Foundation

extension UserDefaults {

    private struct Config {
        static let lastVisitedUrlKey = "lastVisitedUrlKey"
    }

    /// Read / write the user default
    var lastVisitedUrl: String? {
        get {
            UserDefaults.standard.string(forKey: Config.lastVisitedUrlKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Config.lastVisitedUrlKey)
        }
    }
}