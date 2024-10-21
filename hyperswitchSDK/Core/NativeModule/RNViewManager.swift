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

internal protocol RNResponseHandler {
    func didReceiveResponse(response: String?, error: Error?) -> Void
}

internal class RNViewManager: NSObject {
    
    internal var responseHandler: RNResponseHandler?
    internal var rootView: RCTRootView?
    
    private var userAgent: String?
    
    private lazy var bridge: RCTBridge = {
        RCTBridge.init(delegate: self, launchOptions: nil)
    }()
    
    internal static let sharedInstance = RNViewManager()
    internal static let sharedInstance2 = RNViewManager()
    
    internal func viewForModule(_ moduleName: String, initialProperties: [String : Any]?) -> RCTRootView {
        let rootView: RCTRootView = RCTRootView(
            bridge: bridge,
            moduleName: moduleName,
            initialProperties: initialProperties)
        self.rootView = rootView
        return rootView
    }
    
    internal func reinvalidateBridge(){
        self.bridge.invalidate()
        self.bridge = RCTBridge.init(delegate: self, launchOptions: nil)
    }
}

private func getInfoPlist(_ key: String) -> String? {
    guard let infoDictionary = Bundle.main.infoDictionary,
          let value = infoDictionary[key] as? String, !value.isEmpty else {
        return nil
    }
    return value
}

private func getCodePushPlist(_ key: String) -> String? {
    guard let path = Bundle(for: RNViewManager.self).path(forResource: "CodePush", ofType: "plist"),
          let dict = NSDictionary(contentsOfFile: path),
          let value = dict[key] as? String, !value.isEmpty else {
        return nil
    }
    return value
}

private func CodePushAPI() {
    if let hyperVersion = getInfoPlist("HyperVersion"){
        CodePush.overrideAppVersion(hyperVersion)
    }
    else {
        if let hyperVersionInSDK = getCodePushPlist("HyperVersion"){
            CodePush.overrideAppVersion(hyperVersionInSDK)
        }
    }
    if let codePushDeploymentKey = getInfoPlist("HyperCodePushDeploymentKey"){
        CodePush.setDeploymentKey(codePushDeploymentKey)
    }
    else {
        if let codePushDeploymentKeyInSDK = getCodePushPlist("HyperCodePushDeploymentKey"){
            CodePush.setDeploymentKey(codePushDeploymentKeyInSDK)
        }
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
    func localSource(for bridge: RCTBridge!) -> URL! {
        Bundle.main.url(forResource: "hyperswitch",
                                  withExtension: "bundle",
                                  subdirectory: "/Frameworks/Hyperswitch.framework")
    }
}
