//
//  PaymentSheetView.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 15/12/23.
//

import Foundation
import React

/// Extension on the PaymentSheet class to handle the creation of the React Native root view for the payment sheet.
internal extension PaymentSheet {
    
    /// Method to get the root view for the payment sheet based on the configured properties.
    func getRootView() -> RCTRootView {
        
        /// Get the configuration dictionary from the configuration object.
        let configuration = self.configuration?.toDictionary()
        
        /// Create a dictionary of hyperParams with app ID, country, IP address, user agent, default view, and launch time.
        let hyperParams = [
            "appId" : Bundle.main.bundleIdentifier,
            "country" : NSLocale.current.regionCode,
            "ip": nil,
            "user-agent": WKWebView().value(forKey: "userAgent"),
            "defaultView": self.defaultView,
            "launchTime": Int(Date().timeIntervalSince1970 * 1000)
        ]
        
        /// Create a dictionary of props to be sent to React Native with configuration, type, client secret, publishable key, hyperParams, custom backend URL, themes, and custom parameters.
        let props: [String : Any] = [
            "configuration": configuration as Any,
            "type":"payment",
            "clientSecret": self.intentClientSecret,
            "publishableKey": APIClient.shared.publishableKey as Any,
            "hyperParams": hyperParams,
            "customBackendUrl": APIClient.shared.customBackendUrl as Any,
            "themes": self.themes as Any,
            "customParamas": APIClient.shared.customParams as Any
        ]
        /// Get the root view from the RNViewManager with the "hyperSwitch" module and the props dictionary.
        let rootView =  RNViewManager.sharedInstance.viewForModule("hyperSwitch", initialProperties: ["props": props]);
        
        rootView.backgroundColor = UIColor.clear
        return rootView
    }
    
    /// Method to get the root view for the payment sheet with custom parameters.
    /// - Note: Used by Flutter and React Native Wrappers to send separate props.
    func getRootViewWithParams(props: [String: Any]) -> RCTRootView {
        
        var modifiedProps = props
        let params = props["hyperParams"] as? [String: Any] ?? [:]
        let hyperParams = [
            "appId" : Bundle.main.bundleIdentifier,
            "country" : NSLocale.current.regionCode,
            "ip": nil,
            "user-agent": WKWebView().value(forKey: "userAgent"),
            "defaultView": params["defaultView"],
            "launchTime": Int(Date().timeIntervalSince1970 * 1000)
        ]
        modifiedProps["hyperParams"] = hyperParams
        modifiedProps["type"] = "payment"
        
        let rootView =  RNViewManager.sharedInstance.viewForModule("hyperSwitch", initialProperties: ["props": modifiedProps]);
        rootView.backgroundColor = UIColor.clear
        return rootView
    }
}
