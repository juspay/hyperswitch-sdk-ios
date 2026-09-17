//
//  Hyperswitch.swift
//  HyperswitchCore
//
//  Created by Harshit Srivastava on 17/05/26.
//

public final class Hyperswitch {

    internal let hyperswitchConfiguration: HyperswitchConfiguration

    /// Asynchronous by contract rather than by need. Today it only boots the shared React
    /// host, and nothing a merchant does next has to wait for that. The suspension point is
    /// reserved: initialisation that must finish before the instance is usable (validating
    /// the publishable key, resolving remote configuration) can be added later without
    /// changing a single integration.
    ///
    /// Whatever is added here must stay quick. Work that only a payment needs belongs behind
    /// `initPaymentSession`, which is already asynchronous, so that an app paying for it at
    /// launch is never the default.
    public init(configuration: HyperswitchConfiguration) async {
        self.hyperswitchConfiguration = configuration
        #if canImport(React)
        await RNViewManager.shared.warmUp()
        #endif
    }

    public func initPaymentSession(configuration: PaymentSessionConfiguration) async -> PaymentSession {
        let session = PaymentSession(paymentSessionConfiguration: configuration, hyperswitchConfiguration: hyperswitchConfiguration)
        await session.activateRuntime()
        return session
    }
}
