//
//  PaymentEventType.swift
//  Hyperswitch
//

import Foundation

public enum PaymentEventType: String, CaseIterable, Sendable {
    case paymentMethodInfoCard = "PAYMENT_METHOD_INFO_CARD"
    case paymentMethodStatus = "PAYMENT_METHOD_STATUS"
    case formStatus = "FORM_STATUS"
    case paymentMethodInfoBillingAddress = "PAYMENT_METHOD_INFO_BILLING_ADDRESS"
    case cvcStatus = "CVC_STATUS"
}

public struct PaymentEvent {
    public let type: String
    public let payload: [String: Any]

    public var data: PaymentEventData? {
        PaymentEventData.from(type: type, payload: payload)
    }

    public init(type: String, payload: [String: Any]) {
        self.type = type
        self.payload = payload
    }
}
