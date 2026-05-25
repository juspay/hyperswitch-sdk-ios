//
//  HyperModule.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 07/03/24.
//

import Foundation
import React
import WebKit

@objc(HyperModule)
internal class HyperModule: RCTEventEmitter {

    private let applePayPaymentHandler = ApplePayHandler()
    private let expressCheckoutHandler = ExpressCheckoutLauncher()
    private var presentCallback: RCTResponseSenderBlock? = nil
    internal static var shared: HyperModule?

    override init() {
        super.init()
        HyperModule.shared = self
    }

    @objc
    internal override static func requiresMainQueueSetup() -> Bool {
        return true
    }

    @objc
    internal override func supportedEvents() -> [String] {
        return ["confirm", "confirmEC", "triggerWidgetAction", "updateIntentInit", "updateIntentComplete"]
    }

    @objc
    internal func confirm(data: [String: Any]) {
        self.sendEvent(withName: "confirm", body: data)
    }
    // MARK: WIP
    //    @objc func confirmEC(data: [String: Any]) {
    //        self.sendEvent(withName: "confirmEC", body: data)
    //    }

    @objc
    private func sendMessageToNative(_ rnMessage: String) {}

    @objc
    private func launchWidgetPaymentSheet(_ request: NSMutableDictionary, _ callback: @escaping RCTResponseSenderBlock) {
        expressCheckoutHandler.launchPaymentSheet(paymentResult: request, callBack: callback)
    }

    @objc
    private func onAddPaymentMethod(_ rnMessage: String) {
        PaymentMethodManagementWidget.onAddPaymentMethod?()
    }

    @objc
    private func launchApplePay(_ rnMessage: String, _ rnCallback: @escaping RCTResponseSenderBlock) {
        applePayPaymentHandler.startPayment(rnMessage: rnMessage, rnCallback: rnCallback, presentCallback: self.presentCallback)
    }

    @objc
    private func startApplePay(_ rnMessage: String, _ rnCallback: @escaping RCTResponseSenderBlock) {
        rnCallback([])
    }

    @objc
    private func presentApplePay(_ rnMessage: String, _ rnCallback: @escaping RCTResponseSenderBlock) {
        self.presentCallback = rnCallback
    }

    @objc
    private func exitPaymentsheet(_ reactTag: NSNumber, _ rnMessage: String, _ reset: Bool) {
        let result = paymentResult(from: rnMessage)
        withPaymentSheet(reactTag) { vc, sheet in
            sheet?.completion?(result)
            vc?.dismiss(animated: false, completion: nil)
        }
    }

