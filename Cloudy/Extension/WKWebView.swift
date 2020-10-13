// Copyright (c) 2020 Nomad5. All rights reserved.

import Foundation
import WebKit
import GameController

/// The script to be injected into the webview
/// It's overwriting the navigator.getGamepads function
/// to make the connection with the native GCController solid
private let script:       String        = """
                                          var emulatedGamepad = {
                                              id: "Emulated iOS Controller",
                                              index: 0,
                                              connected: true,
                                              timestamp: 0,
                                              mapping: "standard",
                                              axes: [0, 0, 0, 0],
                                              buttons: new Array(17).fill().map(m => ({pressed: false, touched: false, value: 0}))
                                          }

                                          navigator.getGamepads = function() {
                                              window.webkit.messageHandlers.controller.postMessage({}).then((controllerData) => {
                                                  try {
                                                      var data = JSON.parse(controllerData);
                                                      for(let i = 0; i < data.buttons.length; i++) {
                                                          emulatedGamepad.buttons[i].pressed = data.buttons[i].pressed;
                                                          emulatedGamepad.buttons[i].value = data.buttons[i].value;
                                                      }
                                                      for(let i = 0; i < data.axes.length; i++) {
                                                          emulatedGamepad.axes[i] = data.axes[i]
                                                      }
                                                  } catch(e) { }
                                              });
                                              return [emulatedGamepad, null, null, null];
                                          };
                                          """


/// Mapping from a alias to a full url
private let aliasMapping: [String: URL] = ["stadia": URL(string: "https://stadia.google.com")!]

extension WKWebView {

    /// Navigate to a given string
    func navigateTo(address: String) {
        // alias available?
        if let aliasUrl = aliasMapping[address] {
            load(URLRequest(url: aliasUrl))
            return
        }
        /// build url
        guard let url = URL(string: address.fixedProtocol()) else {
            print("Error creating Url from '\(address)'")
            return
        }
        // load
        navigateTo(url: url)
    }

    /// Navigate to url
    func navigateTo(url: URL) {
        load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData))
    }

    /// Inject inject the js controller script
    func injectControllerScript() {
        evaluateJavaScript(script, completionHandler: nil)
    }

    class func clean() {
        // clean cookies
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        // clean cache
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                #if DEBUG
                    print("WKWebsiteDataStore record deleted:", record)
                #endif
            }
        }
    }
}