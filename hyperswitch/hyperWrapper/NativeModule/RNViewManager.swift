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

protocol RNResponseHandler {
    func didReceiveResponse(response: String?, error: Error?) -> Void
}

class RNViewManager: NSObject {
    
    var rootView: RCTRootView?
    var responseHandler: RNResponseHandler?
    var userAgent: String?
    
    lazy var bridge: RCTBridge = {
        RCTBridge.init(delegate: self, launchOptions: nil)
    }()
    
    static let sharedInstance = RNViewManager()
    static let sharedInstance2 = RNViewManager()
    
    func viewForModule(_ moduleName: String, initialProperties: [String : Any]?) -> RCTRootView {
        let rootView: RCTRootView = RCTRootView(
            bridge: bridge,
            moduleName: moduleName,
            initialProperties: initialProperties)
        self.rootView = rootView
        return rootView
    }
    
    func reinvalidateBridge(){
        self.bridge.invalidate()
        self.bridge = RCTBridge.init(delegate: self, launchOptions: nil)
        
    }
}
private func CodepushAPI() {
    CodePush.overrideAppVersion(ProcessInfo.processInfo.environment["HyperVersion"])
    CodePush.setDeploymentKey(ProcessInfo.processInfo.environment["CodePushDeploymentKey"])
}

extension RNViewManager: RCTBridgeDelegate {
    func sourceURL(for bridge: RCTBridge!) -> URL! {
        switch ProcessInfo.processInfo.environment["HYPERSWITCH_JS_SOURCE"] {
        case "LOCAL_HOSTED_FOR_SIMULATOR":
            return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
        case "LOCAL_HOSTED_FOR_PHYSICAL_DEVICE":
            return URL(string: "http://<ip>:8081/index.bundle?platform=ios") /// replace <ip> with your ip
        case "LOCAL_BUNDLE":
            return Bundle.main.url(forResource: "hyperswitch",
                                   withExtension: "bundle")
        default:
            CodepushAPI()
            if let codePushURL = CodePush.bundleURL(forResource: "hyperswitch", withExtension: "bundle", subdirectory: "/Frameworks/Hyperswitch.framework"){
                return codePushURL
            }
            return Bundle.main.url(forResource: "hyperswitch", withExtension: "bundle")
        }
    }
}
