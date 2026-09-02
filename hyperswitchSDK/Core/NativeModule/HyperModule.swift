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
        case "failed", "requires_payment_method":
            let domain = (code?.isEmpty == false) ? code! : "UNKNOWN_ERROR"
            return .failed(
                error: NSError(
                    domain: domain,
                    code: 0,
                    userInfo: ["message": message ?? "An error has occurred."]
                )
            )
        default:
            return .completed(data: status)
        }
    }
}

@objc(HyperModuleShim)
internal protocol HyperModuleShim: NSObjectProtocol {
    @objc(attachImpl:)
    func attach(impl: HyperModuleImpl)
    /* Returns false when the JS event emitter is not armed (detached runtime):
       callers holding a pending confirmation registration must roll it back. */
    @objc(emitEventWithName:payload:)
    func emitEvent(name: String, payload: [String: Any]) -> Bool
    @objc(viewForRootTag:)
    func view(forRootTag rootTag: NSNumber) -> UIView?
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

    internal func emit(_ name: String, _ payload: [String: Any]) {
        onMain {
            _ = self.shim?.emitEvent(name: name, payload: payload)
        }
    }

    /* Synchronous, main-thread delivery check for callers that registered a
       pending confirmation: false means the event can never reach JS. */
    @discardableResult
    internal func emitChecked(_ name: String, _ payload: [String: Any]) -> Bool {
        dispatchPrecondition(condition: .onQueue(.main))
        return shim?.emitEvent(name: name, payload: payload) ?? false
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
            sheet?.completion?(result)
            vc?.dismiss(animated: false, completion: nil)
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
        exitSheet(rnMessage)
    }

    @objc(exitWidget:code:message:widgetType:)
    internal func exitWidget(_ status: String, _ code: String?, _ message: String?, _ widgetType: String) {
    }

    @objc(updateWidgetHeight:)
    internal func updateWidgetHeight(_ height: NSNumber) {
    }

    @objc(notifyWidgetPaymentResult:status:code:message:)
    internal func notifyWidgetPaymentResult(_ rootTag: NSNumber, _ status: String, _ code: String?, _ message: String?) {
    }

    @objc(onUpdateIntentEvent:eventType:status:code:message:)
    internal func onUpdateIntentEvent(_ rootTag: NSNumber, _ type: String, _ status: String, _ code: String?, _ message: String?) {
        let result = Self.encodeExitResult(status: status, code: code, message: message)
        withWidget(rootTag) { widget in
            widget.handleUpdateIntentEvent(type: type, result: result)
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

    private func exitSheet(_ rnMessage: String) {
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
        DispatchQueue.main.async {
            if let view = self.host?.rootView {
                let reactNativeVC: UIViewController? = view.reactViewController()
                reactNativeVC?.dismiss(animated: false, completion: nil)
            }
        }
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
        DispatchQueue.main.async {
            guard let widget = self.shim?.view(forRootTag: rootTag)?
                .nearestAncestor(ofType: PaymentWidget.self)
            else { return }
            block(widget)
        }
    }

    private func resolveSubscribingTarget(_ rootTag: NSNumber, _ block: @escaping (AnyObject?) -> Void) {
        DispatchQueue.main.async {
            guard let view = self.shim?.view(forRootTag: rootTag) else {
                block(nil)
                return
            }
            if let widget = view.nearestAncestor(where: { $0 is PaymentWidget || $0 is CVCWidget }) {
                block(widget)
                return
            }
            block((view.reactViewController() as? HyperUIViewController)?.paymentSheet)
        }
    }

    private func withPaymentSheet(_ rootTag: NSNumber, _ block: @escaping (UIViewController?, PaymentSheet?) -> Void) {
        DispatchQueue.main.async {
            let view = self.shim?.view(forRootTag: rootTag)
            let vc = view?.reactViewController() as? HyperUIViewController
            let sheet = vc?.paymentSheet
            block(vc, sheet)
        }
    }
}
