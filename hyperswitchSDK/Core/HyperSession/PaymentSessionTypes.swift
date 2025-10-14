//
//  PaymentSessionTypes.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 30/08/24.
//

import Foundation

/// Represents card payment method details
public struct Card {
    public let scheme: String
    public let issuerCountry: String
    public let last4Digits: String
    public let expiryMonth: String
    public let expiryYear: String
    public let cardToken: String?
    public let cardHolderName: String
    public let cardFingerprint: String?
    public let nickName: String
    public let cardNetwork: String
    public let cardIsin: String
    public let cardIssuer: String
    public let cardType: String
    public let savedToLocker: Bool
    
    public func toHashMap() -> [String: Any?] {
        return [
            "scheme": scheme,
            "issuer_country": issuerCountry,
            "last4_digits": last4Digits,
            "expiry_month": expiryMonth,
            "expiry_year": expiryYear,
            "card_token": cardToken,
            "card_holder_name": cardHolderName,
            "card_fingerprint": cardFingerprint,
            "nick_name": nickName,
            "card_network": cardNetwork,
            "card_isin": cardIsin,
            "card_issuer": cardIssuer,
            "card_type": cardType,
            "saved_to_locker": savedToLocker
        ]
    }
}

/// Protocol defining payment method behavior
public protocol PaymentMethod {
    func toHashMap() -> [String: Any?]
}

/// Represents a valid payment method with all details
public struct PaymentMethodType: PaymentMethod {
    public let paymentToken: String
    public let paymentMethodId: String
    public let customerId: String
    public let paymentMethod: String
    public let paymentMethodType: String
    public let paymentMethodIssuer: String
    public let paymentMethodIssuerCode: String?
    public let recurringEnabled: Bool
    public let installmentPaymentEnabled: Bool
    public let paymentExperience: [String]
    public let card: Card?
    public let metadata: String?
    public let created: String
    public let bank: String?
    public let surchargeDetails: String?
    public let requiresCvv: Bool
    public let lastUsedAt: String
    public let defaultPaymentMethodSet: Bool
    
    public func toHashMap() -> [String: Any?] {
        return [
            "payment_token": paymentToken,
            "payment_method_id": paymentMethodId,
            "customer_id": customerId,
            "payment_method": paymentMethod,
            "payment_method_type": paymentMethodType,
            "payment_method_issuer": paymentMethodIssuer,
            "payment_method_issuer_code": paymentMethodIssuerCode,
            "recurring_enabled": recurringEnabled,
            "installment_payment_enabled": installmentPaymentEnabled,
            "payment_experience": paymentExperience,
            "card": card?.toHashMap(),
            "metadata": metadata,
            "created": created,
            "bank": bank,
            "surcharge_details": surchargeDetails,
            "requires_cvv": requiresCvv,
            "last_used_at": lastUsedAt,
            "default_payment_method_set": defaultPaymentMethodSet
        ]
    }
}

/// Represents an error state in payment method retrieval
public struct PMError: PaymentMethod {
    public let code: String
    public let message: String
    
    public func toHashMap() -> [String: Any?] {
        return [
            "code": code,
            "message": message
        ]
    }
}

/// Handler for payment session operations
public struct PaymentSessionHandler {
    public let getCustomerDefaultSavedPaymentMethodData: () -> PaymentMethod
    public let getCustomerLastUsedPaymentMethodData: () -> PaymentMethod
    public let getCustomerSavedPaymentMethodData: () -> [PaymentMethod]
    private let confirmWithCustomerDefaultPaymentMethod: (_ cvc: String?, _ resultHandler: @escaping (PaymentResult) -> Void) -> Void
    private let confirmWithCustomerLastUsedPaymentMethod: (_ cvc: String?, _ resultHandler: @escaping (PaymentResult) -> Void) -> Void
    private let confirmWithCustomerPaymentToken: (_ paymentToken: String, _ cvc: String?, _ resultHandler: @escaping (PaymentResult) -> Void) -> Void
    
    public init(
        getCustomerDefaultSavedPaymentMethodData: @escaping () -> PaymentMethod,
        getCustomerLastUsedPaymentMethodData: @escaping () -> PaymentMethod,
        getCustomerSavedPaymentMethodData: @escaping () -> [PaymentMethod],
        confirmWithCustomerDefaultPaymentMethod: @escaping (_ cvc: String?, _ resultHandler: @escaping (PaymentResult) -> Void) -> Void,
        confirmWithCustomerLastUsedPaymentMethod: @escaping (_ cvc: String?, _ resultHandler: @escaping (PaymentResult) -> Void) -> Void,
        confirmWithCustomerPaymentToken: @escaping (_ paymentToken: String, _ cvc: String?, _ resultHandler: @escaping (PaymentResult) -> Void) -> Void
    ) {
        self.getCustomerDefaultSavedPaymentMethodData = getCustomerDefaultSavedPaymentMethodData
        self.getCustomerLastUsedPaymentMethodData = getCustomerLastUsedPaymentMethodData
        self.getCustomerSavedPaymentMethodData = getCustomerSavedPaymentMethodData
        self.confirmWithCustomerDefaultPaymentMethod = confirmWithCustomerDefaultPaymentMethod
        self.confirmWithCustomerLastUsedPaymentMethod = confirmWithCustomerLastUsedPaymentMethod
        self.confirmWithCustomerPaymentToken = confirmWithCustomerPaymentToken
    }
    
    public func confirmWithCustomerDefaultPaymentMethod(resultHandler: @escaping (PaymentResult) -> Void) {
        confirmWithCustomerDefaultPaymentMethod(nil, resultHandler)
    }
    
    public func confirmWithCustomerLastUsedPaymentMethod(resultHandler: @escaping (PaymentResult) -> Void) {
        confirmWithCustomerLastUsedPaymentMethod(nil, resultHandler)
    }
    
    public func confirmWithCustomerPaymentToken(paymentToken: String, resultHandler: @escaping (PaymentResult) -> Void) {
        confirmWithCustomerPaymentToken(paymentToken, nil, resultHandler)
    }
}
