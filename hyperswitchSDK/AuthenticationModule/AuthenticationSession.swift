//
//  AuthenticationSession.swift
//  AuthenticationSdk
//
//  Created by Shivam Nan on 01/09/25.
//

import Foundation

public class AuthenticationSession {
    private var authIntentClientSecret: String?
    private var authConfiguration: AuthenticationConfiguration?
    private var threeDSProvider: ThreeDSProvider?
    private var sessionProvider: ThreeDSSessionProvider?
    
    public init(publishableKey: String, customBackendUrl: String? = nil, customParams: [String : Any]? = nil, customLogUrl: String? = nil) {
        APIClient.shared.publishableKey = publishableKey
        APIClient.shared.customBackendUrl = customBackendUrl
        APIClient.shared.customLogUrl = customLogUrl
        APIClient.shared.customParams = customParams
    }
    
    public func initThreeDsSession(authIntentClientSecret: String, configuration: AuthenticationConfiguration? = nil) async throws {
        self.authIntentClientSecret = authIntentClientSecret
        self.authConfiguration = configuration
        
        do {
            self.threeDSProvider = try ThreeDSProviderFactory.createProvider(preferredProvider: configuration?.preferredProvider)
            try await self.threeDSProvider?.initialize(configuration: configuration)
            self.sessionProvider = try self.threeDSProvider?.createSession()
        } catch {
            self.threeDSProvider = nil
            self.sessionProvider = nil
            throw error
        }
    }
    
    public func createTransaction(messageVersion: String, directoryServerId: String?, cardNetwork: String?) async throws -> Transaction {
        guard let sessionProvider = self.sessionProvider else {
            throw TransactionError.transactionCreationFailed("Failed to create transaction. No instance of ThreeDSSessionProvider found.", nil)
            
        }
        
        let transactionProvider = try await sessionProvider.createTransaction(
            messageVersion: messageVersion,
            directoryServerId: directoryServerId,
            cardNetwork: cardNetwork
        )
        
        return Transaction(
            messageVersion: messageVersion,
            directoryServerId: directoryServerId,
            cardNetwork: cardNetwork,
            transactionProvider: transactionProvider
        )
    }
}

public struct AuthenticationConfiguration {
    public let apiKey: String?
    public let preferredProvider: ProviderType?
    public let environment: EnvironmentType
    
    public init(apiKey: String? = nil, preferredProvider: ProviderType? = nil, environment: EnvironmentType = .sandbox) {
        self.apiKey = apiKey
        self.preferredProvider = preferredProvider
        self.environment = environment
    }
}

public enum EnvironmentType: String, CaseIterable {
    case production = "production"
    case sandbox = "sandbox"
}
