// Copyright (c) 2020 Nomad5. All rights reserved.

import Foundation

class Navigator {

    struct Navigation {
        let userAgent:    String?
        let forwardToUrl: URL?
    }

    var userAgent:                 String? = nil
    var automaticUserAgentSetting: Bool    = true

    struct Config {
        static let stadiaWarning               = "https://stadia.google.com/warning/"
        static let stadiaWarningRedirectReason = "redirect_reasons=9"
        static let googleAccountsWarning       = "deniedsigninrejected"
        static let slash                       = "/"

        struct Url {
            static let google          = URL(string: "https://www.google.com")!
            static let googleStadia    = URL(string: "https://stadia.google.com")!
            static let googleAccounts  = URL(string: "https://accounts.google.com")!
            static let googleMyAccount = URL(string: "https://myaccount.google.com")!
            static let geforceNow      = URL(string: "https://play.geforcenow.com")!
            static let geforceNowLogin = URL(string: "https://www.nvidia.com/en-us/account/gfn")!
        }

        struct UserAgent {
            static let chromeDesktop = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.83 Safari/537.36"
        }
    }

    func getNavigation(for address: String?) -> Navigation {
        // early exit
        guard let requestedUrl = address else {
            return Navigation(userAgent: userAgent, forwardToUrl: nil)
        }
        // no automatic navigation
        if !automaticUserAgentSetting {
            return Navigation(userAgent: userAgent, forwardToUrl: nil)
        }
        // error happened with stadia, navigate to it directly
        if requestedUrl.starts(with: Config.stadiaWarning) &&
           requestedUrl.reversed().starts(with: Config.stadiaWarningRedirectReason.reversed()) {
            return Navigation(userAgent: Config.UserAgent.chromeDesktop, forwardToUrl: Config.Url.googleStadia)
        }
        // google account error occurred
        if requestedUrl.starts(with: Config.Url.googleAccounts.absoluteString) &&
           requestedUrl.contains(Config.googleAccountsWarning) {
            return Navigation(userAgent: nil, forwardToUrl: Config.Url.googleAccounts)
        }
        // regular google stadia
        if requestedUrl.isEqualTo(other: Config.Url.googleStadia.absoluteString) {
            return Navigation(userAgent: Config.UserAgent.chromeDesktop, forwardToUrl: nil)
        }
        // regular geforce now
        if requestedUrl.isEqualTo(other: Config.Url.geforceNow.absoluteString) {
            return Navigation(userAgent: Config.UserAgent.chromeDesktop, forwardToUrl: nil)
        }
        // some problem with signing
        if requestedUrl.contains("signin") {
            return Navigation(userAgent: nil, forwardToUrl: nil)
        }
        return Navigation(userAgent: userAgent, forwardToUrl: nil)
    }

}
