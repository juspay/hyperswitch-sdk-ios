//
//  PaymentSession.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 07/03/24.
//

import Combine
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

    internal let updateIntentDidStart = PassthroughSubject<Void, Never>()
    internal let updateIntentDidComplete = PassthroughSubject<String, Never>()
    internal let updateIntentInitReturned = PassthroughSubject<String, Never>()
    internal let updateIntentCompleteReturned = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()

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

    public func updateIntent(
        authorizationProvider: @escaping (@escaping (String) -> Void) -> Void,
        completion: @escaping (UpdateIntentResult) -> Void
    ) {
//        updateIntentInitReturned
//            .first()
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] _ in
//                guard let self = self else { return }
//                authorizationProvider { [weak self] sdkAuthorization in
//                    guard let self = self else { return }
//                    self.updateIntentCompleteReturned
//                        .first()
//                        .receive(on: DispatchQueue.main)
//                        .sink { result in
//                            completion(self.parseUpdateIntentResult(result))
//                        }
//                        .store(in: &self.cancellables)
//                    self.sdkAuthorization = sdkAuthorization
//                    self.updateIntentDidComplete.send(sdkAuthorization)
//                }
//            }
//            .store(in: &cancellables)
//        updateIntentDidStart.send(())

        // MARK: workaround
        authorizationProvider { [weak self] sdkAuthorization in
                    self?.paymentSessionConfiguration = PaymentSessionConfiguration(sdkAuthorization: sdkAuthorization)
                    completion(UpdateIntentResult.success)
                }
    }

    private func parseUpdateIntentResult(_ data: String) -> UpdateIntentResult {
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
