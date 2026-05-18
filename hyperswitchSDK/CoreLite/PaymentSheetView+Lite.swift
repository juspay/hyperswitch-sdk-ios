//
//  PaymentSheetView+Lite.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 30/08/24.
//

import UIKit
import WebKit

extension PaymentSheet {

    func presentLite(from presentingViewController: UIViewController, completion: @escaping (PaymentResult) -> Void) {

        let hyperswitchConfiguration = try? hyperswitchConfiguration?.toDictionary()
        let paymentSessionConfiguration = try? paymentSessionConfiguration.toDictionary()

        let configuration = try? self.configuration?.toDictionary()

        let sdkParams = SDKParams.getSDKParams()

        /// Create a dictionary of props to be sent to React Native with configuration, type, client secret, publishable key, hyperParams, custom backend URL, themes, and custom parameters
        let props: [String: Any] = [
            "type": "payment",
            "hyperswitchConfig": hyperswitchConfiguration as Any,
            "paymentSessionConfig": paymentSessionConfiguration as Any,
            "sdkParams": sdkParams,
            "configuration": configuration as Any,
        ]

        let initialProps: [String: Any] = [
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
