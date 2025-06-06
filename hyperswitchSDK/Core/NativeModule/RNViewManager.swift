//
//  RNViewManager.swift
//  Hyperswitch
//
//  Created by Shivam Shashank on 09/11/22.
//

import Foundation
import React

internal class RNViewManager: NSObject {
    
    internal var responseHandler: RNResponseHandler?
    internal var rootView: RCTRootView?
    private var isHeadlessMode: Bool = false

    internal lazy var bridge: RCTBridge = {
        RCTBridge(delegate: self, launchOptions: nil)
    }()
    
    internal lazy var bridgeHeadless: RCTBridge = {
        RCTBridge(delegate: self, launchOptions: nil)
    }()
    
    internal static let sharedInstance = RNViewManager()
    
    internal func viewForModule(_ moduleName: String, initialProperties: [String : Any]?) -> RCTRootView {
        self.setHeadlessMode(moduleName == "dummy" ? true : false)
        let rootView: RCTRootView = RCTRootView(
            bridge: moduleName == "dummy" ? bridgeHeadless : bridge,
            moduleName: moduleName,
            initialProperties: initialProperties)
        self.rootView = rootView
        return rootView
    }
    
    internal func setHeadlessMode(_ isHeadless: Bool) {
        self.isHeadlessMode = isHeadless
    }
    
    internal func reinvalidateBridge(isHeadless: Bool = true) {
            if isHeadless {
                self.setHeadlessMode(true)
                self.bridgeHeadless.invalidate()
                self.bridgeHeadless = RCTBridge(delegate: self, launchOptions: nil)
            } else {
                self.setHeadlessMode(false)
                self.bridge.invalidate()
                self.bridge = RCTBridge(delegate: self, launchOptions: nil)
            }
        }
}

extension RNViewManager: RCTBridgeDelegate {
    func sourceURL(for bridge: RCTBridge) -> URL? {
        if self.isHeadlessMode {
            return Bundle.main.url(forResource: "hyperswitch", withExtension: "bundle")
        }else{
            switch getInfoPlist("HyperswitchSource") {
            case "LocalHosted":
                return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
            case "LocalBundle":
                return Bundle.main.url(forResource: "hyperswitch", withExtension: "bundle")
            default:
                return OTAServices.shared.getBundleURL()
            }
        }
    }
}
