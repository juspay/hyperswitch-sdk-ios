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

    public func initClickToPaySession(request3DSAuthentication: Bool) async throws -> ClickToPaySession {
        do {
            return ClickToPaySession(request3DSAuthentication: request3DSAuthentication)
        }
        catch {
            throw error
        }
    }
}
