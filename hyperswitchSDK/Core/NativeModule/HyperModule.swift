//
//  HyperModule.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 07/03/24.
//

import Foundation
import React

extension PaymentResult {
    internal static func from(status: String, code: String?, message: String?) -> PaymentResult {
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

@objc(HyperModuleShim)
internal protocol HyperModuleShim: NSObjectProtocol {
    @objc(attachImpl:)
    func attach(impl: HyperModuleImpl)
    @objc(emitEventWithName:payload:)
    func emitEvent(name: String, payload: [String: Any])
    @objc(viewForRootTag:)
    func view(forRootTag rootTag: NSNumber) -> UIView?
    @objc(surfaceForRootTag:)
    func surface(forRootTag rootTag: NSNumber) -> AnyObject?
}

@objc(HyperModuleImpl)
internal class HyperModuleImpl: NSObject {

    internal weak var host: ReactHostManager?

    private let applePayPaymentHandler = ApplePayHandler()
    private var presentCallback: (([Any]?) -> Void)? = nil

    internal var onAddPaymentMethod: (() -> Void)?

    private weak var shim: HyperModuleShim?

    internal func attach(to shim: HyperModuleShim) {
        shim.attach(impl: self)
        onMain {
            self.shim = shim
        }
    }

    /// Native → JS event on the shared host, dropped if JS has not instantiated this module
    /// yet. Commands that must not be lost (widget confirms, updateIntent) go through the
    /// target surface's props instead.
    internal func emit(_ name: String, _ payload: [String: Any]) {
        onMain {
            self.shim?.emitEvent(name: name, payload: payload)
        }
    }

    internal func confirm(data: [String: Any]) {
        emit("confirm", data)
    }
    // MARK: WIP
    //    func confirmEC(data: [String: Any]) {
    //        self.emitEvent("confirmEC", data)
    //    }

    private func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    @objc(onAddPaymentMethod:)
    internal func onAddPaymentMethod(_ rnMessage: String) {
        self.onAddPaymentMethod?()
    }

    @objc(launchApplePay:callback:)
    internal func launchApplePay(_ rnMessage: String, _ rnCallback: @escaping ([Any]?) -> Void) {
        applePayPaymentHandler.startPayment(rnMessage: rnMessage, rnCallback: rnCallback, presentCallback: self.presentCallback)
    }

    @objc(startApplePay:callback:)
    internal func startApplePay(_ rnMessage: String, _ rnCallback: @escaping ([Any]?) -> Void) {
        rnCallback([])
    }

    @objc(presentApplePay:callback:)
    internal func presentApplePay(_ rnMessage: String, _ rnCallback: @escaping ([Any]?) -> Void) {
        self.presentCallback = rnCallback
    }

    @objc(launchGPay:callback:)
    internal func launchGPay(_ rnMessage: String, _ rnCallback: @escaping ([Any]?) -> Void) {
    }

    @objc(exitPaymentsheet:status:code:message:reset:)
    internal func exitPaymentsheet(_ reactTag: NSNumber, _ status: String, _ code: String?, _ message: String?, _ reset: Bool) {
        let result = PaymentResult.from(status: status, code: code, message: message)
        withPaymentSheet(reactTag) { vc, sheet in
            guard let vc = vc else {
                sheet?.completion?(result)
                return
            }
            vc.dismiss(animated: false) { sheet?.completion?(result) }
        }
    }

    @objc(exitWidgetPaymentsheet:status:code:message:reset:)
    internal func exitWidgetPaymentsheet(_ reactTag: NSNumber, _ status: String, _ code: String?, _ message: String?, _ reset: Bool) {
        let result = PaymentResult.from(status: status, code: code, message: message)
        withWidget(reactTag) { w in
            w.handleConfirmPaymentResponse(result)
        }
    }

    @objc(exitPaymentMethodManagement:result:reset:)
    internal func exitPaymentMethodManagement(_ reactTag: NSNumber, _ rnMessage: String, _ reset: Bool) {
        resolveOwner(reactTag) { owner in
            self.exitSheet(rnMessage, handler: owner as? RNResponseHandler)
        }
    }

    @objc(exitWidget:code:message:widgetType:)
    internal func exitWidget(_ status: String, _ code: String?, _ message: String?, _ widgetType: String) {
    }

    @objc(updateWidgetHeight:)
    internal func updateWidgetHeight(_ height: NSNumber) {
    }

    @objc(notifyWidgetPaymentResult:status:code:message:)
    internal func notifyWidgetPaymentResult(_ rootTag: NSNumber, _ status: String, _ code: String?, _ message: String?) {
        let result = PaymentResult.from(status: status, code: code, message: message)
        withWidget(rootTag) { w in
            w.handleNonTerminalResult(result)
        }
    }

    @objc(onUpdateIntentEvent:eventType:status:code:message:)
    internal func onUpdateIntentEvent(_ rootTag: NSNumber, _ type: String, _ status: String, _ code: String?, _ message: String?) {
        let result = Self.encodeExitResult(status: status, code: code, message: message)
        resolveOwner(rootTag) { owner in
            guard let target = owner as? UpdateIntentReplyTarget else {
                print("HyperModule: onUpdateIntentEvent has no prefetch owner for rootTag \(rootTag) (\(type))")
                return
            }
            target.onUpdateIntentReply(type: type, result: result)
        }
    }

    private static func encodeExitResult(status: String, code: String?, message: String?) -> String {
        var dict: [String: String] = ["status": status]
        dict["code"] = code
        dict["message"] = message
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
            let json = String(data: data, encoding: .utf8)
        else {
            return "{\"status\":\"failed\"}"
        }
        return json
    }

    @objc(emitPaymentEvent:eventType:payload:)
    internal func emitPaymentEvent(_ rootTag: NSNumber, _ eventType: String, _ payload: NSDictionary) {
        let map = (payload as? [String: Any]) ?? [:]
        resolveSubscribingTarget(rootTag) { target in
            if let widget = target as? PaymentWidget, widget.paymentEventListener != nil {
                widget.dispatchPaymentEvent(type: eventType, payload: map)
            } else if let cvc = target as? CVCWidget, cvc.paymentEventListener != nil {
                cvc.dispatchPaymentEvent(type: eventType, payload: map)
            } else if let sheet = target as? PaymentSheet, sheet.paymentEventListener != nil {
                sheet.dispatchPaymentEvent(type: eventType, payload: map)
            }
        }
    }

    @objc(exitCardForm:)
    internal func exitCardForm(_ rnMessage: String) {
        var response: String?
        var error: NSError?

        if let data = rnMessage.data(using: .utf8) {
            do {
                if let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                    let status = jsonDictionary["status"]

                    if status == "failed" || status == "requires_payment_method" {
                        error = NSError(
                            domain: (jsonDictionary["code"] ?? "") != "" ? jsonDictionary["code"]! : "UNKNOWN_ERROR",
                            code: 0,
                            userInfo: ["message": jsonDictionary["message"] ?? "An error has occurred."]
                        )
                    } else {
                        response = status
                    }
                    self.host?.responseHandler?.didReceiveResponse(response: response, error: error)
                } else {
                    self.host?.responseHandler?.didReceiveResponse(
                        response: "failed",
                        error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
                    )
                }
            } catch {
                self.host?.responseHandler?.didReceiveResponse(
                    response: "failed",
                    error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
                )
            }
        } else {
            self.host?.responseHandler?.didReceiveResponse(
                response: "failed",
                error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
            )
        }
    }

    /// Main thread. [handler] is the owner of the surface that exited when it has one;
    /// single-root flows without an owner fall back to the host's response handler.
    private func exitSheet(_ rnMessage: String, handler: RNResponseHandler?) {
        var response: String?
        var error: NSError?
        let unknownError = NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])

