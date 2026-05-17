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

        /// Encode configuration and merge subscribedEvents into it
        var configuration = (try? self.configuration?.toDictionary()) ?? [:]
        configuration["subscribedEvents"] = self.subscribedEvents

        /// Build sdkParams from hyperParams, adding sessionId and confirm
        var sdkParams = HyperParams.getHyperParams()
        sdkParams["sessionId"] = ""
        sdkParams["confirm"] = false

        /// Build props matching the nativeJsonToRecord structure expected by SdkTypes.res
        let props: [String: Any] = [
            "type": "payment",
            "hyperswitchConfig": [
                "publishableKey": APIClient.shared.publishableKey as Any,
                "profileId": APIClient.shared.profileId as Any,
            ],
            "paymentSessionConfig": [
                "sdkAuthorization": self.sdkAuthorization,
            ],
            "sdkParams": sdkParams,
            "configuration": configuration,
            "customBackendUrl": APIClient.shared.customBackendUrl as Any,
            "customLogUrl": APIClient.shared.customLogUrl as Any,
            "customParams": APIClient.shared.customParams as Any,
        ]
        let rootView = RNViewManager.sharedInstance.viewForModule("hyperSwitch", initialProperties: ["props": props])

        rootView.backgroundColor = UIColor.clear
        return rootView
    }

    /// Method to get the root view for the payment sheet with custom parameters.
    /// - Note: Used by Flutter and React Native Wrappers to send separate props.
    func getRootViewWithParams(props: [String: Any]) -> RCTRootView {

        var sdkParams = HyperParams.getHyperParams()
        sdkParams["sessionId"] = ""
        sdkParams["confirm"] = false

        var configuration = props
        configuration["subscribedEvents"] = self.subscribedEvents

        let props: [String: Any] = [
            "type": "payment",
            "hyperswitchConfig": [
                "publishableKey": APIClient.shared.publishableKey as Any,
                "profileId": APIClient.shared.profileId as Any,
            ],
            "paymentSessionConfig": [
                "sdkAuthorization": self.sdkAuthorization,
            ],
            "sdkParams": sdkParams,
            "configuration": configuration,
            "customBackendUrl": APIClient.shared.customBackendUrl as Any,
            "customLogUrl": APIClient.shared.customLogUrl as Any,
            "customParams": APIClient.shared.customParams as Any,
            "from": "rn",
        ]

        let rootView = RNViewManager.sharedInstance.viewForModule("hyperSwitch", initialProperties: ["props": props])

        rootView.backgroundColor = UIColor.clear
        return rootView
    }
}
