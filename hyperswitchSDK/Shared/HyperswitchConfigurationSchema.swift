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
    let publishableKey: String
    let profileId: String?
    let customEndpoints: CustomEndpointConfiguration?
    let environment: HyperswitchEnvironment?

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
    let publishableKey: String
    let profileId: String?
    let customEndpoints: CustomEndpointConfiguration?
    let environment: HyperswitchEnvironment?

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
