//
//  ClickToPayModels.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 31/10/25.
//

import Foundation

// MARK: - Customer Presence Models

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

/// Response indicating if customer has a Click to Pay profile
public struct CustomerPresenceResponse: Codable {
    public let customerPresent: Bool
    
    enum CodingKeys: String, CodingKey {
        case customerPresent
    }
}

// MARK: - Cards Status Models

/// Status codes for card retrieval
public enum StatusCode: String, Codable, CaseIterable {
    case triggeredCustomerAuthentication = "TRIGGERED_CUSTOMER_AUTHENTICATION"
    case noCardsPresent = "NO_CARDS_PRESENT"
    case recognizedCardsPresent = "RECOGNIZED_CARDS_PRESENT"
}

/// Response containing the status of card retrieval
public struct CardsStatusResponse: Codable {
    public let statusCode: StatusCode
    
    enum CodingKeys: String, CodingKey {
        case statusCode
    }
}

// MARK: - Recognized Card Models

/// Represents a recognized card in Click to Pay
public struct RecognizedCard : Codable {
    let countryCode: String?
    let dateOfCardCreated: String?
    let dateOfCardLastUsed: String?
    let dcf: DCF?
    let digitalCardData: DigitalCardData?
    let digitalCardFeatures: DigitalCardFeatures?
    let maskedBillingAddress: MaskedBillingAddress?
    let panBin: String?
    let panExpirationMonth: String?
    let panExpirationYear: String?
    let panLastFour: String?
    let paymentCardDescriptor: String?
    let paymentCardType: String?
    let srcDigitalCardId: String
    let tokenLastFour: String?
}

struct DCF: Codable {
    let logoUri: String?
    let name: String?
    let uri: String?
}

struct DigitalCardFeatures: Codable {
    // Empty object in the JSON, but keeping as struct for future extensibility
}

/// Digital card metadata
public struct DigitalCardData: Codable {
    public let status: String?
    public let presentationName: String?
    public let descriptorName: String?
    public let artUri: String?

    enum CodingKeys: String, CodingKey {
        case status
        case presentationName
        case descriptorName
        case artUri
    }
}

/// Masked billing address for a card
public struct MaskedBillingAddress: Codable {
    public let name: String?
    public let line1: String?
    public let city: String?
    public let state: String?
    public let countryCode: String?
    public let zip: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case line1
        case city
        case state
        case countryCode
        case zip
    }
}

// MARK: - Checkout Models

/// Request to checkout with a selected card
public struct CheckoutRequest {
    public let srcDigitalCardId: String
    public let rememberMe: Bool?

    public init(srcDigitalCardId: String, rememberMe: Bool = false) {
        self.srcDigitalCardId = srcDigitalCardId
        self.rememberMe = rememberMe
    }
}

/// Response from checkout operation
public struct CheckoutResponse: Codable {
    public let authenticationId: String?
    public let merchantId: String?
    public let status: String?
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
    public let tokenData: TokenData?
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
    
    enum CodingKeys: String, CodingKey {
        case authenticationId = "authentication_id"
        case merchantId = "merchant_id"
        case status
        case clientSecret = "client_secret"
        case amount
        case currency
        case authenticationConnector = "authentication_connector"
        case force3dsChallenge = "force_3ds_challenge"
        case returnUrl = "return_url"
        case createdAt = "created_at"
        case profileId = "profile_id"
        case psd2ScaExemptionType = "psd2_sca_exemption_type"
        case acquirerDetails = "acquirer_details"
        case threedsServerTransactionId = "threeds_server_transaction_id"
        case maximumSupported3dsVersion = "maximum_supported_3ds_version"
        case connectorAuthenticationId = "connector_authentication_id"
        case threeDsMethodData = "three_ds_method_data"
        case threeDsMethodUrl = "three_ds_method_url"
        case messageVersion = "message_version"
        case connectorMetadata = "connector_metadata"
        case directoryServerId = "directory_server_id"
        case tokenData = "token_data"
        case billing
        case shipping
        case browserInformation = "browser_information"
        case email
        case transStatus = "trans_status"
        case acsUrl = "acs_url"
        case challengeRequest = "challenge_request"
        case acsReferenceNumber = "acs_reference_number"
        case acsTransId = "acs_trans_id"
        case acsSignedContent = "acs_signed_content"
        case threeDsRequestorUrl = "three_ds_requestor_url"
        case threeDsRequestorAppUrl = "three_ds_requestor_app_url"
        case eci
        case errorMessage = "error_message"
        case errorCode = "error_code"
        case profileAcquirerId = "profile_acquirer_id"
    }
}

/// Acquirer details for the transaction
public struct AcquirerDetails: Codable {
    public let acquirerBin: String?
    public let acquirerMerchantId: String?
    public let merchantCountryCode: String?
    
    enum CodingKeys: String, CodingKey {
        case acquirerBin = "acquirer_bin"
        case acquirerMerchantId = "acquirer_merchant_id"
        case merchantCountryCode = "merchant_country_code"
    }
}

/// Token data returned after successful checkout
public struct TokenData: Codable {
    public let paymentToken: String?
    public let tokenCryptogram: String?
    public let tokenExpirationMonth: String?
    public let tokenExpirationYear: String?

    enum CodingKeys: String, CodingKey {
        case paymentToken = "payment_token"
        case tokenCryptogram = "token_cryptogram"
        case tokenExpirationMonth = "token_expiration_month"
        case tokenExpirationYear = "token_expiration_year"
    }
}


