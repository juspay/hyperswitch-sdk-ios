//
//  RNViewManager.swift
//  Hyperswitch
//
//  Created by Shivam Shashank on 09/11/22.
//

import Foundation
import React
//#if canImport(CodePush)
//import CodePush
//#endif

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

extension RCTBridge: RCTReloadListener {
    
    func triggerReload (bridge: RCTBridge!) {
        NotificationCenter.default.post(name: NSNotification.Name.RCTBridgeWillReload, object: bridge, userInfo: nil)
        
        DispatchQueue.main.async {
            bridge.invalidate()
            bridge.setUp()
        }
    }
    
    public func didReceiveReloadCommand() {
        
        let preferences = UserDefaults.standard
        let pendingUpdate = preferences.object(forKey: "CODE_PUSH_PENDING_UPDATE") as? [String: Any]
        let updateIsLoading = pendingUpdate?["isLoading"] as? Bool
        
        if(!(updateIsLoading ?? true) && RNViewManager.sharedInstance.rootView != nil) {
            if (self === RNViewManager.sharedInstance.bridge) {
                triggerReload(bridge: self)
            }
        } else {
            if(RNViewManager.sharedInstance.rootView != nil) {
                if (self === RNViewManager.sharedInstance.bridge) {
                    return
                }
            }
            triggerReload(bridge: self)
        }
    }
}

//extension CodePush {
//    @objc private class func clearUpdates() {
//        let preferences = UserDefaults.standard
//        preferences.removeObject(forKey: "CODE_PUSH_PENDING_UPDATE")
//        preferences.removeObject(forKey: "CODE_PUSH_FAILED_UPDATES")
//        preferences.synchronize()
//    }
//}

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
            return Bundle.main.url(forResource: "hyperswitch.bundle", withExtension: "bundle")
        default:
            return OTAServices.getBundleURL()
        }
    }
}
