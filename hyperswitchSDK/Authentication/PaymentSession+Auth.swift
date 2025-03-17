//
//  PaymentSession+Auth.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 12/03/25.
//

import Juspay3DS

extension PaymentSession {
    public func initAuthenticationSession(
        paymentIntentClientSecret: String,
        logger: AuthenticationLoggerDelegate? = nil,
        uiCustomization: AuthenticationUICustomization? = nil,
        configParameters: AuthenticationConfigParameters = AuthenticationConfigParameters(),
        completion: @escaping (AuthenticationSession?) -> Void
    ) {
        
        guard let publishableKey = APIClient.shared.publishableKey else {
            return completion(nil)
        }
        
        AuthenticationSession.initAuthenticationSession(
            publishableKey: publishableKey,
            paymentIntentClientSecret: paymentIntentClientSecret,
            logger: logger,
            uiCustomization: uiCustomization,
            configParameters: configParameters,
            completion: completion
        )
    }
    
    public func initAuthenticationSession(
        paymentIntentClientSecret: String,
        merchantId: String,
        cardNetwork: String,
        messageVersion: String,
        logger: AuthenticationLoggerDelegate? = nil,
        uiCustomization: AuthenticationUICustomization? = nil,
        configParameters: AuthenticationConfigParameters = AuthenticationConfigParameters(),
        completion: @escaping (AuthenticationSession?) -> Void
    ) {
        
        guard let publishableKey = APIClient.shared.publishableKey else {
            return completion(nil)
        }
        
        AuthenticationSession.initAuthenticationSession(
            publishableKey: publishableKey,
            paymentIntentClientSecret: paymentIntentClientSecret,
            merchantId: merchantId,
            cardNetwork: cardNetwork,
            messageVersion: messageVersion,
            logger: logger,
            uiCustomization: uiCustomization,
            completion: completion)
    }
}
