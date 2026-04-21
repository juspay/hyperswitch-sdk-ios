//
//  PaymentSession.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 07/03/24.
//

import Foundation

@frozen public enum PaymentResult {
    case completed(data: String)
    case canceled(data: String)
    case failed(error: Error)
}

public class PaymentSession {

    internal var sdkAuthorization: String?
    internal var ephemeralKey: String?

    public init(
        publishableKey: String,
        profileId: String,
        customBackendUrl: String? = nil,
        customParams: [String: Any]? = nil,
        customLogUrl: String? = nil
    ) {
        APIClient.shared.publishableKey = publishableKey
        APIClient.shared.profileId = profileId
        APIClient.shared.customBackendUrl = customBackendUrl
        APIClient.shared.customLogUrl = customLogUrl
        APIClient.shared.customParams = customParams

        #if canImport(HyperOTA)
        OTAServices.shared.initialize(publishableKey: publishableKey)
        LogManager.initialize(publishableKey: publishableKey)
        #endif
    }

    public func initPaymentSession(sdkAuthorization: String) {
        self.sdkAuthorization = sdkAuthorization
    }

    public func initPaymentManagementSession(ephemeralKey: String, sdkAuthorization: String? = nil) {
        self.ephemeralKey = ephemeralKey
        self.sdkAuthorization = sdkAuthorization
    }
}
