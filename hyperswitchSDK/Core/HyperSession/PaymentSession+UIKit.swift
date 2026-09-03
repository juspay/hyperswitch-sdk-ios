//
//  PaymentSession+UIKit.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 30/08/24.
//

import Foundation
import UIKit

private struct PendingPrefetch {
    let continuation: CheckedContinuation<[String: Any]?, Error>
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
        rootView = nil
    }
}

/// These registries are main-queue confined. Different authorizations can run concurrently;
/// duplicate work for one authorization is rejected instead of overwriting the first owner.
private var pendingSavedMethodsRequests: [String: PendingSavedMethodsRequest] = [:]

/* Confirmations currently running through the headless runtime. No timeout on purpose: a
   confirm can wait on a 3DS challenge or a wallet sheet for minutes, and a late real result
   must reach the merchant. A detached runtime is handled by rollbackSavedMethodConfirmation. */
private var headlessConfirmations: [String: (PaymentResult) -> Void] = [:]

extension PaymentSession {

    /* SDK-side last-resort budgets; JS has no budget of its own. Same 30s window as Android. */
    private static let prefetchTimeout: DispatchTimeInterval = .seconds(30)
    private static let savedMethodsTimeout: DispatchTimeInterval = .seconds(30)

    /// Runs the initial prefetch headless task and waits for its result.
    ///
    /// A prefetch miss is not fatal: the sheet and headless flows fall back to making the API
    /// calls themselves, so a timeout resolves with no data rather than propagating an error.
    /// Without the timeout a wedged bridge left `initPaymentSession` awaiting forever.
    /// - Throws: SESSION_INIT_IN_PROGRESS when the same sdkAuthorization is being fetched in
    ///   another in-progress session: retry once it completes, or keep the session you have.
    internal func triggerPrefetch() async throws {
        let configuration = paymentSessionConfiguration
        /* The fetched payload lives only in the JS PrefetchCache; this waits purely so the
           cache is warm before the merchant is allowed to present UI. A duplicate init throws
           out of loadHeadlessData — the in-flight request owns the entry; nothing here runs. */
        let data = try await loadHeadlessData(
            headlessType: "prefetch",
            configuration: configuration
        )
        if data == nil, !configuration.sdkAuthorization.isEmpty,
           paymentSessionConfiguration.sdkAuthorization == configuration.sdkAuthorization {
            /* A failed re-validation must not leave an earlier (e.g. cancelled) attempt's
               entry behind: the sheet would mount with minutes-old session tokens instead
               of fetching for itself. Same-auth guard keeps a late-finishing prefetch of
               an old session from wiping a newer session's entry. Empty-auth stays silent
               (prefetch miss is not an error). */
            clearPrefetch(for: configuration.sdkAuthorization)
        }
    }

    /// Fetches the new intent's data without mutating the active session. Throws
    /// SESSION_INIT_IN_PROGRESS when another in-progress session owns this authorization;
    /// returns nil on a timeout.
    internal func fetchIntentUpdate(
        configuration: PaymentSessionConfiguration
    ) async throws -> [String: Any]? {
        try await loadHeadlessData(
            headlessType: "updateIntent",
            configuration: configuration
        )
    }

    private func loadHeadlessData(
        headlessType: String,
        configuration: PaymentSessionConfiguration
    ) async throws -> [String: Any]? {
        let sdkAuthorization = configuration.sdkAuthorization

        guard !sdkAuthorization.isEmpty else {
            return nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                /* sdkAuthorization identifies one payment: the in-flight request owns the
                   entry and its cache write. A concurrent duplicate (merchant init'd the
                   same intent twice) must not clear, wait, or silently fall back — it throws
                   SESSION_INIT_IN_PROGRESS loudly. */
                guard pendingPrefetches[sdkAuthorization] == nil else {
                    continuation.resume(throwing: NSError(
                        domain: "SESSION_INIT_IN_PROGRESS",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey:
                            "sdkAuthorization '\(sdkAuthorization)' is already in use by an in-progress session"
                        ]
                    ))
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
        guard let pending = pendingPrefetches.removeValue(forKey: sdkAuthorization) else {
            return false
        }
        pending.continuation.resume(returning: data.isEmpty ? nil : data)
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
                "headlessType": "savedPM",
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
            /* A request filed for a superseded intent is still delivered here. Staleness is
               rejected natively at confirm time: beginSavedMethodConfirmation compares the
               session's current authorization with the handler's, and native is the only
               side that knows the current authorization. */
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
                            if !cvc.confirm(
                                sdkAuthorization: sdkAuthorization,
                                paymentToken: paymentToken
                            ) {
                                self.rollbackSavedMethodConfirmation(
                                    sdkAuthorization: sdkAuthorization
                                )
                            }
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
        /* Headless confirms cannot be JS-guarded: the headless root's nativeProp is frozen
           at launch (its clientSecret is used verbatim at confirm time) — only native, which
           owns the current authorization, can reject a superseded-intent handler. */
        guard request.session?.paymentSessionConfiguration.sdkAuthorization == request.sdkAuthorization
        else {
            resultHandler(savedMethodsFailure(
                code: "STALE_PAYMENT_SESSION_HANDLER",
                message: "Saved payment methods handler belongs to a previous payment intent; call getCustomerSavedPaymentMethods again"
            ))
            return false
        }
        /* Confirm channels are single-shot: the codegen callback is consumed by the
           first confirm and the registry entry by its result. A post-terminal retry
           on the same handler is HANDLER_ALREADY_USED — only an in-flight duplicate is
           ALREADY_IN_PROGRESS. */
        if request.confirmationStarted, headlessConfirmations[sdkAuthorization] == nil {
            resultHandler(savedMethodsFailure(
                code: "HANDLER_ALREADY_USED",
                message: "This saved payment methods handler has already completed"
            ))
            return false
        }
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

    /* The emit could not reach JS: roll the registration back so the entry doesn't
       wedge every later confirm on this authorization with ALREADY_IN_PROGRESS. */
    private static func rollbackSavedMethodConfirmation(sdkAuthorization: String) {
        if let completion = headlessConfirmations.removeValue(forKey: sdkAuthorization) {
            completion(.failed(error: NSError(
                domain: "RUNTIME_UNAVAILABLE",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "React runtime is not available"]
            )))
        }
    }

    private static func finishSavedMethodDirectly(
        request: PendingSavedMethodsRequest,
        resultHandler: @escaping (PaymentResult) -> Void,
        result: PaymentResult
    ) {
        guard !request.confirmationStarted else {
            resultHandler(savedMethodsFailure(
                code: "HANDLER_ALREADY_USED",
                message: "This saved payment methods handler has already completed"
            ))
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
