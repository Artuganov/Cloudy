// Copyright (c) 2020 Nomad5. All rights reserved.

import Foundation
import WebKit
import GameController


/// Main module that connects the web views controller scripts to the native controller handling
class WebViewControllerBridge: NSObject, WKScriptMessageHandlerWithReply {

    /// Remember last pressed keys to avoid log spamming
    private var lastPressedKeys: String? = nil

    /// Handle user content controller with proper native controller data reply
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage,
                               replyHandler: @escaping (Any?, String?) -> Void) {
        #if DEBUG
            // debug log
            if let pressedKeys = GCController.controllers().first?.extendedGamepad?.pressedKeys {
                if lastPressedKeys != pressedKeys {
                    print(pressedKeys)
                }
                lastPressedKeys = pressedKeys
            }
        #endif
        replyHandler(GCController.controllers().first?.extendedGamepad?.toJson(), nil)
    }
}
