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

        let configuration = try? self.configuration?.toDictionary()

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
            "configuration": configuration as Any,
            "customBackendUrl": APIClient.shared.customBackendUrl as Any,
            "customLogUrl": APIClient.shared.customLogUrl as Any,
            "customParams": APIClient.shared.customParams as Any,
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
