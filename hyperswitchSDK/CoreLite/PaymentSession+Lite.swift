//
//  PaymentSession+Lite.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 30/08/24.
//

import Foundation
import UIKit

extension PaymentSession {
    
    public func presentPaymentSheetLite(viewController: UIViewController, configuration: PaymentSheet.Configuration, completion: @escaping (PaymentSheetResult) -> ()){
        PaymentSession.isPresented = true
        let paymentSheet = PaymentSheet(paymentIntentClientSecret: PaymentSession.paymentIntentClientSecret ?? "", configuration: configuration)
        paymentSheet.presentLite(from: viewController, completion: completion)
    }
}
