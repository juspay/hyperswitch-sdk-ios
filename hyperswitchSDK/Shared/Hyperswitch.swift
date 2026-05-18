//
//  Hyperswitch.swift
//  HyperswitchCore
//
//  Created by Harshit Srivastava on 17/05/26.
//

public final class Hyperswitch {

    internal let hyperswitchConfiguration: HyperswitchConfiguration

    public init(configuration: HyperswitchConfiguration) {  // MARK: async on superposition impl
        self.hyperswitchConfiguration = configuration
        // Task {} Superposition
    }

    public func initPaymentSession(configuration: PaymentSessionConfiguration) -> PaymentSession {
        PaymentSession(paymentSessionConfiguration: configuration, hyperswitchConfiguration: hyperswitchConfiguration)
    }
}
