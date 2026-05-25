//
//  SavedPaymentMethodsConfiguration.swift
//  hyperswitch
//

import Foundation

/// Configuration for filtering saved payment methods returned by
/// `PaymentSession.getCustomerSavedPaymentMethods`.
public struct SavedPaymentMethodsConfiguration: Codable {

    /// Payment method types to exclude from the saved methods list
    /// (e.g. `["apple_pay", "paypal"]`). Values are matched against
    /// the `payment_method_type` field returned by the Hyperswitch API.
    public var hiddenPaymentMethods: [String]?

    /// Whether the saved payment method section is collapsed by default.
    public var defaultCollapsed: Bool?

    /// Whether to hide the card expiry date on saved card tiles.
    public var hideCardExpiry: Bool?

    /// Whether to hide CVC error messages for saved cards.
    public var hideCVCError: Bool?

    /// Controls visibility of the CVC icon in saved card inputs.
    public var cvcIcon: PaymentSheet.Visibility?

    /// Grouping behaviour for saved payment methods in the accordion layout.
    public var groupingBehavior: PaymentSheet.GroupingBehavior?

    public init(
        hiddenPaymentMethods: [String]? = nil,
        defaultCollapsed: Bool? = nil,
        hideCardExpiry: Bool? = nil,
        hideCVCError: Bool? = nil,
        cvcIcon: PaymentSheet.Visibility? = nil,
        groupingBehavior: PaymentSheet.GroupingBehavior? = nil
    ) {
        self.hiddenPaymentMethods = hiddenPaymentMethods
        self.defaultCollapsed = defaultCollapsed
        self.hideCardExpiry = hideCardExpiry
        self.hideCVCError = hideCVCError
        self.cvcIcon = cvcIcon
        self.groupingBehavior = groupingBehavior
    }
}
