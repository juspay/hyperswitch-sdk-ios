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
    /// Every call returns a **new** `PaymentMethodSession` that constructs its own
    /// `RNViewManager` (own `RCTReactNativeFactory` → own `RCTHost` → own JS runtime),
    /// i.e. every `initPaymentMethodSession` call results in a **new React host instance**
    /// (`session1.hostInstanceId != session2.hostInstanceId`), never a shared/cached one.
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
