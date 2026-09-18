//
//  TokeniseResult.swift
//  Hyperswitch
//
//  Typed result of `CardForm.tokenise(completion:)`.
//

import Foundation

/// Mirrors the payment-methods package's `TokenizeErrorCode` union; any code this SDK does
/// not (yet) know about — a newer package version, or a malformed/missing result — maps to
/// `.unknown` rather than failing to parse.
public enum TokeniseErrorCode {
    case validationError
    case incompleteFieldSet
    case sdkNotReady
    case unsupportedConfiguration
    case sessionExpired
    case sessionConsumed
    case invalidSession
    case unknownOutcome
    case tokenizationFailed
    case unknown

    internal init(code: String?) {
        switch code {
        case "validation_error": self = .validationError
        case "incomplete_field_set": self = .incompleteFieldSet
        case "sdk_not_ready": self = .sdkNotReady
        case "unsupported_configuration": self = .unsupportedConfiguration
        case "session_expired": self = .sessionExpired
        case "session_consumed": self = .sessionConsumed
        case "invalid_session": self = .invalidSession
        case "unknown_outcome": self = .unknownOutcome
        case "tokenization_failed": self = .tokenizationFailed
        default: self = .unknown
        }
    }
}

public struct TokeniseError {
    public let code: TokeniseErrorCode
    public let message: String?
    public let type: String?
}

public struct TokeniseCard {
    public let last4: String?
    public let brand: String?
    public let expiryMonth: String?
    public let expiryYear: String?
}

/// Result of `CardForm.tokenise(completion:)`.
public enum TokeniseResult {
    case success(token: String, vaultType: String?, card: TokeniseCard?)
    case failure(vaultType: String?, error: TokeniseError)

    internal static func from(_ raw: [String: Any]?) -> TokeniseResult {
        guard let raw = raw else {
            return .failure(
                vaultType: nil,
                error: TokeniseError(code: .unknown, message: "No result received", type: nil)
            )
        }

        let status = raw["status"] as? String
        let vaultType = raw["vaultType"] as? String

        if status == "success" {
            let cardDict = raw["card"] as? [String: Any]
            let card = cardDict.map {
                TokeniseCard(
                    last4: $0["last4"] as? String,
                    brand: $0["brand"] as? String,
                    expiryMonth: $0["expiryMonth"] as? String,
                    expiryYear: $0["expiryYear"] as? String
                )
            }
            return .success(token: raw["token"] as? String ?? "", vaultType: vaultType, card: card)
        } else {
            let errorDict = raw["error"] as? [String: Any]
            return .failure(
                vaultType: vaultType,
                error: TokeniseError(
                    code: TokeniseErrorCode(code: errorDict?["code"] as? String),
                    message: errorDict?["message"] as? String,
                    type: errorDict?["type"] as? String
                )
            )
        }
    }
}
