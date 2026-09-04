//
//  PaymentSession+UIKit.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 30/08/24.
//

import Foundation
import UIKit

extension PaymentSession {

    public func presentPaymentSheet(
        viewController: UIViewController,
        configuration: PaymentSheet.Configuration? = nil,
        subscribe: ((PaymentEventSubscriptionBuilder) -> Void)? = nil,
        completion: @escaping (PaymentResult) -> Void
    ) {
        let paymentSheet = PaymentSheet(
            paymentSessionConfiguration: paymentSessionConfiguration,
            hyperswitchConfiguration: hyperswitchConfiguration ?? nil,
            configuration: configuration
        )

        paymentSheet.reactManager = reactManager
        if let subscribe {
            let builder = PaymentEventSubscriptionBuilder()
            subscribe(builder)
            let (subscription, builtListener) = builder.build()
            paymentSheet.subscribedEvents = subscription.subscribedEventStrings()
            paymentSheet.paymentEventListener = builtListener
        }
        paymentSheet.present(from: viewController, completion: completion)
    }

    // MARK: for external frameworks
    public func presentPaymentSheetWithParams(
        viewController: UIViewController,
        params: [String: Any],
        subscribe: ((PaymentEventSubscriptionBuilder) -> Void)? = nil,
        completion: @escaping (PaymentResult) -> Void
    ) {
        let paymentSheet = PaymentSheet(
            paymentSessionConfiguration: paymentSessionConfiguration,
            hyperswitchConfiguration: hyperswitchConfiguration ?? nil
        )

        paymentSheet.reactManager = reactManager
        if let subscribe {
            let builder = PaymentEventSubscriptionBuilder()
            subscribe(builder)
            let (subscription, builtListener) = builder.build()
            paymentSheet.subscribedEvents = subscription.subscribedEventStrings()
            paymentSheet.paymentEventListener = builtListener
        }
        paymentSheet.presentWithParams(from: viewController, props: params, completion: completion)
    }

    public func getCustomerSavedPaymentMethods(
        _ func_: @escaping (any PaymentSessionHandler) -> Void,
        configuration: SavedPaymentMethodsConfiguration? = nil
    ) {
        let manager = reactManager
        manager.headlessModule.begin(session: self, completion: func_)
        let hyperswitchConfiguration = try? hyperswitchConfiguration?.toDictionary()
        let paymentSessionConfiguration = try? paymentSessionConfiguration.toDictionary()
        let sdkParams = SDKParams.getSDKParams()
        let configurationDict = try? configuration.toDictionary()

        var props: [String: Any] = [
            "hyperswitchConfig": hyperswitchConfiguration as Any,
            "paymentSessionConfig": paymentSessionConfiguration as Any,
            "sdkParams": sdkParams,
        ]

        props["configuration"] = [
            "paymentMethodLayout": [
                "savedMethodCustomization": configurationDict
            ]
        ]

        reactRuntime.headlessSurface = manager.viewForModule("HyperHeadless", initialProperties: ["props": props])
    }
}

internal final class UpdateIntentAttempt {
    let completion: (UpdateIntentResult) -> Void
    var configuration: PaymentSessionConfiguration?
    var timeout: DispatchWorkItem?

    init(completion: @escaping (UpdateIntentResult) -> Void) {
        self.completion = completion
    }
}

internal final class PaymentSessionReactRuntime {
    let manager: RNViewManager
    var prefetchSurface: UIView?
    var headlessSurface: UIView?
    var updateIntentAttempt: UpdateIntentAttempt?

    init(manager: RNViewManager) {
        self.manager = manager
    }
}

extension PaymentSession {

    internal var reactManager: RNViewManager { reactRuntime.manager }

    internal func activateRuntime() async {
        reactManager.hyperModule.onPrefetchUpdateIntentReply = { [weak self] type, result in
            self?.handleUpdateIntentReply(type: type, result: result)
        }
        onMain { [weak self] in self?.ensurePrefetchSurface() }
        await reactManager.awaitReady()
    }

    private func ensurePrefetchSurface() {
        guard reactRuntime.prefetchSurface == nil else { return }
        let props: [String: Any] = [
            "type": "prefetch",
            "hyperswitchConfig": (try? hyperswitchConfiguration?.toDictionary()) as Any,
            "paymentSessionConfig": (try? paymentSessionConfiguration.toDictionary()) as Any,
            "sdkParams": SDKParams.getSDKParams(),
            "prefetchTag": HyperModuleImpl.prefetchSurfaceTag,
        ]
        reactRuntime.prefetchSurface = reactManager.viewForModule("HyperHeadless", initialProperties: ["props": props])
    }

    private func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    public func updateIntent(
        authorizationProvider: @escaping (@escaping (String) -> Void) -> Void,
        completion: @escaping (UpdateIntentResult) -> Void
    ) {
        onMain { [weak self] in
            guard let self = self else { return }
            guard self.reactRuntime.updateIntentAttempt == nil else {
                completion(.failure(Self.error("ALREADY_IN_PROGRESS", "updateIntent already in progress")))
                return
            }
            let attempt = UpdateIntentAttempt(completion: completion)
            self.reactRuntime.updateIntentAttempt = attempt
            self.ensurePrefetchSurface()
            self.emitToPrefetchSurface("updateIntentInit", sdkAuthorization: nil)

            authorizationProvider { [weak self] sdkAuthorization in
                self?.onMain { self?.refetch(with: sdkAuthorization, attempt: attempt) }
            }
        }
    }

    private func refetch(with sdkAuthorization: String, attempt: UpdateIntentAttempt) {
        guard reactRuntime.updateIntentAttempt === attempt else { return }
        guard !sdkAuthorization.isEmpty else {
            finish(attempt, .failure(Self.error("INVALID_SDK_AUTHORIZATION", "No sdkAuthorization was provided")))
            return
        }
        attempt.configuration = PaymentSessionConfiguration(sdkAuthorization: sdkAuthorization)

        let timeout = DispatchWorkItem { [weak self] in
            self?.finish(attempt, .failure(Self.error("UPDATE_INTENT_TIMEOUT", "The updated payment intent was not acknowledged in time.")))
        }
        attempt.timeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: timeout)

        emitToPrefetchSurface("updateIntentComplete", sdkAuthorization: sdkAuthorization)
    }

    private func handleUpdateIntentReply(type: String, result: String) {
        guard type == "UPDATE_INTENT_COMPLETE_RETURNED",
            let attempt = reactRuntime.updateIntentAttempt
        else { return }
        let parsed = parseUpdateIntentResult(result)
        if case .success = parsed, let configuration = attempt.configuration {
            paymentSessionConfiguration = configuration
        }
        finish(attempt, parsed)
    }

    private func finish(_ attempt: UpdateIntentAttempt, _ result: UpdateIntentResult) {
        guard reactRuntime.updateIntentAttempt === attempt else { return }
        attempt.timeout?.cancel()
        reactRuntime.updateIntentAttempt = nil
        attempt.completion(result)
    }

    private func emitToPrefetchSurface(_ name: String, sdkAuthorization: String?) {
        var payload: [String: Any] = ["rootTag": HyperModuleImpl.prefetchSurfaceTag]
        if let sdkAuthorization = sdkAuthorization {
            payload["sdkAuthorization"] = sdkAuthorization
        }
        reactManager.hyperModule.emit(name, payload)
    }

    private static func error(_ domain: String, _ message: String) -> NSError {
        NSError(domain: domain, code: 0, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
