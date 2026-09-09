//
//  PaymentMethodSessionConfiguration.swift
//  hyperswitch
//
//  Configuration for a payment-method session.
//

import Foundation

/// Configuration for `PaymentMethodSession`.
///
/// Mirrors the merchant-facing config object:
/// ```
/// configObject = {
///     vault_type = "",
///     vault_data = "data"
/// }
/// ```
public struct PaymentMethodSessionConfiguration: Codable {
    public let vaultType: String?
    public let vaultData: String?

    public init(vaultType: String? = nil, vaultData: String? = nil) {
        self.vaultType = vaultType
        self.vaultData = vaultData
    }

    enum CodingKeys: String, CodingKey {
        case vaultType = "vault_type"
        case vaultData = "vault_data"
    }
}

/// Per-field configuration for the payment-method input widgets.
///
/// ```
/// configuration = {
///     appearance = {},
///     ...any other props related to the field
/// }
/// ```
public struct InputConfiguration {
    public var appearance: [String: Any]?
    /// Mirrors the JS `FieldStyles` (root/container/input/placeholder/label/error/accessory).
    public var styles: FieldStyles?
    /// Mirrors the JS `FieldOptions` (label, labelBehavior, errorDisplay, unstyled,
    /// accessibilityLabel/Hint, cardBrandIcon, cvcIcon).
    public var options: FieldOptions?
    public var props: [String: Any]?

    public init(
        appearance: [String: Any]? = nil,
        styles: FieldStyles? = nil,
        options: FieldOptions? = nil,
        props: [String: Any]? = nil
    ) {
        self.appearance = appearance
        self.styles = styles
        self.options = options
        self.props = props
    }

    internal func toDictionary() -> [String: Any] {
        var dict = props ?? [:]
        if let appearance {
            dict["appearance"] = appearance
        }
        if let styles, !styles.isEmpty {
            dict["styles"] = styles.toDictionary()
        }
        if let options, !options.isEmpty {
            dict["options"] = options.toDictionary()
        }
        return dict
    }
}
