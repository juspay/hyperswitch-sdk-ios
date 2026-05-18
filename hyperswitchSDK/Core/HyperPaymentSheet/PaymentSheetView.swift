//
//  PaymentSheetView.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 15/12/23.
//

import Foundation
import React
import WebKit

/// Extension on the PaymentSheet class to handle the creation of the React Native root view for the payment sheet.
internal extension PaymentSheet {

    /// Method to get the root view for the payment sheet based on the configured properties.
    func getRootView() -> RCTRootView {

        let hyperswitchConfiguration = try? hyperswitchConfiguration?.toDictionary()
        let paymentSessionConfiguration = try? paymentSessionConfiguration.toDictionary()

        /// Get the configuration dictionary from the configuration object.
        let configuration = try? self.configuration?.toDictionary()

        /// Create a dictionary of hyperParams with app ID, sdkVersion, country, user agent, default view, and launch time.
        let sdkParams = SDKParams.getSDKParams()

        /// Create a dictionary of props to be sent to React Native with configuration, type, sdkAuthorization, publishable key, hyperParams, custom backend URL, themes, and custom parameters.
        let props: [String: Any] = [
            "type": "payment",
            "hyperswitchConfig": hyperswitchConfiguration as Any,
            "paymentSessionConfig": paymentSessionConfiguration as Any,
            "sdkParams": sdkParams,
            "configuration": configuration as Any,
            "subscribedEvents": self.subscribedEvents,
        ]
        /// Get the root view from the RNViewManager with the "hyperSwitch" module and the props dictionary.
        let rootView = RNViewManager.sharedInstance.viewForModule("hyperSwitch", initialProperties: ["props": props])

        rootView.backgroundColor = UIColor.clear
        return rootView
    }

    /// Method to get the root view for the payment sheet with custom parameters.
    /// - Note: Used by Flutter and React Native Wrappers to send separate props.
    func getRootViewWithParams(props: [String: Any]) -> RCTRootView {

        let hyperswitchConfiguration = try? hyperswitchConfiguration?.toDictionary()
        let paymentSessionConfiguration = try? paymentSessionConfiguration.toDictionary()

        let sdkParams = SDKParams.getSDKParams()

        let props: [String: Any] = [
            "type": "payment",
            "hyperswitchConfig": hyperswitchConfiguration as Any,
            "paymentSessionConfig": paymentSessionConfiguration as Any,
            "sdkParams": sdkParams,
            "configuration": props,
            "subscribedEvents": self.subscribedEvents,
            "from": "rn",
        ]

        let rootView = RNViewManager.sharedInstance.viewForModule("hyperSwitch", initialProperties: ["props": props])

        rootView.backgroundColor = UIColor.clear
        return rootView
    }
}
