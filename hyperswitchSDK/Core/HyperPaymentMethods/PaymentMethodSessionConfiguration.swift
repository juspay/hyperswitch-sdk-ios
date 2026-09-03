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
    public var props: [String: Any]?

    public init(appearance: [String: Any]? = nil, props: [String: Any]? = nil) {
        self.appearance = appearance
        self.props = props
    }

    internal func toDictionary() -> [String: Any] {
        var dict = props ?? [:]
        if let appearance {
            dict["appearance"] = appearance
        }
        return dict
    }
}
