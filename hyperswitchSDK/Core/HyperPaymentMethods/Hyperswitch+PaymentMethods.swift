//
//  Hyperswitch+PaymentMethods.swift
//  hyperswitch
//
//  Payment-method session entry point.
//

import Foundation

extension Hyperswitch {

    /// Creates a payment-method session for the given `sdkAuthorization`.
    ///
    /// ```swift
    /// let hyperswitchInstance = Hyperswitch(configuration: hyperswitchConfiguration)
    /// let pmsInstance = hyperswitchInstance.initPaymentMethodSession(
    ///     sdkAuthorization: "sdk_auth",
    ///     configuration: PaymentMethodSessionConfiguration(vaultType: "", vaultData: "data")
    /// )
    /// ```
    ///
    /// Every returned `PaymentMethodSession` owns a **separate React Native host** —
    /// sessions are fully isolated from each other and from the main payment SDK's host.
    ///
    /// - Parameters:
    ///   - sdkAuthorization: session authorisation token issued by the merchant backend.
    ///   - configuration: session config object (`vault_type`, `vault_data`).
    public func initPaymentMethodSession(
        sdkAuthorization: String,
        configuration: PaymentMethodSessionConfiguration = PaymentMethodSessionConfiguration()
    ) -> PaymentMethodSession {
        return PaymentMethodSession(
            sdkAuthorization: sdkAuthorization,
            configuration: configuration,
            hyperswitchConfiguration: hyperswitchConfiguration
        )
    }
}
