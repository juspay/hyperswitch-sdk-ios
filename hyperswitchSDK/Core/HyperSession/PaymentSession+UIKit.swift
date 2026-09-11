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

        paymentSheet.sessionTag = sessionTag
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

        paymentSheet.sessionTag = sessionTag
        if let subscribe {
            let builder = PaymentEventSubscriptionBuilder()
            subscribe(builder)
            let (subscription, builtListener) = builder.build()
            paymentSheet.subscribedEvents = subscription.subscribedEventStrings()
            paymentSheet.paymentEventListener = builtListener
        }
        paymentSheet.presentWithParams(from: viewController, props: params, completion: completion)
    }

    /// Starts a saved-payment-methods surface owned by a fresh HeadlessAttempt, which delivers
    /// the handler and routes confirms. A new call replaces the previous surface and fails
    /// whatever it still had pending.
    public func getCustomerSavedPaymentMethods(
        _ func_: @escaping (any PaymentSessionHandler) -> Void,
        configuration: SavedPaymentMethodsConfiguration? = nil
    ) {
        let hyperswitchConfiguration = try? hyperswitchConfiguration?.toDictionary()
        let paymentSessionConfiguration = try? paymentSessionConfiguration.toDictionary()
        let configurationDict = try? configuration.toDictionary()

        onMain { [weak self] in
            guard let self = self else { return }
            guard !self.reactRuntime.closed else {
                print("PaymentSession: getCustomerSavedPaymentMethods called on a closed session")
                return
            }
            var props: [String: Any] = [
                "type": "headless",
                "hyperswitchConfig": hyperswitchConfiguration as Any,
                "paymentSessionConfig": paymentSessionConfiguration as Any,
                "sdkParams": self.sdkParams(),
            ]
            props["configuration"] = [
                "paymentMethodLayout": [
                    "savedMethodCustomization": configurationDict
                ]
            ]

            let attempt = HeadlessAttempt(
                sdkAuthorization: { [weak self] in self?.paymentSessionConfiguration.sdkAuthorization ?? "" },
                onHandler: func_
            )
            if let previous = self.reactRuntime.headless {
                previous.attempt.cancel()
                previous.surface.stop()
            }
            let surface = self.reactRuntime.makeSurface("HyperHeadless", ["props": props], attempt)
            self.reactRuntime.headless = (surface, attempt)
        }
    }
}

/// A viewless surface of a session, as the session drives it. `HeadlessSurface` is the
/// production one; tests substitute a fake to exercise the session's state machine.
internal protocol SessionSurface: AnyObject {
    var rootTag: Int { get }
    func updateProps(_ props: [String: Any])
    func stop()
    func awaitStarted() async
}

extension HeadlessSurface: SessionSurface {}

internal final class UpdateIntentAttempt {
    let completion: (UpdateIntentResult) -> Void
    var configuration: PaymentSessionConfiguration?

    init(completion: @escaping (UpdateIntentResult) -> Void) {
        self.completion = completion
    }
}

/// This session's surfaces on the shared host. The prefetch surface is the session's
/// identity in JS and lives as long as the session; the saved-payment-methods surface is
/// owned by its attempt. Main thread.
internal final class PaymentSessionReactRuntime {
    /// The running prefetch surface and the props it currently renders.
    var prefetch: (surface: SessionSurface, props: [String: Any])?
    var headless: (surface: SessionSurface, attempt: HeadlessAttempt)?
    /// Creates a surface on the shared host; replaced by tests with a fake.
    var makeSurface: (_ moduleName: String, _ initialProperties: [String: Any], _ owner: AnyObject) -> SessionSurface = {
        HeadlessSurface(host: RNViewManager.shared, moduleName: $0, initialProperties: $1, owner: $2)
    }
    var updateIntentAttempt: UpdateIntentAttempt?
    /// Numbers updateIntent calls so the surface can tell consecutive ones apart.
    var updateIntentSequence = 0
    /// Set by `close()`: no surface is started again for this session.
    var closed = false

    deinit {
        // A dropped session stops its surfaces and fails what still waits on them; UIKit
        // work goes to the main thread.
        let prefetch = self.prefetch?.surface
        let headless = self.headless
        let pending = self.updateIntentAttempt
        DispatchQueue.main.async {
            pending?.completion(.failure(NSError(
                domain: "SESSION_CLOSED", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "The payment session was released"]
            )))
            prefetch?.stop()
            headless?.attempt.cancel()
            headless?.surface.stop()
        }
    }
}

extension PaymentSession: UpdateIntentReplyTarget {

    internal var reactManager: RNViewManager { RNViewManager.shared }

    /// The session's identity in JS: the root tag of its prefetch surface.
    internal var sessionTag: Int? { reactRuntime.prefetch?.surface.rootTag }

    /// SDK params for a surface of this session, carrying the session tag so JS scopes
    /// session-wide events to it.
    internal func sdkParams() -> [String: Any?] {
        var params = SDKParams.getSDKParams()
        params["sessionTag"] = sessionTag
        return params
    }

