//
//  PaymentSession+UIKit.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 30/08/24.
//

import Foundation
import UIKit

/* `requested` distinguishes a real fetch attempt from a suppressed duplicate init:
   a duplicate must not read as a failed prefetch (the caller would clear the cache entry
   the original in-flight request is about to write — a race on the same authorization). */
internal struct HeadlessFetchResult {
    let requested: Bool
    let data: [String: Any]?
}

private struct PendingPrefetch {
    let continuation: CheckedContinuation<HeadlessFetchResult, Never>
    let rootView: UIView
}

/// Accessed only on the main queue. The authorization is the routing key for the one payment
/// currently being prefetched; no separate request identifier or callback fan-out is needed.
private var pendingPrefetches: [String: PendingPrefetch] = [:]

private final class PendingSavedMethodsRequest {
    weak var session: PaymentSession?
    let sdkAuthorization: String
    let completion: (PaymentSessionHandler) -> Void
    var rootView: UIView?
    var confirmationStarted = false

    init(
        session: PaymentSession,
        completion: @escaping (PaymentSessionHandler) -> Void
    ) {
        self.session = session
        self.sdkAuthorization = session.paymentSessionConfiguration.sdkAuthorization
        self.completion = completion
    }

    func releaseRootView() {
        guard let rootView else { return }
        RNHeadlessManager.sharedInstance.releaseRootView(rootView)
        self.rootView = nil
    }
}

/// These registries are main-queue confined. Different authorizations can run concurrently;
/// duplicate work for one authorization is rejected instead of overwriting the first owner.
private var pendingSavedMethodsRequests: [String: PendingSavedMethodsRequest] = [:]
private var headlessConfirmations: [String: (PaymentResult) -> Void] = [:]

extension PaymentSession {

    /// Matches the Android launcher and the JS-side fallbacks, so neither side waits on the other.
    private static let prefetchTimeout: DispatchTimeInterval = .seconds(30)
    private static let savedMethodsTimeout: DispatchTimeInterval = .seconds(30)

    /// Runs the initial prefetch headless task and waits for its result.
    ///
    /// A prefetch miss is not fatal: the sheet and headless flows fall back to making the API
    /// calls themselves, so a timeout resolves with no data rather than propagating an error.
    /// Without the timeout a wedged bridge left `initPaymentSession` awaiting forever.
    internal func triggerPrefetch() async {
        let configuration = paymentSessionConfiguration
        /* The fetched payload lives only in the JS PrefetchCache; this waits purely so the
           cache is warm before the merchant is allowed to present UI. */
        let fetch = await loadHeadlessData(
            headlessType: "prefetch",
            configuration: configuration
        )
        /* A suppressed duplicate is not a failure: the original request owns the entry and
           will write it — clearing here would race that write. */
        if fetch.requested, fetch.data == nil,
           paymentSessionConfiguration.sdkAuthorization == configuration.sdkAuthorization {
            /* A failed re-validation must not leave an earlier (e.g. cancelled) attempt's
               entry behind: the sheet would mount with minutes-old session tokens instead
               of fetching for itself. Same-auth guard keeps a late-finishing prefetch of
               an old session from wiping a newer session's entry. */
            clearPrefetch(for: configuration.sdkAuthorization)
        }
    }

    /// Fetches the new intent's data without mutating the active session.
    internal func fetchIntentUpdate(
        configuration: PaymentSessionConfiguration
    ) async -> [String: Any]? {
        await loadHeadlessData(
            headlessType: "updateIntent",
            configuration: configuration
        ).data
    }

