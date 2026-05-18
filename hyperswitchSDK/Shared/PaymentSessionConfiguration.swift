//
//  PaymentSessionConfiguration.swift
//  HyperswitchCore
//
//  Created by Harshit Srivastava on 17/05/26.
//

public struct PaymentSessionConfiguration: Codable {
    public let sdkAuthorization: String

    public init(sdkAuthorization: String) {
        self.sdkAuthorization = sdkAuthorization
    }
}
