//
//  Environment.swift
//  hyperswitch
//
//  Created by Kuntimaddi Manideep on 24/01/25.
//

import Foundation

enum SDKEnvironment {
    case PROD, SANDBOX

    static func getEnvironment(_ publishableKey: String) -> SDKEnvironment {
        return publishableKey.contains("_snd_") ? .SANDBOX : .PROD
    }

    static func baseURL(for publishableKey: String) -> String {
        return getEnvironment(publishableKey) == .PROD ? "https://api.hyperswitch.io" : "https://sandbox.hyperswitch.io"
    }

    static func loggingURL(for publishableKey: String) -> String {
        return "\(baseURL(for: publishableKey))/logs/sdk"
    }
}
