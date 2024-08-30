//
//  PaymentSessionTypes.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 30/08/24.
//

import Foundation

public struct Card: PaymentMethod {
    public let isDefaultPaymentMethod: Bool
    public let paymentToken: String
    public let cardScheme: String
    public let name: String
    public let expiryDate: String
    public let cardNumber: String
    public let nickName: String
    public let cardHolderName: String
    public let requiresCVV: Bool
    public let created: String
    public let lastUsedAt: String
    
    public func toHashMap() -> [String: Any] {
        return [
            "isDefaultPaymentMethod": isDefaultPaymentMethod,
            "paymentToken": paymentToken,
            "cardScheme": cardScheme,
            "name": name,
            "expiryDate": expiryDate,
            "cardNumber": cardNumber,
            "nickName": nickName,
            "cardHolderName": cardHolderName,
            "requiresCVV": requiresCVV,
            "created": created,
            "lastUsedAt": lastUsedAt
        ]
    }
}

public struct Wallet: PaymentMethod {
    public let isDefaultPaymentMethod: Bool
    public let paymentToken: String
    public let walletType: String
    public let created: String
    public let lastUsedAt: String
    
    public func toHashMap() -> [String: Any] {
        return [
            "isDefaultPaymentMethod": isDefaultPaymentMethod,
            "paymentToken": paymentToken,
            "walletType": walletType,
            "created": created,
            "lastUsedAt": lastUsedAt
        ]
    }
}

public struct PMError: PaymentMethod {
    public let isDefaultPaymentMethod: Bool = false
    public let paymentToken: String = ""
    public let created: String = ""
    public let lastUsedAt: String = ""
    public let code: String
    public let message: String
    
    public func toHashMap() -> [String: Any] {
        return [
            "code": code,
            "message": message,
            "isDefaultPaymentMethod": isDefaultPaymentMethod,
            "paymentToken": paymentToken,
            "created": created,
            "lastUsedAt": lastUsedAt
        ]
    }
}

public struct PaymentSessionHandler {
    public let getCustomerDefaultSavedPaymentMethodData: () -> PaymentMethod
    public let getCustomerLastUsedPaymentMethodData: () -> PaymentMethod
    public let getCustomerSavedPaymentMethodData: () -> [PaymentMethod]
    private let confirmWithCustomerDefaultPaymentMethod: (_ cvc: String?, _ resultHandler: @escaping (PaymentResult) -> Void) -> Void
    private let confirmWithCustomerLastUsedPaymentMethod: (_ cvc: String?, _ resultHandler: @escaping (PaymentResult) -> Void) -> Void
    private let confirmWithCustomerPaymentToken: (_ paymentToken: String, _ cvc: String?, _ resultHandler: @escaping (PaymentResult) -> Void) -> Void
    
    init(
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

public protocol PaymentMethod {
    var isDefaultPaymentMethod: Bool { get }
    var paymentToken: String { get }
    var created: String { get }
    var lastUsedAt: String { get }
    func toHashMap() -> [String: Any]
}
