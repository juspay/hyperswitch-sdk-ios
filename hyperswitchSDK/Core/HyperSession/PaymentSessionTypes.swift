//
//  PaymentSessionTypes.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 30/08/24.
//

import Foundation

/// Represents a valid payment method with all details
public struct PaymentMethod: Codable {
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

    enum CodingKeys: String, CodingKey {
        case paymentToken = "payment_token"
        case paymentMethodId = "payment_method_id"
        case customerId = "customer_id"
        case paymentMethod = "payment_method"
        case paymentMethodType = "payment_method_type"
        case paymentMethodIssuer = "payment_method_issuer"
        case paymentMethodIssuerCode = "payment_method_issuer_code"
        case recurringEnabled = "recurring_enabled"
        case installmentPaymentEnabled = "installment_payment_enabled"
        case paymentExperience = "payment_experience"
        case card
        case metadata
        case created
        case bank
        case surchargeDetails = "surcharge_details"
        case requiresCvv = "requires_cvv"
        case lastUsedAt = "last_used_at"
        case defaultPaymentMethodSet = "default_payment_method_set"
    }
}

/// Represents card payment method details
public struct Card: Codable {
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

    enum CodingKeys: String, CodingKey {
        case scheme
        case issuerCountry = "issuer_country"
        case last4Digits = "last4_digits"
        case expiryMonth = "expiry_month"
        case expiryYear = "expiry_year"
        case cardToken = "card_token"
        case cardHolderName = "card_holder_name"
        case cardFingerprint = "card_fingerprint"
        case nickName = "nick_name"
        case cardNetwork = "card_network"
        case cardIsin = "card_isin"
        case cardIssuer = "card_issuer"
        case cardType = "card_type"
        case savedToLocker = "saved_to_locker"
    }
}

/// Represents an error state in payment method retrieval
public struct PMError: Error {
    public let code: String
    public let message: String
}

/// Handler for payment session operations
public struct PaymentSessionHandler {
    public let getCustomerDefaultSavedPaymentMethodData: () -> Result<PaymentMethod, PMError>
    public let getCustomerLastUsedPaymentMethodData: () -> Result<PaymentMethod, PMError>
    public let getCustomerSavedPaymentMethodData: () -> Result<[PaymentMethod], PMError>
    private let confirmWithCustomerDefaultPaymentMethod: (_ cvc: String?, _ resultHandler: @escaping (PaymentResult) -> Void) -> Void
    private let confirmWithCustomerLastUsedPaymentMethod: (_ cvc: String?, _ resultHandler: @escaping (PaymentResult) -> Void) -> Void
    private let confirmWithCustomerPaymentToken: (_ paymentToken: String, _ cvc: String?, _ resultHandler: @escaping (PaymentResult) -> Void) -> Void
    
    public init(
        getCustomerDefaultSavedPaymentMethodData: @escaping () -> Result<PaymentMethod, PMError>,
        getCustomerLastUsedPaymentMethodData: @escaping () -> Result<PaymentMethod, PMError>,
        getCustomerSavedPaymentMethodData: @escaping () -> Result<[PaymentMethod], PMError>,
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
