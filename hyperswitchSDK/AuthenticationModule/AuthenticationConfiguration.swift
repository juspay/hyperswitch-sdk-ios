//
//  AuthenticationConfiguration.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 29/10/25.
//

public struct AuthenticationConfiguration {
    public let apiKey: String?
    public let preferredProvider: ThreeDSProviderType?
    public let environment: EnvironmentType
    
    public init(apiKey: String? = nil, preferredProvider: ThreeDSProviderType? = nil, environment: EnvironmentType = .sandbox) {
        self.apiKey = apiKey
        self.preferredProvider = preferredProvider
        self.environment = environment
    }
}

public enum EnvironmentType: String, CaseIterable {
    case production = "production"
    case sandbox = "sandbox"
}
