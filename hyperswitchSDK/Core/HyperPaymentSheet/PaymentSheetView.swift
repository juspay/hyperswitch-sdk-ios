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
    func getRootView() -> UIView {

        let hyperswitchConfiguration = try? hyperswitchConfiguration?.toDictionary()
        let paymentSessionConfiguration = try? paymentSessionConfiguration.toDictionary()

        /// Get the configuration dictionary from the configuration object.
        var configuration = try? self.configuration?.toDictionary()
        configuration?["subscribedEvents"] = subscribedEvents

        /// Create a dictionary of hyperParams with app ID, sdkVersion, country, user agent, default view, and launch time.
        var sdkParams = SDKParams.getSDKParams()
        sdkParams["sessionTag"] = sessionTag

        /// Create a dictionary of props to be sent to React Native with configuration, type, sdkAuthorization, publishable key, hyperParams, custom backend URL, themes, and custom parameters.
        let props: [String: Any] = [
            "type": "payment",
            "hyperswitchConfig": hyperswitchConfiguration as Any,
            "paymentSessionConfig": paymentSessionConfiguration as Any,
            "sdkParams": sdkParams,
            "configuration": configuration as Any,
        ]
        guard let rootView = RNViewManager.shared.viewForModule("hyperSwitch", initialProperties: ["props": props], owner: self) as UIView?
        else {
            return UIView()
        }

        rootView.backgroundColor = UIColor.clear
        return rootView
    }

    /// Method to get the root view for the payment sheet with custom parameters.
    /// - Note: Used by Flutter and React Native Wrappers to send separate props.
    func getRootViewWithParams(props: [String: Any]) -> UIView {

        let hyperswitchConfiguration = try? hyperswitchConfiguration?.toDictionary()
        let paymentSessionConfiguration = try? paymentSessionConfiguration.toDictionary()

        var sdkParams = SDKParams.getSDKParams()
        sdkParams["sessionTag"] = sessionTag
        var propsDict = props
        propsDict["subscribedEvents"] = subscribedEvents

        let props: [String: Any] = [
            "type": "payment",
            "hyperswitchConfig": hyperswitchConfiguration as Any,
            "paymentSessionConfig": paymentSessionConfiguration as Any,
            "sdkParams": sdkParams,
            "configuration": propsDict,
            "from": "rn",
        ]

        guard let rootView = RNViewManager.shared.viewForModule("hyperSwitch", initialProperties: ["props": props], owner: self) as UIView?
        else {
            return UIView()
        }

        rootView.backgroundColor = UIColor.clear
        return rootView
    }
}
