//
//  PaymentEventData.swift
//  Hyperswitch
//

import Foundation

public enum PaymentEventData {

    case cardInfo(CardInfo)
    case paymentMethodStatus(PaymentMethodStatus)
    case formStatus(FormStatusEvent)
    case paymentMethodInfoAddress(PaymentMethodInfoAddress)
    case cvcStatus(CvcStatus)

    public struct CardInfo: Sendable {
        public let bin: String?
        public let last4: String?
        public let brand: String?
        public let expiryMonth: String?
        public let expiryYear: String?
        public let formattedExpiry: String?
        public let isCardNumberComplete: Bool
        public let isCvcComplete: Bool
        public let isExpiryComplete: Bool
        public let isCardNumberValid: Bool
        public let isExpiryValid: Bool

        static func from(_ map: [String: Any]) -> CardInfo {
            CardInfo(
                bin: map["bin"] as? String,
                last4: map["last4"] as? String,
                brand: map["brand"] as? String,
                expiryMonth: map["expiryMonth"] as? String,
                expiryYear: map["expiryYear"] as? String,
                formattedExpiry: map["formattedExpiry"] as? String,
                isCardNumberComplete: map["isCardNumberComplete"] as? Bool ?? false,
                isCvcComplete: map["isCvcComplete"] as? Bool ?? false,
                isExpiryComplete: map["isExpiryComplete"] as? Bool ?? false,
                isCardNumberValid: map["isCardNumberValid"] as? Bool ?? false,
                isExpiryValid: map["isExpiryValid"] as? Bool ?? false
            )
        }
    }

    public struct PaymentMethodStatus: Sendable {
        public let paymentMethod: String
        public let paymentMethodType: String
        public let isSavedPaymentMethod: Bool
        public let isOneClickWallet: Bool

        static func from(_ map: [String: Any]) -> PaymentMethodStatus {
            PaymentMethodStatus(
                paymentMethod: map["paymentMethod"] as? String ?? "",
                paymentMethodType: map["paymentMethodType"] as? String ?? "",
                isSavedPaymentMethod: map["isSavedPaymentMethod"] as? Bool ?? false,
                isOneClickWallet: map["isOneClickWallet"] as? Bool ?? false
            )
        }
    }

    public enum FormStatusValue: String, Sendable {
        case empty = "EMPTY"
        case filling = "FILLING"
        case complete = "COMPLETE"
    }

    public struct FormStatusEvent: Sendable {
        public let status: FormStatusValue?

        static func from(_ map: [String: Any]) -> FormStatusEvent {
            FormStatusEvent(status: (map["status"] as? String).flatMap(FormStatusValue.init(rawValue:)))
        }
    }

    public struct PaymentMethodInfoAddress: Sendable {
        public let country: String
        public let state: String
        public let postalCode: String

        static func from(_ map: [String: Any]) -> PaymentMethodInfoAddress {
            PaymentMethodInfoAddress(
                country: map["country"] as? String ?? "",
                state: map["state"] as? String ?? "",
                postalCode: map["postalCode"] as? String ?? ""
            )
        }
    }

    public struct CvcStatus: Sendable {
        public let isCvcFocused: Bool
        public let isCvcBlur: Bool
        public let isCvcEmpty: Bool

        static func from(_ map: [String: Any]) -> CvcStatus {
            let source = (map["cvcStatus"] as? [String: Any]) ?? map
            return CvcStatus(
                isCvcFocused: source["isCvcFocused"] as? Bool ?? false,
                isCvcBlur: source["isCvcBlur"] as? Bool ?? false,
                isCvcEmpty: source["isCvcEmpty"] as? Bool ?? true
            )
        }
    }

    public static func from(type: String, payload: [String: Any]) -> PaymentEventData? {
        switch type {
        case PaymentEventType.paymentMethodInfoCard.rawValue:
            return .cardInfo(.from(payload))
        case PaymentEventType.paymentMethodStatus.rawValue:
            return .paymentMethodStatus(.from(payload))
        case PaymentEventType.formStatus.rawValue:
            return .formStatus(.from(payload))
        case PaymentEventType.paymentMethodInfoBillingAddress.rawValue:
            return .paymentMethodInfoAddress(.from(payload))
        case PaymentEventType.cvcStatus.rawValue:
            return .cvcStatus(.from(payload))
        default:
            return nil
        }
    }
}
