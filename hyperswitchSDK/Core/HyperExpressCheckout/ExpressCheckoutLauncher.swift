//
//  ExpressCheckoutLauncher.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 21/02/24.
//

import Foundation
import React
import WebKit

@frozen public enum ExpressCheckoutResult {
    case completed(data: String)
    case canceled(data: String)
    case failed(error: Error)
}

public class ExpressCheckoutLauncher {

    private let reactManager = RNViewManager()

    init() {}

    var configuration: PaymentSheet.Configuration?
    var sdkAuthorization: String?
    var completion: ((ExpressCheckoutResult) -> Void)?
    var themes: String?

    public convenience init(
        sdkAuthorization: String,
        configuration: PaymentSheet.Configuration,
        themes: String? = nil,
        completion: @escaping ((ExpressCheckoutResult) -> Void)
    ) {

        self.init()

        self.configuration = configuration
        self.sdkAuthorization = sdkAuthorization
        self.themes = themes
        self.completion = completion

        let props: [String: Any] = [
            "publishableKey": APIClient.shared.publishableKey as Any,
            "profileId": APIClient.shared.profileId as Any,
            "sdkAuthorization": sdkAuthorization,
            "paymentMethodType": "expressCheckout",
            "paymentMethodData": "",
            "confirm": false,
        ]
        //        HyperModuleImpl.shared?.confirmEC(data: props) //MARK: WIP
    }

    public func launchPaymentSheet(paymentResult: NSMutableDictionary, callBack: @escaping RCTResponseSenderBlock) {

        DispatchQueue.main.async {

            self.reactManager.responseHandler = self

            let hyperParams = SDKParams.getSDKParams()

            let props: [String: Any] = [
                "type": "widgetPayment",
                "sdkAuthorization": self.sdkAuthorization as Any,
                "publishableKey": APIClient.shared.publishableKey as Any,
                "profileId": APIClient.shared.profileId as Any,
                "hyperParams": hyperParams,
                "customBackendUrl": APIClient.shared.customBackendUrl as Any,
                "customLogUrl": APIClient.shared.customLogUrl as Any,
                "customParams": APIClient.shared.customParams as Any,
            ]

            let rootView = self.reactManager.presentedViewForModule("hyperSwitch", initialProperties: ["props": props])

            rootView.backgroundColor = UIColor.clear

            let paymentSheetViewController = UIViewController()
            paymentSheetViewController.modalPresentationStyle = .overFullScreen
            paymentSheetViewController.view = rootView

            RCTPresentedViewController()!.present(paymentSheetViewController, animated: false)
        }
    }

}

extension ExpressCheckoutLauncher: RNResponseHandler {
    func didReceiveResponse(response: String?, error: Error?) {

        if let completion = self.completion {
            if let error = error {
                completion(.failed(error: error))
            } else if response == "cancelled" {
                completion(.canceled(data: "cancelled"))
            } else {
                completion(.completed(data: response ?? "failed"))
            }
        }
    }
}

extension ExpressCheckoutLauncher {
    public func confirm() {

        reactManager.responseHandler = self

        var props: [String: Any] = [
            "publishableKey": APIClient.shared.publishableKey as Any,
            "profileId": APIClient.shared.profileId as Any,
            "sdkAuthorization": self.sdkAuthorization as Any,
            "paymentMethodType": "expressCheckout",
            "paymentMethodData": "",
            "confirm": true,
        ]
        //        HyperModuleImpl.shared?.confirmEC(data: props) //MARK: WIP
    }
}
