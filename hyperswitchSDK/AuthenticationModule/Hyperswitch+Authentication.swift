//
//  Hyperswitch+Authentication.swift
//  HyperswitchAuthentication
//
//  Created by Harshit Srivastava on 26/09/26.
//

import Foundation
import HyperswitchShared

extension Hyperswitch {
    public func initAuthenticationSession(
        clientSecret: String,
        profileId: String? = nil,
        authenticationId: String,
        merchantId: String,
        customParams: [String: Any]? = nil
    ) -> AuthenticationSession {
        let endpoints = hyperswitchConfiguration.customEndpoints
        let session = AuthenticationSession(
            publishableKey: hyperswitchConfiguration.publishableKey,
            customBackendUrl: endpoints?.backendURL,
            customParams: customParams,
            customLogUrl: endpoints?.loggingURL
        )
        session.start(
            clientSecret: clientSecret,
            profileId: profileId ?? hyperswitchConfiguration.profileId,
            authenticationId: authenticationId,
            merchantId: merchantId
        )
        return session
    }
}
