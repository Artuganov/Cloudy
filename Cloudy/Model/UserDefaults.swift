// Copyright (c) 2020 Nomad5. All rights reserved.

import Foundation

extension UserDefaults {

    private struct Config {
        static let lastVisitedUrlKey = "lastVisitedUrlKey"
        static let manualUserAgent   = "manualUserAgent"
    }

    /// Read / write the last visited url
    var lastVisitedUrl:  URL? {
        get {
            UserDefaults.standard.url(forKey: Config.lastVisitedUrlKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Config.lastVisitedUrlKey)
        }
    }

    /// Read / write the user agent
    var manualUserAgent: String? {
        get {
            UserDefaults.standard.string(forKey: Config.manualUserAgent)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Config.manualUserAgent)
        }
    }
}