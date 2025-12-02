//
//  ClickToPayModels.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 31/10/25.
//

import Foundation

// MARK: - Customer Presence Request

/// Request to check if a customer has an existing Click to Pay profile
public struct CustomerPresenceRequest {
    public let email: String?
    public let mobileNumber: MobileNumber?

    public init(email: String? = nil, mobileNumber: MobileNumber? = nil) {
        self.email = email
        self.mobileNumber = mobileNumber
    }
}

/// Mobile number details for customer identification
public struct MobileNumber {
    public let countryCode: String
    public let phoneNumber: String

    public init(countryCode: String, phoneNumber: String) {
        self.countryCode = countryCode
        self.phoneNumber = phoneNumber
    }
}

// MARK: - Customer Presence Response

/// Response indicating if customer has a Click to Pay profile
public struct CustomerPresenceResponse: Codable {
    public let customerPresent: Bool
}

// MARK: - Cards Status Response

/// Response containing the status of card retrieval
public struct CardsStatusResponse: Codable {
    public let statusCode: StatusCode

    enum CodingKeys: String, CodingKey {
        case statusCode
    }
}

/// Status codes for card retrieval
public enum StatusCode: String, Codable, CaseIterable {
    case triggeredCustomerAuthentication = "TRIGGERED_CUSTOMER_AUTHENTICATION"
    case noCardsPresent = "NO_CARDS_PRESENT"
    case recognizedCardsPresent = "RECOGNIZED_CARDS_PRESENT"
}

// MARK: - Recognized Card Models

/// Represents a recognized card in Click to Pay
public struct RecognizedCard : Codable {
    public let countryCode: String?
    public let dateOfCardCreated: String?
    public let dateOfCardLastUsed: String?
    public let dcf: DCF?
    public let digitalCardData: DigitalCardData?
    public let digitalCardFeatures: DigitalCardFeatures?
    public let maskedBillingAddress: MaskedBillingAddress?
    public let panBin: String?
    public let panExpirationMonth: String?
    public let panExpirationYear: String?
    public let panLastFour: String?
    public let paymentAccountReference: String?
    public let paymentCardDescriptor: CardType?
    public let paymentCardType: String?
    public let srcDigitalCardId: String
    public let tokenBinRange: String?
    public let tokenLastFour: String?
}

public struct DCF: Codable {
    public let logoUri: String?
    public let name: String?
    public let uri: String?
}

public struct DigitalCardFeatures: Codable {
    // Empty object in the JSON, but keeping as struct for future extensibility
}

/// Digital card metadata
public struct DigitalCardData: Codable {
    public let status: String?
    public let presentationName: String?
    public let descriptorName: String?
    public let artUri: String?
    public let artHeight: Int?
    public let artWidth: Int?
    public let authenticationMethods: [AuthenticationMethod]?
    public let pendingEvents: [String]?
}

public struct AuthenticationMethod: Codable {
    public let authenticationMethodType: String
}

/// Masked billing address for a card
public struct MaskedBillingAddress: Codable {
    public let addressId: String?
    public let name: String?
    public let line1: String?
    public let line2: String?
    public let line3: String?
    public let city: String?
    public let state: String?
    public let countryCode: String?
    public let zip: String?
}

public enum CardType: String, Codable, CaseIterable {
    case visa = "VISA"
    case mastercard = "MASTERCARD"
    case unknown = "UNKNOWN"
}

// MARK: - Sign Out Response

public struct SignOutResponse {
    public let recognized : Bool
}

// MARK: - Checkout Request

/// Request to checkout with a selected card
public struct CheckoutRequest: Codable {
    public let srcDigitalCardId: String
    public let rememberMe: Bool?

    public init(srcDigitalCardId: String, rememberMe: Bool = false) {
        self.srcDigitalCardId = srcDigitalCardId
        self.rememberMe = rememberMe
    }
}

// MARK: - Checkout Response

