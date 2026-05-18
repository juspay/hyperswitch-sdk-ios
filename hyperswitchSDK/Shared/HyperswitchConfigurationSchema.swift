//
//  HyperswitchConfigurationSchema.swift
//  HyperswitchCore
//
//  Created by Harshit Srivastava on 17/05/26.
//

private protocol HyperswitchConfigurationSchema {
    var publishableKey: String { get }
    var profileId: String? { get }
    var customConfig: CustomEndpointConfiguration? { get }
}

public struct HyperswitchConfiguration: HyperswitchConfigurationSchema, Codable {
    let publishableKey: String
    let profileId: String?
    let customConfig: CustomEndpointConfiguration?

    public init(
        publishableKey: String,
        profileId: String? = nil,
        customConfig: CustomEndpointConfiguration? = nil
    ) {
        self.publishableKey = publishableKey
        self.profileId = profileId
        self.customConfig = customConfig
    }
}

public struct HyperswitchPlatformConfiguration: HyperswitchConfigurationSchema, Codable {
    let platformPublishableKey: String
    let publishableKey: String
    let profileId: String?
    let customConfig: CustomEndpointConfiguration?

    public init(
        platformPublishableKey: String,
        publishableKey: String,
        profileId: String? = nil,
        customConfig: CustomEndpointConfiguration? = nil
    ) {
        self.platformPublishableKey = platformPublishableKey
        self.publishableKey = publishableKey
        self.profileId = profileId
        self.customConfig = customConfig
    }
}
