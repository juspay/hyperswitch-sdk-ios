//
//  PaymentSheetView+Lite.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 30/08/24.
//

import UIKit
import WebKit

extension PaymentSheet {
    
    func presentLite(from presentingViewController: UIViewController, completion: @escaping (PaymentSheetResult) -> ()) {
        
        let configuration = self.configuration?.toDictionary()
        
        let hyperParams = HyperParams.getHyperParams()
        
        /// Create a dictionary of props to be sent to React Native with configuration, type, client secret, publishable key, hyperParams, custom backend URL, themes, and custom parameters
        let props: [String : Any] = [
            "configuration": configuration as Any,
            "type":"payment",
            "clientSecret": self.intentClientSecret,
            "publishableKey": APIClient.shared.publishableKey as Any,
            "hyperParams": hyperParams,
            "customBackendUrl": APIClient.shared.customBackendUrl as Any,
            "customLogUrl": APIClient.shared.customLogUrl as Any,
            "customParams": APIClient.shared.customParams as Any
        ]
        
        let initialProps: [String : Any] = [
            "initialProps": [
                "props": props
            ]
        ]
        
        let paymentSheetViewController = WebViewController(props: initialProps, completion: completion)
        
        paymentSheetViewController.view.backgroundColor = UIColor.clear
        /// Set the modal presentation style to cover the entire screen.
        paymentSheetViewController.modalPresentationStyle = .overFullScreen
        /// Present the payment sheet view controller modally from the presenting view controller.
        presentingViewController.present(paymentSheetViewController, animated: false)
    }
}
