//
//  RNViewManager.swift
//  Hyperswitch
//
//  Created by Shivam Shashank on 09/11/22.
//

import Foundation
import React
#if canImport(CodePush)
import CodePush
#endif

internal class RNViewManager: NSObject {
    
    internal var responseHandler: RNResponseHandler?
    internal var rootView: RCTRootView?
    
    private lazy var bridge: RCTBridge = {
        RCTBridge.init(delegate: self, launchOptions: nil)
    }()
    
    internal static let sharedInstance = RNViewManager()
    
    internal func viewForModule(_ moduleName: String, initialProperties: [String : Any]?) -> RCTRootView {
        let rootView: RCTRootView = RCTRootView(
            bridge: bridge,
            moduleName: moduleName,
            initialProperties: initialProperties)
        self.rootView = rootView
        return rootView
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
            CodePushAPI()
            return CodePush.bundleURL(forResource: "hyperswitch",
                                      withExtension: "bundle",
                                      subdirectory: "/Frameworks/Hyperswitch.framework")
        }
    }
}
