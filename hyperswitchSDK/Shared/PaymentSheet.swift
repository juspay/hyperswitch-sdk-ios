//
//  PaymentSheet.swift
//  Hyperswitch
//
//  Created by Balaganesh on 09/12/22.
//

import Foundation

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
}
