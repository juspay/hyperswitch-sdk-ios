//
//  RNHeadlessManager.swift
//  Hyperswitch
//
//  Created by Shivam Shashank on 09/11/22.
//

import Foundation
import React

internal class RNHeadlessManager: NSObject {
    
    internal var responseHandler: RNResponseHandler?
    internal var rootView: RCTRootView?
    
    internal lazy var bridgeHeadless: RCTBridge = {
        RCTBridge.init(delegate: self, launchOptions: nil)
    }()
    
    internal static let sharedInstance = RNHeadlessManager()
    
    internal func viewForModule(_ moduleName: String, initialProperties: [String : Any]?) -> RCTRootView {
        let rootView: RCTRootView = RCTRootView(
            bridge: self.bridgeHeadless,
            moduleName: moduleName,
            initialProperties: initialProperties)
        self.rootView = rootView
        return rootView
    }
    
    internal func reinvalidateBridge(){
        self.bridgeHeadless.invalidate()
        self.bridgeHeadless = RCTBridge.init(delegate: self, launchOptions: nil)
    }
}

extension RNHeadlessManager: RCTBridgeDelegate {
    func sourceURL(for bridge: RCTBridge) -> URL? {
        switch getInfoPlist("HyperswitchSource") {
        case "LocalHosted":
            return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
        default:
            return Bundle(for: RNHeadlessManager.self).url(forResource: "hyperswitch", withExtension: "bundle")
        }
    }
}
