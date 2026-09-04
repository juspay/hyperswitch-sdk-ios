//
//  PaymentSession+UIKit.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 30/08/24.
//

import Foundation
import UIKit

extension PaymentSession {

    /* Same props map on every headless request — mount and event paths carry it verbatim;
       during updateIntent the passed (new) configuration is used, not the session's. */
    internal func headlessProps(
        headlessType: String,
        configuration: PaymentSessionConfiguration? = nil
    ) -> [String: Any] {
        let hyperswitchConfig = try? hyperswitchConfiguration?.toDictionary()
        let paymentSessionConfig = try? (configuration ?? paymentSessionConfiguration).toDictionary()
        return [
            "hyperswitchConfig": hyperswitchConfig as Any,
            "paymentSessionConfig": paymentSessionConfig as Any,
            "sdkParams": SDKParams.getSDKParams(),
            "headlessType": headlessType,
        ]
    }

    /// Runs the initial prefetch headless task and waits for its result.
    ///
    /// A prefetch miss is not fatal: the sheet and headless flows fall back to making the API
    /// calls themselves, so a timeout resolves with no data rather than propagating an error.
    internal func triggerPrefetch() async {
        let configuration = paymentSessionConfiguration
        /* One headless root per session: a re-init releases the previous session's root before
           this prefetch mounts or reuses one. */
        RNViewManager.sharedInstance.headlessModule.finishHeadlessRoot()
        /* The fetched payload lives only in the JS PrefetchCache; this waits purely so the
           cache is warm before the merchant is allowed to present UI. */
        let data = await loadHeadlessData(
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

    /// Fetches the new intent's data without mutating the active session. Returns nil when the
    /// fetch produced nothing usable (timeout or wedged bridge).
    internal func fetchIntentUpdate(
        configuration: PaymentSessionConfiguration
    ) async -> [String: Any]? {
        await loadHeadlessData(
            headlessType: "updateIntent",
            configuration: configuration
        )
    }

    /* The continuation and its timeout live on the headless module, not in file scope: the impl
       owns the root they reply to. */
    private func loadHeadlessData(
        headlessType: String,
        configuration: PaymentSessionConfiguration
    ) async -> [String: Any]? {
        guard !configuration.sdkAuthorization.isEmpty else {
            return nil
        }
        return await RNViewManager.sharedInstance.headlessModule.requestAndAwait(
            props: headlessProps(headlessType: headlessType, configuration: configuration)
        )
    }

    internal func clearPrefetch(for sdkAuthorization: String) {
        guard !sdkAuthorization.isEmpty else { return }
        RNViewManager.sharedInstance.removePrefetchCache(
            sdkAuthorization: sdkAuthorization
        )
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

    /* The session's headless root mounts once (at prefetch); this is either the mount on a cold
       start or a headlessRequest event into the live root. The reply arrives on the impl by
       rootTag (HyperHeadlessImpl.getPaymentSession), as on main. */
    public func getCustomerSavedPaymentMethods(
        _ func_: @escaping (PaymentSessionHandler) -> Void,
        configuration: SavedPaymentMethodsConfiguration? = nil
    ) {
        let manager = RNViewManager.sharedInstance
        manager.headlessModule.begin(session: self, completion: func_)
        var props = headlessProps(headlessType: "savedPM")
        props["configuration"] = [
            "paymentMethodLayout": [
                "savedMethodCustomization": try? configuration?.toDictionary()
            ]
        ]
        manager.headlessModule.request(props: props)
    }
}
