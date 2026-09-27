//
//  PaymentSheet.swift
//  Hyperswitch
//
//  Created by Balaganesh on 09/12/22.
//

import Foundation
import UIKit

/// PaymentSheet is a class that handles the presentation and management of a payment sheet interface.
public class PaymentSheet {

    /// The initializer method that sets up the payment sheet with the required parameters.
    package required init(
        paymentSessionConfiguration: PaymentSessionConfiguration,
        hyperswitchConfiguration: HyperswitchConfiguration? = nil,
        configuration: Configuration? = nil
    ) {
        self.paymentSessionConfiguration = paymentSessionConfiguration
        self.hyperswitchConfiguration = hyperswitchConfiguration
        self.configuration = configuration
    }

    package let paymentSessionConfiguration: PaymentSessionConfiguration
    package var hyperswitchConfiguration: HyperswitchConfiguration?

    /// The configuration object that holds the settings for the payment sheet.
    package let configuration: Configuration?
    package var completion: ((PaymentResult) -> Void)?
    package var subscribedEvents: [String]?
    package var paymentEventListener: PaymentEventListener?
    package var shouldProceedWithPaymentCallback: ((PaymentRequestData, @escaping (Bool) -> Void) -> Void)?

    /// Identity of the presenting session in JS (its prefetch root tag), if any.
    package var sessionTag: Int?

    /// The controller presenting this sheet, for dismissal when JS exits it.
    package weak var presentedViewController: UIViewController?
}
