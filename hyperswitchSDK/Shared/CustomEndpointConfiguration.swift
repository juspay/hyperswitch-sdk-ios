//
//  CustomEndpointConfiguration.swift
//  HyperswitchCore
//
//  Created by Harshit Srivastava on 17/05/26.
//

public enum CustomEndpointConfiguration: Codable {
    case customEndpoint(String)
    case overrideEndpoints(OverrideEndpointConfiguration)
}

public struct OverrideEndpointConfiguration: Codable {
    let backendEndpoint: String?
    let assetsEndpoint: String?
    let sdkConfigEndpoint: String?
    let confirmEndpoint: String?
    let airborneEndpoint: String?
    let loggingEndpoint: String?

    public init(
        backendEndpoint: String? = nil,
        assetsEndpoint: String? = nil,
        sdkConfigEndpoint: String? = nil,
        confirmEndpoint: String? = nil,
        airborneEndpoint: String? = nil,
        loggingEndpoint: String? = nil
    ) {
        self.backendEndpoint = backendEndpoint
        self.assetsEndpoint = assetsEndpoint
        self.sdkConfigEndpoint = sdkConfigEndpoint
        self.confirmEndpoint = confirmEndpoint
        self.airborneEndpoint = airborneEndpoint
        self.loggingEndpoint = loggingEndpoint
    }
}