    @objc
    private func exitWidgetPaymentsheet(_ reactTag: NSNumber, _ rnMessage: String, _ reset: Bool) {
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

    @objc
    private func exitPaymentMethodManagement(_ reactTag: NSNumber, _ rnMessage: String, _ reset: Bool) {
        exitSheet(rnMessage)
    }

    @objc
    private func notifyWidgetPaymentResult(_ rootTag: NSNumber, _ rnMessage: String) {
    }

    @objc
    private func onUpdateIntentEvent(_ rootTag: NSNumber, _ type: String, _ result: String) {
        withWidget(rootTag) { widget in
            widget.handleUpdateIntentEvent(type: type, result: result)
        }
    }

    @objc func emitPaymentEvent(_ rootTag: NSNumber, _ eventType: String, _ payload: NSDictionary) {
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

    @objc
    private func exitCardForm(_ rnMessage: String) {
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
                    RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(response: response, error: error)
                } else {
                    RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(
                        response: "failed",
                        error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
                    )
                }
            } catch {
                RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(
                    response: "failed",
                    error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
                )
            }
        } else {
            RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(
                response: "failed",
                error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
            )
        }
    }

    @objc
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
                    RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(response: response, error: error)
                } else {
                    RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(
                        response: "failed",
                        error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
                    )
                }
            } catch {
                RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(
                    response: "failed",
                    error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
                )
            }
        } else {
            RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(
                response: "failed",
                error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message": "An error has occurred."])
            )
        }
        DispatchQueue.main.async {
            if let view = RNViewManager.sharedInstance.rootView {
                let reactNativeVC: UIViewController? = view.reactViewController()
                reactNativeVC?.dismiss(animated: false, completion: nil)
            }
        }
    }

    @objc
    private func onPaymentConfirmButtonClick(_ rootTag: NSNumber, _ payload: String, _ callback: @escaping RCTResponseSenderBlock) {
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

    @objc
    private func openDDCWebView(_ ddcUrl: String, _ timeoutMs: NSNumber, _ callback: @escaping RCTResponseSenderBlock) {
        DispatchQueue.main.async {
            let keyWindow: UIWindow?
            if #available(iOS 13.0, *) {
                keyWindow = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow }
            } else {
                keyWindow = UIApplication.shared.windows.first { $0.isKeyWindow }
            }

            guard let window = keyWindow else {
                callback([""])
                return
            }

            let ddcDelegate = DDCWebViewDelegate(callback: callback, window: window)
            let config = WKWebViewConfiguration()

            let webView = WKWebView(frame: CGRect(x: -9999, y: -9999, width: 1, height: 1), configuration: config)
            webView.navigationDelegate = ddcDelegate
            webView.uiDelegate = ddcDelegate
            ddcDelegate.webView = webView
            window.addSubview(webView)

            guard let url = URL(string: ddcUrl) else {
                ddcDelegate.invokeCallback("")
                return
            }

            webView.load(URLRequest(url: url))

            let timeoutInterval = timeoutMs.doubleValue / 1000.0
            let workItem = DispatchWorkItem { [weak ddcDelegate] in
                ddcDelegate?.invokeCallback("")
            }
            ddcDelegate.timeoutWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + timeoutInterval, execute: workItem)
        }
    }

    private func withWidget(_ rootTag: NSNumber, _ block: @escaping (PaymentWidget) -> Void) {
        RCTGetUIManagerQueue().async {
            self.bridge.uiManager.addUIBlock { _, viewRegistry in
                guard let view = viewRegistry?[rootTag] else { return }
                var current: UIView? = view
                while let v = current {
                    if let widget = v as? PaymentWidget {
                        block(widget)
                        return
                    }
                    current = v.superview
                }
            }
        }
    }

    private func resolveSubscribingTarget(_ rootTag: NSNumber, _ block: @escaping (AnyObject?) -> Void) {
        RCTGetUIManagerQueue().async {
            self.bridge.uiManager.addUIBlock { _, viewRegistry in
                guard let view = viewRegistry?[rootTag] else {
                    DispatchQueue.main.async { block(nil) }
                    return
                }
                var current: UIView? = view
                while let v = current {
                    if v is PaymentWidget || v is CVCWidget {
                        DispatchQueue.main.async { block(v) }
                        return
                    }
                    current = v.superview
                }
                let sheet = (view.reactViewController() as? HyperUIViewController)?.paymentSheet
                DispatchQueue.main.async { block(sheet) }
            }
        }
    }

    private func withPaymentSheet(_ rootTag: NSNumber, _ block: @escaping (UIViewController?, PaymentSheet?) -> Void) {
        RCTGetUIManagerQueue().async {
            self.bridge.uiManager.addUIBlock { _, viewRegistry in
                let view = viewRegistry?[rootTag]
                let vc = view?.reactViewController() as? HyperUIViewController
                let sheet = vc?.paymentSheet
                DispatchQueue.main.async { block(vc, sheet) }
            }
        }
    }
}

private class DDCWebViewDelegate: NSObject, WKNavigationDelegate, WKUIDelegate {
    private let callback: RCTResponseSenderBlock
    private weak var window: UIWindow?
    private var strongSelf: DDCWebViewDelegate?
    private var callbackInvoked = false
    private var ddcPageLoaded = false

    var webView: WKWebView?
    var timeoutWorkItem: DispatchWorkItem?

    init(callback: @escaping RCTResponseSenderBlock, window: UIWindow) {
        self.callback = callback
        self.window = window
        super.init()
        self.strongSelf = self
    }

    func invokeCallback(_ url: String) {
        guard !callbackInvoked else { return }
        callbackInvoked = true
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.webView?.stopLoading()
            self.webView?.navigationDelegate = nil
            self.webView?.uiDelegate = nil
            self.webView?.removeFromSuperview()
            self.webView = nil
            self.strongSelf = nil
            self.callback([url])
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if !ddcPageLoaded {
            ddcPageLoaded = true
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url?.absoluteString ?? ""
        let isMainFrame = navigationAction.targetFrame?.isMainFrame == true
        let isNewWindow = navigationAction.targetFrame == nil
        guard !callbackInvoked else {
            decisionHandler(.cancel)
            return
        }
        if ddcPageLoaded && (isMainFrame || isNewWindow) {
            invokeCallback(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let url = navigationAction.request.url?.absoluteString ?? ""
        if ddcPageLoaded {
            invokeCallback(url)
        }
        return nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        invokeCallback("")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        invokeCallback("")
    }
}
