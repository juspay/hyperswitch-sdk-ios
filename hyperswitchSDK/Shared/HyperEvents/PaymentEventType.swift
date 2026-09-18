//
//  PaymentEventType.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 21/04/26.
//

import Foundation

public enum PaymentEventType: String, CaseIterable, Sendable {
    case cardDetailsChange = "cardDetailsChange"
    case paymentMethodChange = "paymentMethodChange"
    case formStatusChange = "formStatusChange"
    case billingDetailsChange = "billingDetailsChange"
    case cvcStatusChange = "cvcStatusChange"
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
