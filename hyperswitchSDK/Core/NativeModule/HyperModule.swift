//
//  HyperModule.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 07/03/24.
//

import Foundation
import React

@objc(HyperModuleShim)
internal protocol HyperModuleShim: NSObjectProtocol {
    @objc(attachImpl:)
    func attach(impl: HyperModuleImpl)
    @objc(emitEventWithName:payload:)
    func emitEvent(name: String, payload: [String: Any])
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

    @objc(sendMessageToNative:)
    internal func sendMessageToNative(_ rnMessage: String) {
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

    @objc(exitPaymentsheet:result:reset:)
    internal func exitPaymentsheet(_ reactTag: NSNumber, _ rnMessage: String, _ reset: Bool) {
        let result = paymentResult(from: rnMessage)
        withPaymentSheet(reactTag) { vc, sheet in
            sheet?.completion?(result)
            vc?.dismiss(animated: false, completion: nil)
        }
    }

    @objc(exitWidgetPaymentsheet:result:reset:)
    internal func exitWidgetPaymentsheet(_ reactTag: NSNumber, _ rnMessage: String, _ reset: Bool) {
        let result = paymentResult(from: rnMessage)
        withWidget(reactTag) { w in
            w.handleConfirmPaymentResponse(result)
        }
    }

    private func paymentResult(from rnMessage: String) -> PaymentResult {
        guard let data = rnMessage.data(using: .utf8) else {
            return .failed(
                error: NSError(
                    domain: "UNKNOWN_ERROR",
                    code: 0,
                    userInfo: ["message": "An error has occurred."]
                )
            )
        }

        do {
            guard let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] else {
                return .failed(
                    error: NSError(
                        domain: "UNKNOWN_ERROR",
                        code: 0,
                        userInfo: ["message": "An error has occurred."]
                    )
                )
            }

            let status = jsonDictionary["status"]

            if status == "failed" || status == "requires_payment_method" {
                let error = NSError(
                    domain: (jsonDictionary["code"] ?? "") != "" ? jsonDictionary["code"]! : "UNKNOWN_ERROR",
                    code: 0,
                    userInfo: ["message": jsonDictionary["message"] ?? "An error has occurred."]
                )
                return .failed(error: error)
            } else if status == "cancelled" {
                return .canceled(data: "cancelled")
            } else {
                return .completed(data: status ?? "failed")
            }
        } catch {
            return .failed(
                error: NSError(
                    domain: "UNKNOWN_ERROR",
                    code: 0,
                    userInfo: ["message": "An error has occurred."]
                )
            )
        }
    }

    @objc(exitPaymentMethodManagement:result:reset:)
    internal func exitPaymentMethodManagement(_ reactTag: NSNumber, _ rnMessage: String, _ reset: Bool) {
        exitSheet(rnMessage)
    }

    @objc(exitWidget:widgetType:)
    internal func exitWidget(_ rnMessage: String, _ widgetType: String) {
    }

    @objc(updateWidgetHeight:)
    internal func updateWidgetHeight(_ height: NSNumber) {
    }

    @objc(notifyWidgetPaymentResult:result:)
    internal func notifyWidgetPaymentResult(_ rootTag: NSNumber, _ rnMessage: String) {
    }

    @objc(onUpdateIntentEvent:eventType:result:)
    internal func onUpdateIntentEvent(_ rootTag: NSNumber, _ type: String, _ result: String) {
        withWidget(rootTag) { widget in
            widget.handleUpdateIntentEvent(type: type, result: result)
        }
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
