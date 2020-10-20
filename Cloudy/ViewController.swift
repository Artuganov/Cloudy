// Copyright (c) 2020 Nomad5. All rights reserved.

import UIKit
import WebKit

class FullScreenWKWebView: WKWebView {
    override var safeAreaInsets: UIEdgeInsets {
        .zero
    }
}

class ViewController: UIViewController {

    /// Containers
    @IBOutlet var containerWebView: UIView!
    @IBOutlet var containerMenu:    UIView!

    /// View references
    @IBOutlet weak var userAgentTextField:     UITextField!
    @IBOutlet weak var manualUserAgent:        UISwitch!
    @IBOutlet weak var automaticUserAgent:     UISwitch!
    @IBOutlet weak var addressBar:             UITextField!
    @IBOutlet weak var backButton:             UIButton!
    @IBOutlet weak var forwardButton:          UIButton!

    /// The hacked webView
    private var        webView:                FullScreenWKWebView!
    private let        navigator:              Navigator = Navigator()

    /// By default hide the status bar
    override var       prefersStatusBarHidden: Bool {
        true
    }

    /// The configuration used for the wk webView
    private lazy var webViewConfig: WKWebViewConfiguration = {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.applicationNameForUserAgent = "Version/13.0.1 Safari/605.1.15"
        //config.userContentController.addScriptMessageHandler(WebViewControllerBridge(), contentWorld: WKContentWorld.page, name: "controller")
        return config
    }()

    /// View will be shown shortly
    override func viewDidLoad() {
        super.viewDidLoad()
        // configure webView
        webView = FullScreenWKWebView(frame: view.bounds, configuration: webViewConfig)
        webView.translatesAutoresizingMaskIntoConstraints = false
        containerWebView.addSubview(webView)
        webView.fillParent()
        webView.navigationDelegate = self
        // initial
        if let lastVisitedUrl = UserDefaults.standard.lastVisitedUrl {
            webView.navigateTo(url: lastVisitedUrl)
        } else {
            webView.navigateTo(url: Navigator.Config.Url.google)
        }
        // tapping anywhere else in the menu closes it
        let tap = UITapGestureRecognizer(target: self, action: #selector(onOverlayClosePressed))
        containerMenu.addGestureRecognizer(tap)
        // set user agent to label
        userAgentTextField.text = UserDefaults.standard.manualUserAgent
    }

    /// Update the address bar and its buttons
    func updateAddressBar() {
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
        // early exit
        guard let address = addressBar.text else { return }
        webView.navigateTo(address: address)
        hideMenu()
    }

    /// Reload current page
    @IBAction func onReloadPressed(_ sender: Any) {
        guard let url = webView.url else { return }
        webView.navigateTo(url: url)
        hideMenu()
    }

    /// Clear address bar pressed
    @IBAction func onClearPressed(_ sender: Any) {
        addressBar.text = ""
        addressBar.becomeFirstResponder()
    }

    /// Delete cache pressed
    @IBAction func onDeleteCachePressed(_ sender: Any) {
        WKWebView.clean()
    }

    /// Automatic user agent changed
    @IBAction func onAutomaticUserAgentSwitchChanged(_ sender: Any) {
        manualUserAgent.setOn(!automaticUserAgent.isOn, animated: true)
        navigator.automaticUserAgentSetting = automaticUserAgent.isOn
        navigator.userAgent = userAgentTextField.text
    }

    /// Manual user agent changed
    @IBAction func onManualUserAgentSwitchChanged(_ sender: Any) {
        automaticUserAgent.setOn(!manualUserAgent.isOn, animated: true)
        navigator.automaticUserAgentSetting = automaticUserAgent.isOn
        navigator.userAgent = userAgentTextField.text
    }

    /// Tapped on the menu item
    @IBAction func onMenuButtonPressed(_ sender: Any) {
        containerMenu.fadeIn()
    }

    /// Tapped somewhere to close the overlay
    @IBAction func onOverlayClosePressed(_ sender: Any) {
        hideMenu()
    }

    /// User agent value changed
    @IBAction func onUserAgentValueChanged(_ sender: Any) {
        navigator.userAgent = userAgentTextField.text
        UserDefaults.standard.manualUserAgent = userAgentTextField.text
    }

}

extension ViewController: WKNavigationDelegate {

    /// When a stadia page finished loading, inject the controller override script
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //if let url = webView.url?.absoluteString {
        //    if url.starts(with: Navigator.Config.Url.googleStadia.absoluteString) {
        //webView.injectControllerScript()
        //    }
        //}
        updateAddressBar()
        UserDefaults.standard.lastVisitedUrl = webView.url
    }

    /// After successfully logging in, forward user to stadia
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let navigation = navigator.getNavigation(for: navigationAction.request.url?.absoluteString)
        print("navigation -> \(navigation)")
        webView.customUserAgent = navigation.userAgent
        if let forwardUrl = navigation.forwardToUrl {
            decisionHandler(.cancel)
            webView.navigateTo(url: forwardUrl)
            return
        }
        decisionHandler(.allow)
    }
}
