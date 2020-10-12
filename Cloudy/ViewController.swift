// Copyright (c) 2020 Nomad5. All rights reserved.

import UIKit
import WebKit

class ViewController: UIViewController {

    /// Containers
    @IBOutlet var containerWebView: UIView!
    @IBOutlet var containerMenu:    UIView!

    /// View references
    @IBOutlet weak var userAgentTextField: UITextField!
    @IBOutlet weak var manualUserAgent:    UISwitch!
    @IBOutlet weak var automaticUserAgent: UISwitch!
    @IBOutlet weak var backButton:         UIButton!
    @IBOutlet weak var forwardButton:      UIButton!
    @IBOutlet weak var addressBar:         UITextField!

    /// The hacked webView
    private var webView: WKWebView!

    /// By default hide the status bar
    override var prefersStatusBarHidden: Bool {
        true
    }

    let mapping: [String: String] = [
        "https://stadia.google.com": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36",
        "https://play.geforcenow.com": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36"
    ]



    @IBAction func onManualUserAgentSwitchChanged(_ sender: Any) {
        automaticUserAgent.setOn(!manualUserAgent.isOn, animated: true)
    }

    @IBAction func onClearPressed(_ sender: Any) {
        addressBar.text = ""
        addressBar.becomeFirstResponder()
    }

    @IBAction func onOverlayClosePressed(_ sender: Any) {
        containerMenu.fadeOut()
        addressBar.resignFirstResponder()
    }

    @IBAction func onMenuButtonPressed(_ sender: Any) {
        containerMenu.fadeIn()
    }

    @IBAction func onAutoSwitchChanged(_ sender: Any) {
        manualUserAgent.setOn(!automaticUserAgent.isOn, animated: true)
        userAgentTextField.isEnabled = !automaticUserAgent.isOn
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







    @IBAction func onReloadPressed(_ sender: Any) {
        webView.load(URLRequest(url: webView.url!))
        containerMenu.fadeOut()
        addressBar.resignFirstResponder()
    }

    /// View will be shown shortly
    override func viewDidLoad() {
        super.viewDidLoad()
        // configure webview
        webView = WKWebView(frame: view.bounds, configuration: webViewConfig)
        webView.translatesAutoresizingMaskIntoConstraints = false
        containerWebView.addSubview(webView)
        webView.leadingAnchor.constraint(equalTo: containerWebView.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: containerWebView.trailingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: containerWebView.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: containerWebView.bottomAnchor).isActive = true
        webView.navigationDelegate = self

        // trigger login path
//        webview.load(URLRequest(url: URL(string:"https://www.google.de")!))
//        webview.load(URLRequest(url: URL(string: "https://play.geforcenow.com/mall/")!))
//        webview.load(URLRequest(url: URL(string:"https://www.nvidia.com/en-us/account/gfn/")!))


        if let lastVisitedUrl = UserDefaults.standard.lastVisitedUrl {
            webView.load(URLRequest(url: URL(string: lastVisitedUrl)!))
        } else {
            webView.load(URLRequest(url: URL(string: "https://www.google.com")!))
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(onOverlayClosePressed))
        containerMenu.addGestureRecognizer(tap)

    }

    func updateAdressbar() {
        addressBar.text = webView.url?.absoluteString ?? ""
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
    }

    }

/// UI handling extension
extension ViewController {

    /// Hide menu and keyboard
    private func hideMenu() {
        containerMenu.fadeOut()
        addressBar.resignFirstResponder()
    }

    /// Forward
    @IBAction func onForwardPressed(_ sender: Any) {
        webView.goForward()
        hideMenu()
    }

    /// Go backward
    @IBAction func onBackPressed(_ sender: Any) {
        webView.goBack()
        hideMenu()
    }

    /// Navigate to a url
    @IBAction func onGoPressed(_ sender: Any) {
        guard var text = addressBar.text else {
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
        webView.load(URLRequest(url: url))
        containerMenu.fadeOut()
        addressBar.resignFirstResponder()
    }

    /// Delete cache pressed
    @IBAction func onDeleteCachePressed(_ sender: Any) {
        WKWebView.clean()
    }
}

extension ViewController: WKNavigationDelegate {

    /// When a stadia page finished loading, inject the controller override script
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        if let url = webview.url?.absoluteString, url.starts(with: Config.Url.stadia.absoluteString) {
        webView.injectControllerScript()
        updateAdressbar()
        UserDefaults.standard.lastVisitedUrl = webView.url?.absoluteString
//        }
    }

    /// After successfully logging in, forward user to stadia
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        // if no automatic behavior is desired
        guard automaticUserAgent.isEnabled,
              let requestedUrl = navigationAction.request.url?.absoluteString else {
            webView.customUserAgent = userAgentTextField.text ?? ""
            decisionHandler(.allow)
            return
        }
        // error happend with stadia, navigate to it
        if requestedUrl.starts(with: "https://stadia.google.com/warning/") &&
           requestedUrl.reversed().starts(with: "redirect_reasons=9".reversed()) {
            decisionHandler(.cancel)
            webView.customUserAgent = Config.UserAgent.chromeDesktop
            webView.load(URLRequest(url: Config.Url.stadia))
            return
        }

        if requestedUrl.starts(with: "https://accounts.google.com") &&
           requestedUrl.contains("deniedsigninrejected") {
            decisionHandler(.cancel)
            webView.customUserAgent = nil
            webView.load(URLRequest(url: URL(string: "https://accounts.google.com")!))
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

        webView.customUserAgent = userAgent
        print("\(requestedUrl) -> \(userAgent)")
        decisionHandler(.allow)
    }
}
