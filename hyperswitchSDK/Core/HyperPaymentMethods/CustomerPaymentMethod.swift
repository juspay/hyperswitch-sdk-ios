//
//  CustomerPaymentMethod.swift
//  hyperswitch
//
//  Wire model of the customer payment methods API.
//

import Foundation

/// One entry of the `customer_payment_methods` array returned by the
/// customer payment methods API.
///
/// ```json
/// {
///   "payment_method_token": "7ebf443f-a050-4067-84e5-e6f6d4800aef",
///   "customer_id": "0a_cus_...",
///   "payment_method_type": "card",
///   "payment_method_subtype": "ach",
///   "recurring_enabled": true,
///   "created": "2023-01-18T11:04:09.922Z",
///   "requires_cvv": true,
///   "last_used_at": "2024-02-24T11:04:09.922Z",
///   "is_default": true,
///   "payment_method_data": { "card": { ... } },
///   "bank": { ... },
///   "billing": { ... }
/// }
/// ```
public struct CustomerPaymentMethod: Codable {

    public let paymentMethodToken: String
    public let customerId: String
    public let paymentMethodType: String
    public let paymentMethodSubtype: String?
    public let recurringEnabled: Bool
    public let created: String?
    public let requiresCvv: Bool
    public let lastUsedAt: String?
    public let isDefault: Bool
    public let paymentMethodData: PaymentMethodData?
    public let bank: BankData?
    public let billing: BillingData?

    /// `payment_method_data` wrapper — currently only `card` payloads.
    public struct PaymentMethodData: Codable {
        public let card: CardData?
    }

    /// Card details nested inside `payment_method_data.card`.
    public struct CardData: Codable {
        public let savedToLocker: Bool
        public let issuerCountry: String?
        public let last4Digits: String?
        public let expiryMonth: String?
        public let expiryYear: String?
        public let cardHolderName: String?
        public let cardFingerprint: String?
        public let nickName: String?
        public let cardNetwork: String?
        public let cardIsin: String?
        public let cardIssuer: String?
        public let cardType: String?
        public let cardSubtype: String?
        public let cardSegmentType: String?
        public let fundingSource: String?

        private enum CodingKeys: String, CodingKey {
            case savedToLocker = "saved_to_locker"
            case issuerCountry = "issuer_country"
            case last4Digits = "last4_digits"
            case expiryMonth = "expiry_month"
            case expiryYear = "expiry_year"
            case cardHolderName = "card_holder_name"
            case cardFingerprint = "card_fingerprint"
            case nickName = "nick_name"
            case cardNetwork = "card_network"
            case cardIsin = "card_isin"
            case cardIssuer = "card_issuer"
            case cardType = "card_type"
            case cardSubtype = "card_subtype"
            case cardSegmentType = "card_segment_type"
            case fundingSource = "funding_source"
        }
    }

    /// Bank account details (top-level sibling of `payment_method_data`).
    public struct BankData: Codable {
        public let mask: String?
        public let accountHolderName: String?
        public let bankName: String?

        private enum CodingKeys: String, CodingKey {
            case mask
            case accountHolderName = "account_holder_name"
            case bankName = "bank_name"
        }
    }

    /// Billing block (top-level sibling of `payment_method_data`).
    public struct BillingData: Codable {
        public let address: AddressData?
        public let phone: PhoneData?
        public let email: String?
    }

    public struct AddressData: Codable {
        public let city: String?
        public let country: String?
        public let line1: String?
        public let line2: String?
        public let line3: String?
        public let zip: String?
        public let state: String?
        public let firstName: String?
        public let lastName: String?
        public let originZip: String?

        private enum CodingKeys: String, CodingKey {
            case city, country, line1, line2, line3, zip, state
            case firstName = "first_name"
            case lastName = "last_name"
            case originZip = "origin_zip"
        }
    }

    public struct PhoneData: Codable {
        public let number: String?
        public let countryCode: String?

        private enum CodingKeys: String, CodingKey {
            case number
            case countryCode = "country_code"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case paymentMethodToken = "payment_method_token"
        case customerId = "customer_id"
        case paymentMethodType = "payment_method_type"
        case paymentMethodSubtype = "payment_method_subtype"
        case recurringEnabled = "recurring_enabled"
        case created
        case requiresCvv = "requires_cvv"
        case lastUsedAt = "last_used_at"
        case isDefault = "is_default"
        case paymentMethodData = "payment_method_data"
        case bank, billing
    }
}
