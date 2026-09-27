//
//  ReactNativeFactory+Host.swift
//  HyperswitchReactNative
//
//  Created by Harshit Srivastava on 26/09/26.
//

import Foundation
package import React
package import React_RCTAppDelegate

extension RCTReactNativeFactory {
    /// Starts the factory's React host, and with it the bundle, ahead of its first root.
    /// Idempotent.
    package func initializeHost() {
        rootViewFactory.initializeReactHost(
            launchOptions: nil,
            bundleConfiguration: RCTBundleConfiguration.default(),
            // Release builds of React Native have no dev menu: `default()` is nil there, which
            // the non-optional Swift parameter would trap on. An empty configuration is ignored alike.
            devMenuConfiguration: RCTDevMenuConfiguration.default() ?? RCTDevMenuConfiguration()
        )
    }
}
