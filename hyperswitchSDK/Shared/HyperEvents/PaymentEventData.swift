//
//  PaymentEventData.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 21/04/26.
//

import Foundation
import CoreFoundation

public enum PaymentEventData: Sendable {

    case cardDetailsChange(CardDetailsChange)
    case paymentMethodChange(PaymentMethodChange)
    case formStatusChange(FormStatusChange)
    case billingDetailsChange(BillingDetailsChange)
    case cvcStatusChange(CvcStatusChange)

    /// JSON representation for wrapper bridges.
    public func toDictionary() -> [String: Any] {
        switch self {
        case .cardDetailsChange(let data): return data.toDictionary()
        case .paymentMethodChange(let data): return data.toDictionary()
        case .formStatusChange(let data): return data.toDictionary()
        case .billingDetailsChange(let data): return data.toDictionary()
        case .cvcStatusChange(let data): return data.toDictionary()
        }
    }

    public struct CardDetailsChange: Sendable {
        public let bin: String?
        public let extendedBin: String?
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

        static func from(_ map: [String: Any]) throws -> CardDetailsChange {
            let reader = PayloadReader(values: map)
            return CardDetailsChange(
                bin: try reader.nullableString("bin"),
                extendedBin: try reader.nullableString("extendedBin"),
                last4: try reader.nullableString("last4"),
                brand: try reader.nullableString("brand"),
                expiryMonth: try reader.nullableString("expiryMonth"),
                expiryYear: try reader.nullableString("expiryYear"),
                formattedExpiry: try reader.nullableString("formattedExpiry"),
                isCardNumberComplete: try reader.boolean("isCardNumberComplete"),
                isCvcComplete: try reader.boolean("isCvcComplete"),
                isExpiryComplete: try reader.boolean("isExpiryComplete"),
                isCardNumberValid: try reader.boolean("isCardNumberValid"),
                isExpiryValid: try reader.boolean("isExpiryValid")
            )
        }

        fileprivate func toDictionary() -> [String: Any] {
            [
                "bin": bin.map { $0 as Any } ?? NSNull(),
                "extendedBin": extendedBin.map { $0 as Any } ?? NSNull(),
                "last4": last4.map { $0 as Any } ?? NSNull(),
                "brand": brand.map { $0 as Any } ?? NSNull(),
                "expiryMonth": expiryMonth.map { $0 as Any } ?? NSNull(),
                "expiryYear": expiryYear.map { $0 as Any } ?? NSNull(),
                "formattedExpiry": formattedExpiry.map { $0 as Any } ?? NSNull(),
                "isCardNumberComplete": isCardNumberComplete,
                "isCardNumberValid": isCardNumberValid,
                "isExpiryComplete": isExpiryComplete,
                "isExpiryValid": isExpiryValid,
                "isCvcComplete": isCvcComplete
            ]
        }
    }

    public struct PaymentMethodChange: Sendable {
        public let paymentMethod: String
        public let paymentMethodType: String
        public let isSavedPaymentMethod: Bool
        public let isOneClickWallet: Bool

        static func from(_ map: [String: Any]) throws -> PaymentMethodChange {
            let reader = PayloadReader(values: map)
            return PaymentMethodChange(
                paymentMethod: try reader.string("paymentMethod"),
                paymentMethodType: try reader.string("paymentMethodType"),
                isSavedPaymentMethod: try reader.boolean("isSavedPaymentMethod"),
                isOneClickWallet: try reader.boolean("isOneClickWallet")
            )
        }

        fileprivate func toDictionary() -> [String: Any] {
            [
                "paymentMethod": paymentMethod,
                "paymentMethodType": paymentMethodType,
                "isSavedPaymentMethod": isSavedPaymentMethod,
                "isOneClickWallet": isOneClickWallet
            ]
        }
    }

    public enum FormStatusValue: String, Sendable {
        case empty = "EMPTY"
        case filling = "FILLING"
        case complete = "COMPLETE"
    }

    public struct FormStatusChange: Sendable {
        public let status: FormStatusValue

        static func from(_ map: [String: Any]) throws -> FormStatusChange {
            let reader = PayloadReader(values: map)
            return FormStatusChange(
                status: try reader.formStatus()
            )
        }

        fileprivate func toDictionary() -> [String: Any] {
            [
                "status": status.rawValue
            ]
        }
    }

    public struct BillingDetailsChange: Sendable {
        public let country: String?
        public let state: String?
        public let postalCode: String?

        static func from(_ map: [String: Any]) throws -> BillingDetailsChange {
            let reader = PayloadReader(values: map)
            return BillingDetailsChange(
                country: try reader.nullableString("country"),
                state: try reader.nullableString("state"),
                postalCode: try reader.nullableString("postalCode")
            )
        }

        fileprivate func toDictionary() -> [String: Any] {
            [
                "country": country.map { $0 as Any } ?? NSNull(),
                "state": state.map { $0 as Any } ?? NSNull(),
                "postalCode": postalCode.map { $0 as Any } ?? NSNull()
            ]
        }
    }

    public struct CvcStatusChange: Sendable {
        public let cvcStatus: CvcStatusDetails

        static func from(_ map: [String: Any]) throws -> CvcStatusChange {
            let reader = PayloadReader(values: map)
            return CvcStatusChange(
                cvcStatus: try reader.cvcStatus()
            )
        }

        fileprivate func toDictionary() -> [String: Any] {
            [
                "cvcStatus": ["isCvcEmpty": cvcStatus.isCvcEmpty, "isCvcComplete": cvcStatus.isCvcComplete]
            ]
        }
    }

    public struct CvcStatusDetails: Sendable {
        public let isCvcEmpty: Bool
        public let isCvcComplete: Bool
    }

    static func from(type: PaymentEventType, payload: [String: Any]) -> PaymentEventData? {
        do {
            switch type {
            case .cardDetailsChange: return .cardDetailsChange(try .from(payload))
            case .paymentMethodChange: return .paymentMethodChange(try .from(payload))
            case .formStatusChange: return .formStatusChange(try .from(payload))
            case .billingDetailsChange: return .billingDetailsChange(try .from(payload))
            case .cvcStatusChange: return .cvcStatusChange(try .from(payload))
            }
        } catch {
            return nil
        }
    }
}

private enum PayloadError: Error { case invalidField }

private struct PayloadReader {
    let values: [String: Any]

    func nullableString(_ key: String) throws -> String? {
        guard let value = values[key] else { throw PayloadError.invalidField }
        if value is NSNull { return nil }
        guard let text = value as? String else { throw PayloadError.invalidField }
        return text
    }

    func string(_ key: String) throws -> String {
        guard let value = values[key] as? String else { throw PayloadError.invalidField }
        return value
    }

    func boolean(_ key: String) throws -> Bool {
        guard let value = values[key] as? NSNumber,
              CFGetTypeID(value) == CFBooleanGetTypeID() else { throw PayloadError.invalidField }
        return value.boolValue
    }

    func formStatus() throws -> PaymentEventData.FormStatusValue {
        guard let value = PaymentEventData.FormStatusValue(rawValue: try string("status")) else {
            throw PayloadError.invalidField
        }
        return value
    }

    func cvcStatus() throws -> PaymentEventData.CvcStatusDetails {
        guard let value = values["cvcStatus"] as? [String: Any] else { throw PayloadError.invalidField }
        let reader = PayloadReader(values: value)
        return PaymentEventData.CvcStatusDetails(
            isCvcEmpty: try reader.boolean("isCvcEmpty"),
            isCvcComplete: try reader.boolean("isCvcComplete")
        )
    }
}