        if let data = rnMessage.data(using: .utf8),
            let jsonDictionary = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: String]
        {
            let status = jsonDictionary["status"]
            if status == "failed" || status == "requires_payment_method" {
                error = NSError(
                    domain: (jsonDictionary["code"] ?? "") != "" ? jsonDictionary["code"]! : "UNKNOWN_ERROR",
                    code: 0,
                    userInfo: ["message": jsonDictionary["message"] ?? "An error has occurred."]
                )
            } else {
                response = status
            }
        } else {
            response = "failed"
            error = unknownError
        }
        let target = handler ?? self.host?.responseHandler
        let deliver = { target?.didReceiveResponse(response: response, error: error) }
        guard let vc = self.host?.rootView?.reactViewController() else {
            deliver()
            return
        }
        vc.dismiss(animated: false) { deliver() }
    }

    @objc(onPaymentConfirmButtonClick:payload:callback:)
    internal func onPaymentConfirmButtonClick(_ rootTag: NSNumber, _ payload: String, _ callback: @escaping ([Any]?) -> Void) {
        resolveSubscribingTarget(rootTag) { target in
            if let widget = target as? PaymentWidget {
                widget.handleShouldProceedWithPayment(payload: payload) { shouldProceed in
                    callback([shouldProceed])
                }
            } else if let sheet = target as? PaymentSheet {
                sheet.handleShouldProceedWithPayment(payload: payload) { shouldProceed in
                    callback([shouldProceed])
                }
            } else {
                callback([true])
            }
        }
    }

    @objc(openIframeBridge:timeoutMs:callback:)
    internal func openIframeBridge(_ url: String, _ timeoutMs: NSNumber, _ callback: @escaping ([Any]?) -> Void) {
        DispatchQueue.main.async {
            let headlessWebView = HeadlessWebView(url: url, timeoutMs: timeoutMs, callback: callback)
            headlessWebView.startFlow()
        }
    }

    private func withWidget(_ rootTag: NSNumber, _ block: @escaping (PaymentWidget) -> Void) {
        resolveOwner(rootTag) { owner in
            guard let widget = owner as? PaymentWidget else { return }
            block(widget)
        }
    }

    private func resolveSubscribingTarget(_ rootTag: NSNumber, _ block: @escaping (AnyObject?) -> Void) {
        resolveOwner(rootTag, block)
    }

    /// Root tag → surface object → the native object that owns it (a sheet, a widget, a
    /// session or a headless attempt). Main thread.
    private func resolveOwner(_ rootTag: NSNumber, _ block: @escaping (AnyObject?) -> Void) {
        DispatchQueue.main.async {
            guard let surface = self.shim?.surface(forRootTag: rootTag) else {
                block(nil)
                return
            }
            block(SurfaceOwners.owner(of: surface))
        }
    }

    private func withPaymentSheet(_ rootTag: NSNumber, _ block: @escaping (UIViewController?, PaymentSheet?) -> Void) {
        resolveOwner(rootTag) { owner in
            let sheet = owner as? PaymentSheet
            block(sheet?.presentedViewController, sheet)
        }
    }
}
