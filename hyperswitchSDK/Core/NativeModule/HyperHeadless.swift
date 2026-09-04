//
//  HyperHeadless.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 01/08/26.
//

import Foundation
import UIKit
import WebKit

@objc(HyperHeadlessShim)
internal protocol HyperHeadlessShim: NSObjectProtocol {
    @objc(attachImpl:)
    func attach(impl: HyperHeadlessImpl)
    @objc(viewForRootTag:)
    func view(forRootTag rootTag: NSNumber) -> UIView?
}

@objc(HyperHeadlessImpl)
internal class HyperHeadlessImpl: NSObject {

    private weak var activeSession: PaymentSession?
    private var headlessCompletion: ((PaymentSessionHandler) -> Void)?
    private var completion: ((PaymentResult) -> Void)?
    private var hasResponded = false

    /* One headless root per session, mounted at the session's first headless request and kept
       for its life. The retained root is the liveness probe into the surface presenter (via its
       surfaceRootTag) and keeps the surface alive. */
    private var headlessRootView: UIView?
    private var prefetchContinuation: CheckedContinuation<[String: Any]?, Never>?
    private var prefetchTimeoutItem: DispatchWorkItem?

    /* SDK-side last-resort budget; JS has none of its own. Same 30s window as Android. */
    private static let prefetchTimeout: DispatchTimeInterval = .seconds(30)

    private weak var shim: HyperHeadlessShim?

    internal func attach(to shim: HyperHeadlessShim) {
        shim.attach(impl: self)
        DispatchQueue.main.async {
            self.shim = shim
        }
    }

    internal func begin(session: PaymentSession, completion: @escaping (PaymentSessionHandler) -> Void) {
        hasResponded = false
        headlessCompletion = completion
        activeSession = session
    }

    /* The session's single dispatch point: after the first mount everything is a headlessRequest
       event into the live JS closure. Liveness comes from the surface presenter, not emit
       success: emitChecked proves only that a module is attached, and after a runtime restart
       the module re-attaches long before the new runtime mounts a headless root — the event
       would fall on the floor and the merchant's callback would hang. A surface from a dead
       runtime no longer resolves, so a dead root self-heals into a fresh mount. */
    internal func request(props: [String: Any]) {
        DispatchQueue.main.async {
            let manager = RNViewManager.sharedInstance
            if let root = self.headlessRootView,
               let tag = root.surfaceRootTag,
               self.shim?.view(forRootTag: tag) != nil,
               manager.hyperModule.emitChecked("headlessRequest", props) {
                return
            }
            self.headlessRootView = manager.widgetViewForModule(
                "HyperHeadless", initialProperties: ["props": props]
            )
        }
    }

