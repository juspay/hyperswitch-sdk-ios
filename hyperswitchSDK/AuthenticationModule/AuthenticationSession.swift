//
//  AuthenticationSession.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 31/10/25.
//

import Foundation

public class AuthenticationSession {
    private var authIntentClientSecret: String?
    private var authConfiguration: AuthenticationConfiguration?
    private var threeDSProvider: ThreeDSProvider?
    private var sessionProvider: ThreeDSSessionProvider?
    private var publishableKey: String
    private var customBackendUrl: String?
    private var customParams: [String: Any]?
    private var customLogUrl: String?
    
    private var clientSecret: String?
    private var profileId: String?
    private var authenticationId: String?
    private var merchantId: String?
    
    
    public init(publishableKey: String, customBackendUrl: String? = nil, customParams: [String : Any]? = nil, customLogUrl: String? = nil) {
        self.publishableKey = publishableKey
        self.customBackendUrl = customBackendUrl
        self.customLogUrl = customLogUrl
        self.customParams = customParams
        
        APIClient.shared.publishableKey = publishableKey
        APIClient.shared.customBackendUrl = customBackendUrl
        APIClient.shared.customLogUrl = customLogUrl
        APIClient.shared.customParams = customParams
    }
    
    public func initAuthenticationSession(clientSecret: String, profileId: String, authenticationId: String, merchantId: String) {
        self.clientSecret = clientSecret
        self.profileId = profileId
        self.authenticationId = authenticationId
        self.merchantId = merchantId
    }
    
    public func initThreeDSSession(authIntentClientSecret: String, configuration: AuthenticationConfiguration? = nil) async throws -> ThreeDSSession {
        self.authIntentClientSecret = authIntentClientSecret
        self.authConfiguration = configuration
        
        do {
            self.threeDSProvider = try ThreeDSProviderFactory.createProvider(preferredProvider: configuration?.preferredProvider)
            try await self.threeDSProvider?.initialize(configuration: configuration)
            
            guard let sessionProvider = try self.threeDSProvider?.createSession() else {
                throw TransactionError.transactionCreationFailed("Failed to create session provider.", nil)
            }
            
            return ThreeDSSession(sessionProvider: sessionProvider)
        }
        catch {
            self.threeDSProvider = nil
            self.sessionProvider = nil
            throw error
        }
    }
    
    public func initClickToPaySession(request3DSAuthentication: Bool?) async throws -> ClickToPaySession {
        let clickToPaySession = await ClickToPaySession(
            publishableKey: publishableKey,
            customBackendUrl: customBackendUrl,
            customLogUrl: customLogUrl,
            customParams: customParams
        )
        do {
            guard let clientSecret = clientSecret,
                  let profileId = profileId,
                  let authenticationId = authenticationId,
                  let merchantId = merchantId else {
                throw NSError(domain: "ClickToPay", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
            }
            
            try await clickToPaySession.initClickToPaySession(clientSecret: clientSecret, profileId: profileId, authenticationId: authenticationId, merchantId: merchantId, request3DSAuthentication: request3DSAuthentication ?? true)
        }
        catch {
            throw NSError(domain: "ClickToPay", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }
        return clickToPaySession
    }
}