        private func loadHeadlessData(
        headlessType: String,
        configuration: PaymentSessionConfiguration
    ) async -> HeadlessFetchResult {
        let sdkAuthorization = configuration.sdkAuthorization

        guard !sdkAuthorization.isEmpty else {
            return HeadlessFetchResult(requested: false, data: nil)
        }

        let result: HeadlessFetchResult = await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                /* sdkAuthorization identifies one payment. If a merchant initializes the exact
                   same payment concurrently, let that unsupported duplicate fall back instead of
                   adding callback lists and multi-owner lifecycle state. */
                guard pendingPrefetches[sdkAuthorization] == nil else {
                    continuation.resume(returning: HeadlessFetchResult(requested: false, data: nil))
                    return
                }

                let hyperswitchConfig = try? self.hyperswitchConfiguration?.toDictionary()
                let paymentSessionConfig = try? configuration.toDictionary()
                let sdkParams = SDKParams.getSDKParams()

                let props: [String: Any] = [
                    "hyperswitchConfig": hyperswitchConfig as Any,
                    "paymentSessionConfig": paymentSessionConfig as Any,
                    "sdkParams": sdkParams,
                    "headlessType": headlessType,
                ]

                let rootView = RNHeadlessManager.sharedInstance.viewForModule(
                    "HyperHeadless", initialProperties: ["props": props]
                )
                pendingPrefetches[sdkAuthorization] = PendingPrefetch(
                    continuation: continuation,
                    rootView: rootView
                )

                DispatchQueue.main.asyncAfter(deadline: .now() + PaymentSession.prefetchTimeout) {
                    guard PaymentSession.finishPrefetch(sdkAuthorization, data: [:]) else { return }
                    print("[Hyperswitch] Prefetch timed out; falling back to on-demand API calls")
                }
            }
        }

        return HeadlessFetchResult(requested: result.requested, data: result.data?.isEmpty == true ? nil : result.data)
    }

    internal func clearPrefetch(for sdkAuthorization: String) {
        guard !sdkAuthorization.isEmpty else { return }
        RNHeadlessManager.sharedInstance.removePrefetchCache(
            sdkAuthorization: sdkAuthorization
        )
    }

    /// Completes the one native waiter for this payment and releases only its temporary root.
    @discardableResult
    internal static func finishPrefetch(
        _ sdkAuthorization: String,
        data: [String: Any]
    ) -> Bool {
        dispatchPrecondition(condition: .onQueue(.main))
        guard         let pending = pendingPrefetches.removeValue(forKey: sdkAuthorization) else {
            return false
        }
        RNHeadlessManager.sharedInstance.releaseRootView(pending.rootView)
        pending.continuation.resume(returning: HeadlessFetchResult(requested: true, data: data))
        return true
    }

    public func presentPaymentSheet(
        viewController: UIViewController,
        configuration: PaymentSheet.Configuration? = nil,
        subscribe: ((PaymentEventSubscriptionBuilder) -> Void)? = nil,
        completion: @escaping (PaymentResult) -> Void
    ) {
        let sdkAuthorization = paymentSessionConfiguration.sdkAuthorization
        let paymentSheet = PaymentSheet(
            paymentSessionConfiguration: paymentSessionConfiguration,
            hyperswitchConfiguration: hyperswitchConfiguration ?? nil,
            configuration: configuration
        )

        if let subscribe {
            let builder = PaymentEventSubscriptionBuilder()
            subscribe(builder)
            let (subscription, builtListener) = builder.build()
            paymentSheet.subscribedEvents = subscription.subscribedEventStrings()
            paymentSheet.paymentEventListener = builtListener
        }
        paymentSheet.present(from: viewController) { [weak self] result in
            self?.handlePaymentResult(result, sdkAuthorization: sdkAuthorization)
            completion(result)
        }
    }

    // MARK: for external frameworks
    public func presentPaymentSheetWithParams(
        viewController: UIViewController,
        params: [String: Any],
        subscribe: ((PaymentEventSubscriptionBuilder) -> Void)? = nil,
        completion: @escaping (PaymentResult) -> Void
    ) {
        let sdkAuthorization = paymentSessionConfiguration.sdkAuthorization
        let paymentSheet = PaymentSheet(
            paymentSessionConfiguration: paymentSessionConfiguration,
            hyperswitchConfiguration: hyperswitchConfiguration ?? nil
        )

        if let subscribe {
            let builder = PaymentEventSubscriptionBuilder()
            subscribe(builder)
            let (subscription, builtListener) = builder.build()
            paymentSheet.subscribedEvents = subscription.subscribedEventStrings()
            paymentSheet.paymentEventListener = builtListener
        }
        paymentSheet.presentWithParams(from: viewController, props: params) { [weak self] result in
            self?.handlePaymentResult(result, sdkAuthorization: sdkAuthorization)
            completion(result)
        }
    }

    public func getCustomerSavedPaymentMethods(
        _ func_: @escaping (PaymentSessionHandler) -> Void,
        configuration: SavedPaymentMethodsConfiguration? = nil
    ) {
        DispatchQueue.main.async {
            let sdkAuthorization = self.paymentSessionConfiguration.sdkAuthorization
            guard !sdkAuthorization.isEmpty else {
                func_(PaymentSession.failedSavedMethodsHandler(
                    code: "INVALID_SDK_AUTHORIZATION",
                    message: "sdkAuthorization must not be empty"
                ))
                return
            }
            guard pendingSavedMethodsRequests[sdkAuthorization] == nil else {
                func_(PaymentSession.failedSavedMethodsHandler(
                    code: "ALREADY_IN_PROGRESS",
                    message: "Saved payment methods request already in progress"
                ))
                return
            }

            let request = PendingSavedMethodsRequest(session: self, completion: func_)
            pendingSavedMethodsRequests[sdkAuthorization] = request

            let hyperswitchConfiguration = try? self.hyperswitchConfiguration?.toDictionary()
            let paymentSessionConfiguration = try? self.paymentSessionConfiguration.toDictionary()
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

            request.rootView = RNHeadlessManager.sharedInstance.viewForModule(
                "HyperHeadless",
                initialProperties: ["props": props]
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + PaymentSession.savedMethodsTimeout) {
                guard pendingSavedMethodsRequests[sdkAuthorization] === request else { return }
                pendingSavedMethodsRequests.removeValue(forKey: sdkAuthorization)
                request.releaseRootView()
                request.completion(PaymentSession.failedSavedMethodsHandler(
                    code: "HEADLESS_TIMEOUT",
                    message: "Saved payment methods request timed out"
                ))
            }
        }
    }

    internal static func getPaymentSession(
        sdkAuthorization: String,
        getPaymentMethodData: NSDictionary,
        getPaymentMethodData2: NSDictionary,
        getPaymentMethodDataArray: NSArray,
        callback: @escaping RCTResponseSenderBlock
    ) {
        DispatchQueue.main.async {
            guard let request = pendingSavedMethodsRequests.removeValue(
                forKey: sdkAuthorization
            ) else { return }
            guard request.session?.paymentSessionConfiguration.sdkAuthorization == sdkAuthorization else {
                request.releaseRootView()
                request.completion(failedSavedMethodsHandler(
                    code: "STALE_PAYMENT_SESSION_HANDLER",
                    message: "Saved payment methods handler belongs to the previous payment intent"
                ))
                return
            }
            let handler = PaymentSessionHandler(
                getCustomerDefaultSavedPaymentMethodData: {
                    return decodePaymentMethodData(getPaymentMethodData)
                },
                getCustomerLastUsedPaymentMethodData: {
                    return decodePaymentMethodData(getPaymentMethodData2)
                },
                getCustomerSavedPaymentMethodData: {
                    var array = [PaymentMethod]()
                    for i in 0..<getPaymentMethodDataArray.count {
                        if let map = getPaymentMethodDataArray[i] as? NSDictionary {
                            switch decodePaymentMethodData(map) {
                            case .success(let paymentMethod):
                                array.append(paymentMethod)
                            case .failure(_):
                                continue
                            }
                        }
                    }
                    if array.isEmpty {
                        return .failure(
                            PMError(
                                code: "01",
                                message: "No default type found"
                            )
                        )
                    }
                    return .success(array)

                },
                confirmWithCustomerDefaultPaymentMethod: { cvc, resultHandler in
                    DispatchQueue.main.async {
                        if let paymentToken = getPaymentMethodData["payment_token"] as? String {
                            guard self.beginSavedMethodConfirmation(
                                sdkAuthorization: sdkAuthorization,
                                request: request,
                                resultHandler: resultHandler
                            ) else { return }
                            self.resolveSavedMethodJSCallback(
                                callback: callback,
                                paymentToken: paymentToken,
                                cvc: cvc
                            )
                        } else {
                            self.finishSavedMethodDirectly(
                                request: request,
                                resultHandler: resultHandler,
                                result: self.savedMethodsFailure(
                                    code: "MISSING_PAYMENT_TOKEN",
                                    message: "Saved payment method has no payment token"
                                )
                            )
                        }
                    }
                },
                confirmWithCustomerLastUsedPaymentMethod: { cvc, resultHandler in
                    DispatchQueue.main.async {
                        if let paymentToken = getPaymentMethodData2["payment_token"] as? String {
                            guard self.beginSavedMethodConfirmation(
                                sdkAuthorization: sdkAuthorization,
                                request: request,
                                resultHandler: resultHandler
                            ) else { return }
                            cvc.confirm(
                                sdkAuthorization: sdkAuthorization,
                                paymentToken: paymentToken
                            )
                        } else {
                            self.finishSavedMethodDirectly(
                                request: request,
                                resultHandler: resultHandler,
                                result: self.savedMethodsFailure(
                                    code: "MISSING_PAYMENT_TOKEN",
                                    message: "Saved payment method has no payment token"
                                )
                            )
                        }
                    }
                },
                confirmWithCustomerPaymentToken: { paymentToken, cvc, resultHandler in
                    DispatchQueue.main.async {
                        guard self.beginSavedMethodConfirmation(
                            sdkAuthorization: sdkAuthorization,
                            request: request,
                            resultHandler: resultHandler
                        ) else { return }
                        self.resolveSavedMethodJSCallback(
                            callback: callback,
                            paymentToken: paymentToken,
                            cvc: cvc
                        )
                    }
                }
            )
            request.completion(handler)
        }
    }

    @discardableResult
    internal static func exitHeadless(
        sdkAuthorization: String,
        result: PaymentResult
    ) -> Bool {
        dispatchPrecondition(condition: .onQueue(.main))
        guard let completion = headlessConfirmations.removeValue(
            forKey: sdkAuthorization
        ) else { return false }
        completion(result)
        return true
    }

    private static func beginSavedMethodConfirmation(
        sdkAuthorization: String,
        request: PendingSavedMethodsRequest,
        resultHandler: @escaping (PaymentResult) -> Void
    ) -> Bool {
        guard
            !request.confirmationStarted,
            headlessConfirmations[sdkAuthorization] == nil
        else {
            resultHandler(savedMethodsFailure(
                code: "ALREADY_IN_PROGRESS",
                message: "Payment confirmation already in progress"
            ))
            return false
        }
        if rejectStaleSavedMethodsRequest(
            sdkAuthorization: sdkAuthorization,
            request: request,
            resultHandler: resultHandler
        ) {
            return false
        }
        request.confirmationStarted = true
        headlessConfirmations[sdkAuthorization] = { result in
            request.session?.handlePaymentResult(
                result,
                sdkAuthorization: sdkAuthorization
            )
            request.releaseRootView()
            resultHandler(result)
        }
        return true
    }

    private static func resolveSavedMethodJSCallback(
        callback: @escaping RCTResponseSenderBlock,
        paymentToken: String,
        cvc: String?
    ) {
        var map = [String: Any]()
        map["paymentToken"] = paymentToken
        map["cvc"] = cvc
        callback([map])
    }

    private static func finishSavedMethodDirectly(
        request: PendingSavedMethodsRequest,
        resultHandler: @escaping (PaymentResult) -> Void,
        result: PaymentResult
    ) {
        guard !request.confirmationStarted else {
            resultHandler(savedMethodsFailure(
                code: "ALREADY_USED",
                message: "This saved payment methods handler has already completed"
            ))
            return
        }
        if rejectStaleSavedMethodsRequest(
            sdkAuthorization: request.sdkAuthorization,
            request: request,
            resultHandler: resultHandler
        ) {
            return
        }
        request.confirmationStarted = true
        request.session?.handlePaymentResult(
            result,
            sdkAuthorization: request.sdkAuthorization
        )
        request.releaseRootView()
        resultHandler(result)
    }

    private static func rejectStaleSavedMethodsRequest(
        sdkAuthorization: String,
        request: PendingSavedMethodsRequest,
        resultHandler: @escaping (PaymentResult) -> Void
    ) -> Bool {
        guard request.session?.paymentSessionConfiguration.sdkAuthorization == sdkAuthorization
        else {
            request.confirmationStarted = true
            let result = savedMethodsFailure(
                code: "STALE_PAYMENT_SESSION_HANDLER",
                message: "Saved payment methods handler belongs to the previous payment intent"
            )
            request.session?.handlePaymentResult(
                result,
                sdkAuthorization: request.sdkAuthorization
            )
            request.releaseRootView()
            resultHandler(result)
            return true
        }
        return false
    }

    private static func savedMethodsFailure(
        code: String,
        message: String
    ) -> PaymentResult {
        .failed(error: NSError(
            domain: code,
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: message]
        ))
    }

    private static func failedSavedMethodsHandler(
        code: String,
        message: String
    ) -> PaymentSessionHandler {
        let error = PMError(code: code, message: message)
        let result = savedMethodsFailure(code: code, message: message)
        return PaymentSessionHandler(
            getCustomerDefaultSavedPaymentMethodData: { .failure(error) },
            getCustomerLastUsedPaymentMethodData: { .failure(error) },
            getCustomerSavedPaymentMethodData: { .failure(error) },
            confirmWithCustomerDefaultPaymentMethod: { _, callback in callback(result) },
            confirmWithCustomerLastUsedPaymentMethod: { _, callback in callback(result) },
            confirmWithCustomerPaymentToken: { _, _, callback in callback(result) }
        )
    }

    private static func decodePaymentMethodData(_ readableMap: NSDictionary) -> Result<PaymentMethod, PMError> {
        if let jsonData = try? JSONSerialization.data(withJSONObject: readableMap),
            let paymentMethod = try? JSONDecoder().decode(PaymentMethod.self, from: jsonData)
        {
            return .success(paymentMethod)
        } else {
            return .failure(
                PMError(
                    code: readableMap["code"] as? String ?? "01",
                    message: readableMap["message"] as? String ?? "No default type found"
                )
            )
        }
    }
}