    /* Registers the waiter before the mount/emit so the reply can never beat the registration.
       The slot is single: any prior waiter is released as a prefetch miss before retaking it —
       clobbering it would strand that await forever (a prefetch miss is not fatal; the caller
       fetches for itself). */
    internal func requestAndAwait(props: [String: Any]) async -> [String: Any]? {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.prefetchTimeoutItem?.cancel()
                self.prefetchTimeoutItem = nil
                self.resolvePrefetch(nil)
                self.prefetchContinuation = continuation
                let item = DispatchWorkItem { [weak self] in
                    self?.resolvePrefetch(nil)
                }
                self.prefetchTimeoutItem = item
                DispatchQueue.main.asyncAfter(deadline: .now() + Self.prefetchTimeout, execute: item)
                self.request(props: props)
            }
        }
    }

    /* Ends the session's root when a new initPaymentSession supersedes it — not on a terminal
       payment result: a saved-methods request may still follow. Releasing the surface ends the
       root on its own: the task's JS promise never resolves, which is inert — nothing awaits it,
       and the subscription HeadlessTask installs is runtime-lifetime module state. No shutdown
       event: it would race the next session's mount through the JS queue. */
    internal func finishHeadlessRoot() {
        DispatchQueue.main.async {
            self.headlessRootView = nil
            self.prefetchTimeoutItem?.cancel()
            self.prefetchTimeoutItem = nil
            self.resolvePrefetch(nil)
        }
    }

    /* Completion signal for one payment's prefetch. The payload itself lives only in the
       JS PrefetchCache (shared VM); native just resumes the awaiting session. */
    @objc(completePrefetch:data:)
    internal func completePrefetch(_ rootTag: NSNumber, _ data: NSDictionary) {
        DispatchQueue.main.async {
            self.prefetchTimeoutItem?.cancel()
            self.prefetchTimeoutItem = nil
            self.resolvePrefetch(data as? [String: Any])
        }
    }

    private func resolvePrefetch(_ data: [String: Any]?) {
        let continuation = prefetchContinuation
        prefetchContinuation = nil
        continuation?.resume(returning: data)
    }

    private func safeResolve(
        _ callback: @escaping ([Any]?) -> Void,
        _ result: [Any],
        _ resultHandler: @escaping (PaymentResult) -> Void
    ) {
        guard !hasResponded else {
            print("Warning: Attempt to resolve callback more than once")
            resultHandler(.failed(error: NSError(domain: "Not Initialised", code: 0, userInfo: ["message": "An error has occurred."])))
            return
        }
        hasResponded = true
        callback(result)
    }

    @objc(getPaymentSession:paymentIntentData:defaultPaymentMethod:savedPaymentMethods:callback:)
    internal func getPaymentSession(
        _ rootTag: NSNumber,
        _ rnMessage: NSDictionary,
        _ rnMessage2: NSDictionary,
        _ rnMessage3: NSArray,
        _ rnCallback: @escaping ([Any]?) -> Void
    ) {
        DispatchQueue.main.async {
            self.hasResponded = false
            let handler = PaymentSessionHandler(
                getCustomerDefaultSavedPaymentMethodData: {
                    return HyperHeadlessImpl.decodePaymentMethodData(rnMessage)
                },
                getCustomerLastUsedPaymentMethodData: {
                    return HyperHeadlessImpl.decodePaymentMethodData(rnMessage2)
                },
                getCustomerSavedPaymentMethodData: {
                    var array = [PaymentMethod]()
                    for i in 0..<rnMessage3.count {
                        if let map = rnMessage3[i] as? NSDictionary {
                            switch HyperHeadlessImpl.decodePaymentMethodData(map) {
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
                    if let paymentToken = rnMessage["payment_token"] as? String {
                        self.completion = resultHandler
                        var map = [String: Any]()
                        map["paymentToken"] = paymentToken
                        map["cvc"] = cvc
                        self.safeResolve(rnCallback, [map], resultHandler)
                    } else {
                        /* No default method exists (JS sends an error payload without a token):
                           main's missing else left resultHandler uncalled forever. */
                        resultHandler(.failed(error: NSError(
                            domain: "MISSING_PAYMENT_TOKEN",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "Saved payment method has no payment token"]
                        )))
                    }
                },
                confirmWithCustomerLastUsedPaymentMethod: { cvc, resultHandler in
                    if let paymentToken = rnMessage2["payment_token"] as? String {
                        cvc.awaitConfirmResult(resultHandler)
                        if !cvc.confirm(
                            sdkAuthorization: self.activeSession?.paymentSessionConfiguration.sdkAuthorization ?? "",
                            paymentToken: paymentToken
                        ) {
                            cvc.resolveConfirmResult(.failed(error: NSError(
                                domain: "RUNTIME_UNAVAILABLE",
                                code: 0,
                                userInfo: [NSLocalizedDescriptionKey: "React runtime is not available"]
                            )))
                        }
                    } else {
                        resultHandler(.failed(error: NSError(
                            domain: "MISSING_PAYMENT_TOKEN",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "Saved payment method has no payment token"]
                        )))
                    }
                },
                confirmWithCustomerPaymentToken: { paymentToken, cvc, resultHandler in
                    self.completion = resultHandler
                    var map = [String: Any]()
                    map["paymentToken"] = paymentToken
                    map["cvc"] = cvc
                    self.safeResolve(rnCallback, [map], resultHandler)
                }
            )
            self.headlessCompletion?(handler)
        }
    }

    /* Replies route by root tag, exactly as on main: a reply from a CVC widget's own surface
       goes to that widget; anything else is the headless root's own reply. */
    @objc(exitHeadless:status:code:message:)
    internal func exitHeadless(_ rootTag: NSNumber, _ status: String, _ code: String?, _ message: String?) {
        DispatchQueue.main.async {
            let result = PaymentResult.from(status: status, code: code, message: message)

            if let widget = self.cvcWidget(forRootTag: rootTag) {
                widget.resolveConfirmResult(result)
                return
            }
            self.completion?(result)
        }
    }

    private func cvcWidget(forRootTag rootTag: NSNumber) -> CVCWidget? {
        return shim?.view(forRootTag: rootTag)?.nearestAncestor(ofType: CVCWidget.self)
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
