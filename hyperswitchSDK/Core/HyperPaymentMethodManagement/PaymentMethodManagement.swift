//
//  PaymentMethodManagement.swift
//  hyperswitch
//
//  Created by Shivam Nan on 15/09/24.
//

import Foundation
import WebKit

/// PaymentSheetResult is an enum that represents the possible outcomes of a payment sheet operation.
@frozen public enum PaymentMethodManagementSheetResult {
    case closed(data: String)
    case failed(error: Error)
}

internal class PaymentMethodManagement {
    private var ephemeralKey: String?
    internal var completion: ((PaymentMethodManagementSheetResult) -> ())?
    internal let configuration: PMMConfiguration?
    
    internal init(ephemeralKey: String, configuration: PMMConfiguration){
        self.ephemeralKey = ephemeralKey
        self.configuration = configuration
    }
    
    internal func presentPaymentMethodManagementView(from presentingViewController: UIViewController, completion: @escaping (PaymentMethodManagementSheetResult) -> ()) {

        /// Get the configuration dictionary from the configuration object.
        let configuration = self.configuration?.toDictionary()
        
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
            "configuration": configuration as Any,
            "hyperParams": hyperParams,
            "customBackendUrl": APIClient.shared.customBackendUrl as Any,
            "customParamas": APIClient.shared.customParams as Any,
            "ephemeralKey": self.ephemeralKey ?? "",
        ]
        
        /// Set the completion closure for handling the payment sheet result.
        self.completion = completion
        
        /// Set the response handler for the RNViewManager to be the current PaymentMethodManagement instance.
        RNViewManager.sharedInstance.responseHandler = self
        
        /// Get the root view from the RNViewManager with the "hyperSwitch" module and the props dictionary.
        let rootView = RNViewManager.sharedInstance.viewForModule("hyperSwitch", initialProperties: ["props": props])
        
        /// Create a new UIViewController to present the payment method management view.
        let paymentMethodManagementViewController = HyperUIViewController()
        
        /// Set the modal presentation style to cover the entire screen.
        paymentMethodManagementViewController.modalPresentationStyle = .overFullScreen
        
        /// Set the view of the payment management view controller to the provided root view.
        paymentMethodManagementViewController.view = rootView
        
        /// Set the background of the payment management view controller.
        paymentMethodManagementViewController.view.backgroundColor = UIColor.clear
        
        /// Present the payment management view controller modally from the presenting view controller.
        presentingViewController.present(paymentMethodManagementViewController, animated: false)
    }
}

/// An extension that conforms to the RNResponseHandler protocol, which handles the response from the payment sheet operation.
extension PaymentMethodManagement: RNResponseHandler {
    func didReceiveResponse(response: String?, error: Error?) {
        if let completion = completion {
            if let error = error {
                completion(.failed(error: error))
            }
            else if (response == "cancelled"){
                completion(.closed(data: "cancelled"))
            }
            else {
                completion(.closed(data: response ?? "failed"))
            }
        }
    }
}
