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
    internal required init(
        paymentSessionConfiguration: PaymentSessionConfiguration,
        hyperswitchConfiguration: HyperswitchConfiguration? = nil,
        configuration: Configuration? = nil
    ) {
        self.paymentSessionConfiguration = paymentSessionConfiguration
        self.hyperswitchConfiguration = hyperswitchConfiguration
        self.configuration = configuration
    }

    internal let paymentSessionConfiguration: PaymentSessionConfiguration
    internal var hyperswitchConfiguration: HyperswitchConfiguration?

    /// The configuration object that holds the settings for the payment sheet.
    internal let configuration: Configuration?
    internal var completion: ((PaymentResult) -> Void)?
    internal var subscribedEvents: [String]?
    internal var paymentEventListener: PaymentEventListener?
    internal var shouldProceedWithPaymentCallback: ((PaymentRequestData, @escaping (Bool) -> Void) -> Void)?

    /// Identity of the presenting session in JS (its prefetch root tag), if any.
    internal var sessionTag: Int?

    /// The controller presenting this sheet, for dismissal when JS exits it.
    internal weak var presentedViewController: UIViewController?
}