    /// Starts the prefetch surface and resolves once it is running, which is when its
    /// requests are on their way.
    internal func activateRuntime() async {
        let surface = await MainActor.run { ensurePrefetchSurface() }
        await surface?.awaitStarted()
    }

    /// Main thread. Starts the prefetch surface once, under the session's credentials. Its
    /// root tag is the session's identity for every other surface, so it is never
    /// replaced; a changed intent reaches it through its props. Nil once the session closed.
    @discardableResult
    private func ensurePrefetchSurface() -> SessionSurface? {
        if let current = reactRuntime.prefetch {
            return current.surface
        }
        guard !reactRuntime.closed else { return nil }
        let props: [String: Any] = [
            "type": "prefetch",
            "hyperswitchConfig": (try? hyperswitchConfiguration?.toDictionary()) as Any,
            "paymentSessionConfig": (try? paymentSessionConfiguration.toDictionary()) as Any,
            "sdkParams": SDKParams.getSDKParams(),
        ]
        let initialProperties: [String: Any] = ["props": props]
        let surface = reactRuntime.makeSurface("HyperHeadless", initialProperties, self)
        reactRuntime.prefetch = (surface, initialProperties)
        return surface
    }

    /// Main thread. Re-renders the prefetch root with an `updateIntent` marker and, for
    /// `complete`, the new `paymentSessionConfig`. The surface then carries the attempted
    /// credentials whatever the outcome, as JS switched to them; the session's own
    /// configuration only commits on success.
    private func pushUpdateIntent(phase: String, configuration: PaymentSessionConfiguration?) {
        guard var current = reactRuntime.prefetch else { return }
        var inner = current.props["props"] as? [String: Any] ?? [:]
        if let configuration = configuration {
            inner["paymentSessionConfig"] = (try? configuration.toDictionary()) as Any
        }
        inner["updateIntent"] = ["attempt": reactRuntime.updateIntentSequence, "phase": phase]
        current.props["props"] = inner
        reactRuntime.prefetch = current
        current.surface.updateProps(current.props)
    }

    internal func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    /// Stops this session's surfaces on the shared host and fails whatever is still waiting
    /// on them. A session that is simply released does the same in deinit.
    public func close() {
        onMain { [self] in
            reactRuntime.closed = true
            failPendingUpdateIntent("SESSION_CLOSED", "The payment session was closed")
            if let headless = reactRuntime.headless {
                headless.attempt.cancel()
                headless.surface.stop()
            }
            reactRuntime.headless = nil
            reactRuntime.prefetch?.surface.stop()
            reactRuntime.prefetch = nil
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
            guard self.ensurePrefetchSurface() != nil else {
                completion(.failure(Self.error("SESSION_CLOSED", "The payment session was closed")))
                return
            }
            let attempt = UpdateIntentAttempt(completion: completion)
            self.reactRuntime.updateIntentAttempt = attempt
            self.reactRuntime.updateIntentSequence += 1
            self.pushUpdateIntent(phase: "init", configuration: nil)

            authorizationProvider { [weak self] sdkAuthorization in
                self?.onMain { self?.refetch(with: sdkAuthorization, attempt: attempt) }
            }
        }
    }

    private func refetch(with sdkAuthorization: String, attempt: UpdateIntentAttempt) {
        guard reactRuntime.updateIntentAttempt === attempt else { return }
        guard !sdkAuthorization.isEmpty else {
            // The overlay went up on `init`; JS lowers it on `cancel`.
            pushUpdateIntent(phase: "cancel", configuration: nil)
            finish(attempt, .failure(Self.error("INVALID_SDK_AUTHORIZATION", "No sdkAuthorization was provided")))
            return
        }
        guard reactRuntime.prefetch != nil else {
            finish(attempt, .failure(Self.error("SESSION_CLOSED", "The payment session was closed")))
            return
        }
        let configuration = PaymentSessionConfiguration(sdkAuthorization: sdkAuthorization)
        attempt.configuration = configuration

        pushUpdateIntent(phase: "complete", configuration: configuration)
    }

    /// JS reply, routed here because this session owns the prefetch surface it came from.
    internal func onUpdateIntentReply(type: String, result: String) {
        onMain { [weak self] in self?.handleUpdateIntentReply(type: type, result: result) }
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
        reactRuntime.updateIntentAttempt = nil
        attempt.completion(result)
    }

    /// Ends the attempt in flight once native knows its JS reply can no longer arrive, and
    /// tells the surface so the session's other surfaces lower their overlay.
    private func failPendingUpdateIntent(_ code: String, _ message: String) {
        if let attempt = reactRuntime.updateIntentAttempt {
            pushUpdateIntent(phase: "cancel", configuration: nil)
            finish(attempt, .failure(Self.error(code, message)))
        }
    }

    private static func error(_ domain: String, _ message: String) -> NSError {
        NSError(domain: domain, code: 0, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
