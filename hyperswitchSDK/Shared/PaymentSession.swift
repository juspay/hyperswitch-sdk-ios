//
//  PaymentSession.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 07/03/24.
//

import Foundation

@frozen public enum PaymentResult {
    case completed(data: String)
    case canceled(data: String)
    case failed(error: Error)
}

public enum UpdateIntentResult {
    case success
    case cancelled
    case failure(Error)
}

public class PaymentSession {

    internal var paymentSessionConfiguration: PaymentSessionConfiguration
    internal var hyperswitchConfiguration: HyperswitchConfiguration?

    #if canImport(React)
    internal let reactRuntime = PaymentSessionReactRuntime(manager: RNViewManager())
    #endif

    internal init(paymentSessionConfiguration: PaymentSessionConfiguration, hyperswitchConfiguration: HyperswitchConfiguration? = nil) {
        self.paymentSessionConfiguration = paymentSessionConfiguration
        self.hyperswitchConfiguration = hyperswitchConfiguration

        if let hyperswitchConfiguration = hyperswitchConfiguration {
            #if canImport(HyperOTA)
            OTAServices.shared.initialize(publishableKey: hyperswitchConfiguration.publishableKey)
            LogManager.initialize(publishableKey: hyperswitchConfiguration.publishableKey)
            #endif
        }
    }

    internal func parseUpdateIntentResult(_ data: String) -> UpdateIntentResult {
        guard
            let bytes = data.data(using: .utf8),
            let json = (try? JSONSerialization.jsonObject(with: bytes)) as? [String: String]
        else {
            return .failure(
                NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid update intent result"])
            )
        }
        switch json["status"] {
        case "cancelled":
            return .cancelled
        case "failed", "error":
            let code = json["code"].flatMap { $0.isEmpty ? nil : $0 } ?? "UNKNOWN_ERROR"
            let message = json["message"].flatMap { $0.isEmpty ? nil : $0 } ?? (json["status"] ?? "failed")
            return .failure(NSError(domain: code, code: 0, userInfo: [NSLocalizedDescriptionKey: message]))
        default:
            return .success
        }
    }
}
