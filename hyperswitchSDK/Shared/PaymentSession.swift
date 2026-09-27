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

extension PaymentResult {
    package static func from(status: String, code: String?, message: String?) -> PaymentResult {
        switch status {
        case "cancelled":
            return .canceled(data: "cancelled")
        case "failed", "requires_payment_method", "form_invalid":
            let domain = (code?.isEmpty == false) ? code! : "UNKNOWN_ERROR"
            return .failed(error: NSError.hyperswitch(domain, message ?? "An error has occurred."))
        default:
            return .completed(data: status)
        }
    }
}

public enum UpdateIntentResult {
    case success
    case cancelled
    case failure(Error)
}

public class PaymentSession {

    package var paymentSessionConfiguration: PaymentSessionConfiguration
    package var hyperswitchConfiguration: HyperswitchConfiguration?

    /// The payments SDK's state for this session (its surfaces on the React host), when the
    /// app links that SDK.
    package var runtime: (any PaymentSessionRuntime)?

    internal init(paymentSessionConfiguration: PaymentSessionConfiguration, hyperswitchConfiguration: HyperswitchConfiguration? = nil) {
        self.paymentSessionConfiguration = paymentSessionConfiguration
        self.hyperswitchConfiguration = hyperswitchConfiguration
    }

    package func parseUpdateIntentResult(_ data: String) -> UpdateIntentResult {
        guard
            let bytes = data.data(using: .utf8),
            let json = (try? JSONSerialization.jsonObject(with: bytes)) as? [String: String]
        else {
            return .failure(
                NSError.hyperswitch("UNKNOWN_ERROR", "Invalid update intent result")
            )
        }
        switch json["status"] {
        case "cancelled":
            return .cancelled
        case "failed", "error":
            let code = json["code"].flatMap { $0.isEmpty ? nil : $0 } ?? "UNKNOWN_ERROR"
            let message = json["message"].flatMap { $0.isEmpty ? nil : $0 } ?? (json["status"] ?? "failed")
            return .failure(NSError.hyperswitch(code, message))
        default:
            return .success
        }
    }
}

extension PaymentSession {

    public func updateIntent(
        authorizationProvider: @escaping (@escaping (String) -> Void) -> Void,
        completion: @escaping (UpdateIntentResult) -> Void
    ) {
        if let runtime = runtime {
            runtime.updateIntent(of: self, authorizationProvider: authorizationProvider, completion: completion)
            return
        }
        authorizationProvider { [weak self] sdkAuthorization in
            self?.paymentSessionConfiguration = PaymentSessionConfiguration(sdkAuthorization: sdkAuthorization)
            completion(.success)
        }
    }
}
