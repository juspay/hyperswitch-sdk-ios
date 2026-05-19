//
//  SavedPaymentMethodsConfiguration.swift
//  hyperswitch
//

import Foundation

/// Configuration for filtering saved payment methods returned by
/// `PaymentSession.getCustomerSavedPaymentMethods`.
///
/// - Parameter hiddenPaymentMethods: Payment method types to exclude from the
///   saved methods list (e.g. `["apple_pay", "paypal"]`). Values are matched against
///   the `payment_method_type` field returned by the Hyperswitch API.
public struct SavedPaymentMethodsConfiguration: Codable {
    public var hiddenPaymentMethods: [String]

    public init(hiddenPaymentMethods: [String]) {
        self.hiddenPaymentMethods = hiddenPaymentMethods
    }
}
