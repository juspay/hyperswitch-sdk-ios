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
        completion: @escaping (PaymentSheetResult) -> Void
    ) {
        let paymentSheet = PaymentSheet(
            sdkAuthorization: self.sdkAuthorization ?? "",
            configuration: configuration
        )
        paymentSheet.presentLite(from: viewController, completion: completion)
    }
}
