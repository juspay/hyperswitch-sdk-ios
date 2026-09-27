//
//  Hyperswitch.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 17/05/26.
//

import Foundation

public final class Hyperswitch {

    package let hyperswitchConfiguration: HyperswitchConfiguration

    public init(configuration: HyperswitchConfiguration) {  // MARK: async on superposition impl
        self.hyperswitchConfiguration = configuration
        LogManager.initialize(publishableKey: configuration.publishableKey)
        // Task {} Superposition
        PaymentsRuntime.entry?.warmUp(configuration: configuration)
    }

    public func initPaymentSession(configuration: PaymentSessionConfiguration) async -> PaymentSession {
        let session = PaymentSession(paymentSessionConfiguration: configuration, hyperswitchConfiguration: hyperswitchConfiguration)
        await PaymentsRuntime.entry?.activate(session)
        return session
    }
}
