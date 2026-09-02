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

    /// Creates a payment session and prefetches the data the payment flows need.
    ///
    /// Await this before presenting a sheet or building a widget — it is what makes the
    /// subsequent flows API-call free. A prefetch miss is not an error: those flows fall back to
    /// fetching for themselves, so the session is still returned.
    ///
    /// - Throws: `SESSION_INIT_IN_PROGRESS` when another session for the same sdkAuthorization
    ///   is already fetching: retry once it completes, or keep the session you already have.
    public func initPaymentSession(configuration: PaymentSessionConfiguration) async throws -> PaymentSession {
        let session = PaymentSession(
            paymentSessionConfiguration: configuration,
            hyperswitchConfiguration: hyperswitchConfiguration
        )
        #if canImport(React)
        try await session.triggerPrefetch()
        #endif
        return session
    }
}
