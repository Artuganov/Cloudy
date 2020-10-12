// Copyright (c) 2020 Nomad5. All rights reserved.

import UIKit
import WebKit

class ViewController: UIViewController {

    /// The "hacked" webview
    @IBOutlet var webViewContainer: UIView!
    @IBOutlet var overlayContainer: UIView!

    @IBOutlet weak var userAgentTextField: UITextField!
    @IBOutlet weak var manualUserAgent:    UISwitch!
    @IBOutlet weak var userAgentAuto:      UISwitch!
    @IBOutlet weak var backButton:         UIButton!
    @IBOutlet weak var forwardButton:      UIButton!
    @IBOutlet weak var adressBar:          UITextField!

    private var webview: WKWebView!

    override var prefersStatusBarHidden: Bool {
        true
    }

    let mapping: [String: String] = [
        "https://stadia.google.com": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36",
        "https://play.geforcenow.com": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36"
    ]

    @IBAction func onDeleteCachePressed(_ sender: Any) {
        WKWebView.clean()
    }

    @IBAction func onManualUserAgentSwitchChanged(_ sender: Any) {
        userAgentAuto.setOn(!manualUserAgent.isOn, animated: true)
    }

    @IBAction func onClearPressed(_ sender: Any) {
        adressBar.text = ""
        adressBar.becomeFirstResponder()
    }

    @IBAction func onOverlayClosePressed(_ sender: Any) {
        overlayContainer.fadeOut()
        adressBar.resignFirstResponder()
    }

    @IBAction func onMenuButtonPressed(_ sender: Any) {
        overlayContainer.fadeIn()
    }

    @IBAction func onAutoSwitchChanged(_ sender: Any) {
        manualUserAgent.setOn(!userAgentAuto.isOn, animated: true)
        userAgentTextField.isEnabled = !userAgentAuto.isOn
    }

    /// The configuration used for the wk webview
    private lazy var webViewConfig: WKWebViewConfiguration = {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = false
        config.mediaTypesRequiringUserActionForPlayback = []
        config.applicationNameForUserAgent = "Version/13.0.1 Safari/605.1.15"
        config.userContentController.addScriptMessageHandler(WebViewControllerBridge(), contentWorld: WKContentWorld.page, name: "controller")
        return config
    }()

    @IBAction func onForwardPressed(_ sender: Any) {
        webview.goForward()
        overlayContainer.fadeOut()
        adressBar.resignFirstResponder()
    }

    @IBAction func onBackPressed(_ sender: Any) {
        webview.goBack()
        overlayContainer.fadeOut()
        adressBar.resignFirstResponder()
    }

    @IBAction func onGoPressed(_ sender: Any) {
        guard var text = adressBar.text else {
            print("ERROR, no adress give")
            return
        }
        if text == "stadia" {
            text = "https://stadia.google.com"
        }
        if !(text.starts(with: "https://") || text.starts(with: "http://")) {
            text = "https://" + text
        }
        guard let url = URL(string: text) else {
            print("ERROR, URL")
            return
        }
        webview.load(URLRequest(url: url))
        overlayContainer.fadeOut()
        adressBar.resignFirstResponder()
    }

    @IBAction func onReloadPressed(_ sender: Any) {
        webview.load(URLRequest(url: webview.url!))
        overlayContainer.fadeOut()
        adressBar.resignFirstResponder()
    }

    /// View will be shown shortly
    override func viewDidLoad() {
        super.viewDidLoad()
        // configure webview
        webview = WKWebView(frame: view.bounds, configuration: webViewConfig)
        webview.translatesAutoresizingMaskIntoConstraints = false
        webViewContainer.addSubview(webview)
        webview.leadingAnchor.constraint(equalTo: webViewContainer.leadingAnchor).isActive = true
        webview.trailingAnchor.constraint(equalTo: webViewContainer.trailingAnchor).isActive = true
        webview.topAnchor.constraint(equalTo: webViewContainer.topAnchor).isActive = true
        webview.bottomAnchor.constraint(equalTo: webViewContainer.bottomAnchor).isActive = true
        webview.navigationDelegate = self

        // trigger login path
//        webview.load(URLRequest(url: URL(string:"https://www.google.de")!))
//        webview.load(URLRequest(url: URL(string: "https://play.geforcenow.com/mall/")!))
//        webview.load(URLRequest(url: URL(string:"https://www.nvidia.com/en-us/account/gfn/")!))


        if let lastVisitedUrl = UserDefaults.standard.lastVisitedUrl {
            webview.load(URLRequest(url: URL(string: lastVisitedUrl)!))
        } else {
            webview.load(URLRequest(url: URL(string: "https://www.google.com")!))
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(onOverlayClosePressed))
        overlayContainer.addGestureRecognizer(tap)

    }

    func updateAdressbar() {
        adressBar.text = webview.url?.absoluteString ?? ""
        backButton.isEnabled = webview.canGoBack
        forwardButton.isEnabled = webview.canGoForward
    }


    func clearCache() {
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date             = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date, completionHandler: {})
    }
}

extension ViewController: WKNavigationDelegate {

    /// When a stadia page finished loading, inject the controller override script
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        if let url = webview.url?.absoluteString, url.starts(with: Config.Url.stadia.absoluteString) {
        webview.injectControllerScript()
        updateAdressbar()
        UserDefaults.standard.lastVisitedUrl = webView.url?.absoluteString
//        }
    }

    /// After successfully logging in, forward user to stadia
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//
        // if no automatic behavior is desired
        guard userAgentAuto.isEnabled,
              let requestedUrl = navigationAction.request.url?.absoluteString else {
            webview.customUserAgent = userAgentTextField.text ?? ""
            decisionHandler(.allow)
            return
        }
        // error happend with stadia, navigate to it
        if requestedUrl.starts(with: "https://stadia.google.com/warning/") &&
           requestedUrl.reversed().starts(with: "redirect_reasons=9".reversed()) {
            decisionHandler(.cancel)
            webview.customUserAgent = Config.UserAgent.chromeDesktop
            webview.load(URLRequest(url: Config.Url.stadia))
            return
        }

        if requestedUrl.starts(with: "https://accounts.google.com") &&
           requestedUrl.contains("deniedsigninrejected") {
            decisionHandler(.cancel)
            webview.customUserAgent = ""
//            webview.load(URLRequest(url: webView.url!))
            webview.load(URLRequest(url: URL(string: "https://accounts.google.com")!))
            return
        }
        //
        var userAgent = ""
        // check if we have a user agent mapping

        self.mapping.forEach { (key, value) in
            if requestedUrl.starts(with: key) {
                userAgent = value
            }
        }

        if requestedUrl.contains("signin") {
            userAgent = ""
        }

        webview.customUserAgent = userAgent
        print("\(requestedUrl) -> \(userAgent)")
        decisionHandler(.allow)
    }
}