/// Response from checkout operation
public struct CheckoutResponse: Codable {
    public let authenticationId: String?
    public let merchantId: String?
    public let status: AuthenticationStatus?
    public let clientSecret: String?
    public let amount: Int?
    public let currency: String?
    public let authenticationConnector: String?
    public let force3dsChallenge: Bool?
    public let returnUrl: String?
    public let createdAt: String?
    public let profileId: String?
    public let psd2ScaExemptionType: String?
    public let acquirerDetails: AcquirerDetails?
    public let threedsServerTransactionId: String?
    public let maximumSupported3dsVersion: String?
    public let connectorAuthenticationId: String?
    public let threeDsMethodData: String?
    public let threeDsMethodUrl: String?
    public let messageVersion: String?
    public let connectorMetadata: String?
    public let directoryServerId: String?
    public let vaultTokenData: PaymentData?
    public let paymentMethodData: PaymentData?
    public let billing: String?
    public let shipping: String?
    public let browserInformation: String?
    public let email: String?
    public let transStatus: String?
    public let acsUrl: String?
    public let challengeRequest: String?
    public let acsReferenceNumber: String?
    public let acsTransId: String?
    public let acsSignedContent: String?
    public let threeDsRequestorUrl: String?
    public let threeDsRequestorAppUrl: String?
    public let eci: String?
    public let errorMessage: String?
    public let errorCode: String?
    public let profileAcquirerId: String?
}

/// Authentication status enum
public enum AuthenticationStatus: String, Codable {
    case success
    case failed
    case pending
}

/// Acquirer details for the transaction
public struct AcquirerDetails: Codable {
    public let acquirerBin: String?
    public let acquirerMerchantId: String?
    public let merchantCountryCode: String?
}

/// Card Data
public struct CardData: Codable {
    public let cardNumber: String?
    public let cardCvc: String?
    public let cardExpiryMonth: String?
    public let cardExpiryYear: String?
    public let type: String
}

/// Network Token Data
public struct NetworkTokenData: Codable {
    public let networkToken: String?
    public let networkTokenCryptogram: String?
    public let networkTokenExpiryMonth: String?
    public let networkTokenExpiryYear: String?
    public let type: String
}

/// Payment Data
public enum PaymentData: Codable {
    case cardData(CardData)
    case networkTokenData(NetworkTokenData)

    enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "card_data":
            self = .cardData(try CardData(from: decoder))
        case "network_token_data":
            self = .networkTokenData(try NetworkTokenData(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown type: \(type)"
            )
        }
    }
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .cardData(let data):
            try data.encode(to: encoder)
        case .networkTokenData(let data):
            try data.encode(to: encoder)
        }
    }
}

// MARK: - Error Model

/// Error types for Click to Pay operations
public enum ClickToPayErrorType: String, Codable {
    // Get User Type errors
    case authInvalid = "AUTH_INVALID"
    case acctInaccessible = "ACCT_INACCESSIBLE"
    case acctFraud = "ACCT_FRAUD"
    case consumerIdMissing = "CONSUMER_ID_MISSING"
    case consumerIdFormatUnsupported = "CONSUMER_ID_FORMAT_UNSUPPORTED"
    case consumerIdFormatInvalid = "CONSUMER_ID_FORMAT_INVALID"

    // Validate Customer Authentication errors
    case otpSendFailed = "OTP_SEND_FAILED"
    case validationDataMissing = "VALIDATION_DATA_MISSING"
    case validationDataExpired = "VALIDATION_DATA_EXPIRED"
    case validationDataInvalid = "VALIDATION_DATA_INVALID"
    case retriesExceeded = "RETRIES_EXCEEDED"

    // Standard errors
    case unknownError = "UNKNOWN_ERROR"
    case requestTimeout = "REQUEST_TIMEOUT"
    case serverError = "SERVER_ERROR"
    case invalidParameter = "INVALID_PARAMETER"
    case invalidRequest = "INVALID_REQUEST"
    case authError = "AUTH_ERROR"
    case notFound = "NOT_FOUND"
    case rateLimitExceeded = "RATE_LIMIT_EXCEEDED"
    case serviceError = "SERVICE_ERROR"

    // SDK errors
    case scriptLoadError = "SCRIPT_LOAD_ERROR"
    case hyperUndefinedError = "HYPER_UNDEFINED_ERROR"
    case hyperInitializationError = "HYPER_INITIALIZATION_ERROR"
    case initClickToPaySessionError = "INIT_CLICK_TO_PAY_SESSION_ERROR"
    case isCustomerPresentError = "IS_CUSTOMER_PRESENT_ERROR"
    case getRecognizedCardsError = "GET_RECOGNIZED_CARDS_ERROR"
    case checkoutWithCardError = "CHECKOUT_WITH_CARD_ERROR"
    
    // Fallback
    case error = "ERROR"

    // Checkout errors
    case changeCard = "CHANGE_CARD"
    case switchConsumer = "SWITCH_CONSUMER"
}

/// Click to Pay exception with error details
public class ClickToPayException: Error, LocalizedError {
    public let message: String
    public let type: ClickToPayErrorType

    public init(message: String, type: ClickToPayErrorType) {
        self.message = message
        self.type = type
    }

    public var errorDescription: String? {
        return message
    }
}
