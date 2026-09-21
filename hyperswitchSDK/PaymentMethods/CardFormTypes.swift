//
//  CardFormTypes.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 21/09/26.
//

import Foundation

public enum CardElementType: String, CaseIterable {
    case cardNumber
    case cardExpiry
    case cardCvc
    case cardholderName
}

/// What is known about the card without knowing the card. The number and the security code
/// are never part of any value this SDK hands out.
public struct CardDetails: Equatable {
    public let bin: String?
    public let extendedBin: String?
    public let last4: String?
    public let brand: String?
    public let expiryMonth: String?
    public let expiryYear: String?

    internal init(_ payload: [String: Any]) {
        bin = payload["bin"] as? String
        extendedBin = payload["extendedBin"] as? String
        last4 = payload["last4"] as? String
        brand = payload["brand"] as? String
        expiryMonth = payload["expiryMonth"] as? String
        expiryYear = payload["expiryYear"] as? String
    }
}

public struct CardFieldState: Equatable {
    public let elementType: CardElementType
    public let isEmpty: Bool
    public let isComplete: Bool
    public let isValid: Bool
    public let isTouched: Bool
    public let brand: String?
    public let error: String?

    internal init?(_ payload: [String: Any]) {
        guard let raw = payload["elementType"] as? String,
              let elementType = CardElementType(rawValue: raw)
        else { return nil }
        self.elementType = elementType
        isEmpty = payload["empty"] as? Bool ?? true
        isComplete = payload["complete"] as? Bool ?? false
        isValid = payload["valid"] as? Bool ?? false
        isTouched = payload["touched"] as? Bool ?? false
        brand = payload["brand"] as? String
        error = payload["error"] as? String
    }
}

public struct CardFormState: Equatable {
    /// Every field on screen is complete.
    public let isComplete: Bool
    /// Every field on screen is valid.
    public let isValid: Bool
    public let card: CardDetails
    /// The fields currently on screen, by type.
    public let fields: [CardElementType: CardFieldState]

    internal init(_ payload: [String: Any]) {
        isComplete = payload["complete"] as? Bool ?? false
        isValid = payload["valid"] as? Bool ?? false
        card = CardDetails(payload["payload"] as? [String: Any] ?? [:])
        var fields: [CardElementType: CardFieldState] = [:]
        for (_, value) in payload["fields"] as? [String: Any] ?? [:] {
            if let state = (value as? [String: Any]).flatMap(CardFieldState.init) {
                fields[state.elementType] = state
            }
        }
        self.fields = fields
    }
}

public struct CardFormError: Error, Equatable {
    public let message: String
}

public struct TokenizedCard {
    public let vaultType: String?
    /// The vault's tokens by name. The Hyperswitch vault returns `payment_method_token`.
    public let tokens: [String: String]
    public let card: CardDetails?

    public var paymentMethodToken: String? { tokens["payment_method_token"] }
}

public struct TokenizeError: Error, Equatable {
    public enum Kind: String {
        /// The card as entered cannot be tokenized; the fields say why.
        case validation = "validation_error"
        case api = "api_error"
        case card = "card_error"
    }

    public let kind: Kind
    public let code: String
    public let message: String

    internal static func local(_ code: String, _ message: String) -> TokenizeError {
        TokenizeError(kind: .validation, code: code, message: message)
    }
}

@frozen public enum TokenizeResult {
    case success(TokenizedCard)
    case failure(TokenizeError)

    /// From the bundle's answer to a tokenize command (`CommandResultPayload`).
    internal init(commandResult payload: [String: Any]) {
        guard payload["ok"] as? Bool == true,
              let result = payload["result"] as? [String: Any]
        else {
            let message = payload["message"] as? String ?? "The card could not be tokenized."
            self = .failure(TokenizeError(kind: .api, code: "tokenization_failed", message: message))
            return
        }

        guard result["status"] as? String == "success" else {
            let error = result["error"] as? [String: Any] ?? [:]
            self = .failure(
                TokenizeError(
                    kind: (error["type"] as? String).flatMap(TokenizeError.Kind.init) ?? .api,
                    code: error["code"] as? String ?? "tokenization_failed",
                    message: error["message"] as? String ?? "The card could not be tokenized."
                )
            )
            return
        }

        let data = result["data"] as? [String: Any] ?? [:]
        var tokens: [String: String] = [:]
        for (name, value) in data["tokens"] as? [String: Any] ?? [:] {
            tokens[name] = value as? String ?? String(describing: value)
        }
        self = .success(
            TokenizedCard(
                vaultType: result["vaultType"] as? String,
                tokens: tokens,
                card: (result["card"] as? [String: Any]).map(CardDetails.init)
            )
        )
    }
}

public struct CardFieldOptions {
    public enum LabelBehavior: String { case above, floating, never }
    public enum ErrorDisplay: String { case none, colorOnly, inline }
    public enum CvcIcon: String {
        case standard = "default"
        case hidden
    }

    public var placeholder: String?
    public var label: String?
    public var labelBehavior: LabelBehavior?
    public var errorDisplay: ErrorDisplay?
    public var unstyled: Bool?
    /// Read by the CVC field only.
    public var cvcIcon: CvcIcon?

    public init(
        placeholder: String? = nil,
        label: String? = nil,
        labelBehavior: LabelBehavior? = nil,
        errorDisplay: ErrorDisplay? = nil,
        unstyled: Bool? = nil,
        cvcIcon: CvcIcon? = nil
    ) {
        self.placeholder = placeholder
        self.label = label
        self.labelBehavior = labelBehavior
        self.errorDisplay = errorDisplay
        self.unstyled = unstyled
        self.cvcIcon = cvcIcon
    }

    internal var props: [String: Any] {
        var props: [String: Any] = [:]
        props["placeholder"] = placeholder
        props["label"] = label
        props["labelBehavior"] = labelBehavior?.rawValue
        props["errorDisplay"] = errorDisplay?.rawValue
        props["unstyled"] = unstyled
        props["cvcIcon"] = cvcIcon?.rawValue
        return props
    }
}
