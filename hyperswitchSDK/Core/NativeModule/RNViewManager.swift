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
    
    internal lazy var bridge: RCTBridge = {
        RCTBridge.init(delegate: self, launchOptions: nil)
    }()
    
    internal lazy var bridgeHeadless: RCTBridge = {
        RCTBridge.init(delegate: self, launchOptions: nil)
    }()
    
    internal static let sharedInstance = RNViewManager()
    
    internal func viewForModule(_ moduleName: String, initialProperties: [String : Any]?) -> RCTRootView {
        let rootView: RCTRootView = RCTRootView(
            bridge: moduleName == "dummy" ? bridgeHeadless : bridge,
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

extension RNViewManager: RCTBridgeDelegate {
    func sourceURL(for bridge: RCTBridge!) -> URL! {
        switch getInfoPlist("HyperswitchSource") {
        case "LocalHosted":
            if let ip = getInfoPlist("HyperswitchSourceIP") {
                return URL(string: "http://"+ip+":8081/index.bundle?platform=ios")
            } else {
                return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
            }
        case "LocalBundle":
            return Bundle.main.url(forResource: "hyperswitch", withExtension: "bundle")
        default:
            return OTAServices.getBundleURL()
        }
    }
}
