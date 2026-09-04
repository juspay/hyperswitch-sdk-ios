//
//  PaymentSession+Lite.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 30/08/24.
//

import Foundation
import UIKit

extension PaymentSession {

    public func presentPaymentSheetLite(
        viewController: UIViewController,
        configuration: PaymentSheet.Configuration,
        completion: @escaping (PaymentResult) -> Void
    ) {
        let paymentSheet = PaymentSheet(
            paymentSessionConfiguration: paymentSessionConfiguration,
            hyperswitchConfiguration: hyperswitchConfiguration,
            configuration: configuration
        )
        paymentSheet.presentLite(from: viewController, completion: completion)
    }
}

extension PaymentSession {

    internal func activateRuntime() async {} //no-op

    public func updateIntent(
        authorizationProvider: @escaping (@escaping (String) -> Void) -> Void,
        completion: @escaping (UpdateIntentResult) -> Void
    ) {
        authorizationProvider { [weak self] sdkAuthorization in
            self?.paymentSessionConfiguration = PaymentSessionConfiguration(sdkAuthorization: sdkAuthorization)
            completion(.success)
        }
    }
}
