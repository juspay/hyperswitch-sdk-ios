//
//  CustomEndpointConfiguration.swift
//  HyperswitchCore
//
//  Created by Harshit Srivastava on 17/05/26.
//

public enum CustomEndpointConfiguration: Codable {
    case commonEndpoint(String)
    case overrideEndpoints(OverrideEndpointConfiguration)

    private enum CodingKeys: String, CodingKey {
        case customEndpoint
        case overrideEndpoints
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .commonEndpoint(let value):
            try container.encode(value, forKey: .customEndpoint)
        case .overrideEndpoints(let config):
            try container.encode(config, forKey: .overrideEndpoints)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try container.decodeIfPresent(String.self, forKey: .customEndpoint) {
            self = .commonEndpoint(value)
        } else if let config = try container.decodeIfPresent(OverrideEndpointConfiguration.self, forKey: .overrideEndpoints) {
            self = .overrideEndpoints(config)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: ""
                )
            )
        }
    }
}

public struct OverrideEndpointConfiguration: Codable {
    let customBackendEndpoint: String?
    let customAssetEndpoint: String?
    let customSDKConfigEndpoint: String?
    let customConfirmEndpoint: String?
    let customAirborneEndpoint: String?
    let customLoggingEndpoint: String?

    public init(
        customBackendEndpoint: String? = nil,
        customAssetEndpoint: String? = nil,
        customSDKConfigEndpoint: String? = nil,
        customConfirmEndpoint: String? = nil,
        customAirborneEndpoint: String? = nil,
        customLoggingEndpoint: String? = nil
    ) {
        self.customBackendEndpoint = customBackendEndpoint
        self.customAssetEndpoint = customAssetEndpoint
        self.customSDKConfigEndpoint = customSDKConfigEndpoint
        self.customConfirmEndpoint = customConfirmEndpoint
        self.customAirborneEndpoint = customAirborneEndpoint
        self.customLoggingEndpoint = customLoggingEndpoint
    }
}
