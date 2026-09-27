//
//  HyperswitchConfigurationSchema.swift
//  HyperswitchCore
//
//  Created by Harshit Srivastava on 17/05/26.
//

private protocol HyperswitchConfigurationSchema {
    var publishableKey: String { get }
    var profileId: String? { get }
    var customEndpoints: CustomEndpointConfiguration? { get }
    var environment: HyperswitchEnvironment? { get }
}

public struct HyperswitchConfiguration: HyperswitchConfigurationSchema, Codable {
    package let publishableKey: String
    package let profileId: String?
    package let customEndpoints: CustomEndpointConfiguration?
    package let environment: HyperswitchEnvironment?

    public init(
        publishableKey: String,
        profileId: String? = nil,
        customEndpoints: CustomEndpointConfiguration? = nil,
        environment: HyperswitchEnvironment? = nil
    ) {
        self.publishableKey = publishableKey
        self.profileId = profileId
        self.customEndpoints = customEndpoints
        self.environment = environment
    }
}

public struct HyperswitchPlatformConfiguration: HyperswitchConfigurationSchema, Codable {
    let platformPublishableKey: String
    package let publishableKey: String
    package let profileId: String?
    package let customEndpoints: CustomEndpointConfiguration?
    package let environment: HyperswitchEnvironment?

    public init(
        platformPublishableKey: String,
        publishableKey: String,
        profileId: String? = nil,
        customEndpoints: CustomEndpointConfiguration? = nil,
        environment: HyperswitchEnvironment? = nil
    ) {
        self.platformPublishableKey = platformPublishableKey
        self.publishableKey = publishableKey
        self.profileId = profileId
        self.customEndpoints = customEndpoints
        self.environment = environment
    }
}
