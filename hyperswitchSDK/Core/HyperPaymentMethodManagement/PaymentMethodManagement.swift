//
//  PaymentMethodManagement.swift
//  hyperswitch
//
//  Created by Shivam Nan on 15/09/24.
//

import Foundation
import WebKit

internal class PaymentMethodManagement {
    private var ephemeralKey: String?
    
    internal init(ephemeralKey: String){
        self.ephemeralKey = ephemeralKey
    }
    
    internal func presentPaymentMethodManagementView(from presentingViewController: UIViewController) {
        /// Create a dictionary of hyperParams with app ID, sdkVersion, country, IP address, user agent, default view, and launch time.
        let hyperParams = [
            "appId" : Bundle.main.bundleIdentifier,
            "sdkVersion" : SDKVersion.current,
            "country" : NSLocale.current.regionCode,
            "ip": nil,
            "user-agent": WKWebView().value(forKey: "userAgent"),
            "launchTime": Int(Date().timeIntervalSince1970 * 1000)
        ]
        
        /// Create a dictionary of props to be sent to React Native with configuration, type, client secret, publishable key, hyperParams, custom backend URL, themes, and custom parameters.
        let props: [String : Any] = [
            "type":"paymentMethodsManagement",
            "hyperParams": hyperParams,
            "customBackendUrl": APIClient.shared.customBackendUrl as Any,
            "customParamas": APIClient.shared.customParams as Any,
            "ephemeralKey": self.ephemeralKey ?? "",
        ]
        
        /// Get the root view from the RNViewManager with the "hyperSwitch" module and the props dictionary.
        let rootView = RNViewManager.sharedInstance.viewForModule("hyperSwitch", initialProperties: ["props": props])
        
        /// Create a new UIViewController to present the payment method management view.
        let paymentMethodManagementViewController = HyperUIViewController()
        
        /// Set the modal presentation style to cover the entire screen.
        paymentMethodManagementViewController.modalPresentationStyle = .overFullScreen
        
        /// Set the view of the payment management view controller to the provided root view.
        paymentMethodManagementViewController.view = rootView
        
        /// Present the payment management view controller modally from the presenting view controller.
        presentingViewController.present(paymentMethodManagementViewController, animated: false)
    }
}
