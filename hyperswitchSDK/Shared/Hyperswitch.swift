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
        #if canImport(React)
        #if canImport(Airborne)
        // Before warmUp: the host resolves its bundle URL through Airborne.
        OTAServices.shared.initialize(publishableKey: configuration.publishableKey)
        #endif
        RNViewManager.shared.warmUp()
        #endif
    }

    public func initPaymentSession(configuration: PaymentSessionConfiguration) async -> PaymentSession {
        let session = PaymentSession(paymentSessionConfiguration: configuration, hyperswitchConfiguration: hyperswitchConfiguration)
        await session.activateRuntime()
        return session
    }
}
