//
//  CodePushAPI.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 22/10/24.
//

import Foundation
#if canImport(CodePush)
import CodePush
#endif

private func getCodePushPlist(_ key: String) -> String? {
    guard let path = Bundle(for: RNViewManager.self).path(forResource: "CodePush", ofType: "plist"),
          let dict = NSDictionary(contentsOfFile: path),
          let value = dict[key] as? String, !value.isEmpty else {
        return nil
    }
    return value
}

internal func CodePushAPI() {
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