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

private func getPlist(_ key: String) -> String? {
    guard let plistPath = Bundle(for: RNViewManager.self).path(forResource: "Codepush", ofType: "plist"),
          let plistData = try? Data(contentsOf: URL(fileURLWithPath: plistPath)),
          let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any],
          let value = plist[key] as? String, !value.isEmpty else {
        return nil
    }
    return value
}

private func CodepushAPI() {
    if let hyperVersion = getInfoPlist("HyperVersion"), !hyperVersion.isEmpty{
        CodePush.overrideAppVersion(hyperVersion)
    }
    else {
        if let hyperVersionInSDK = getPlist("HyperVersion"){
            CodePush.overrideAppVersion(hyperVersionInSDK)
        }
    }
    
    if let codePushDeploymentKey = getInfoPlist("CodePushDeploymentKey"), !codePushDeploymentKey.isEmpty {
        CodePush.setDeploymentKey(codePushDeploymentKey)
    }
    else {
        if let codePushDeploymentKeyInSDK = getPlist("CodePushDeploymentKey"){
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
            CodepushAPI()
            return CodePush.bundleURL(forResource: "hyperswitch",
                                      withExtension: "bundle",
                                      subdirectory: "/Frameworks/Hyperswitch.framework")
        }
    }
}
