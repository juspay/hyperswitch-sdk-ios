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


            let userContentController = WKUserContentController()
            let interceptScript = WKUserScript(
                source: """
                (function() {
                    var nativePostMessage = function(msg) {
                        var str = (typeof msg === 'string') ? msg : JSON.stringify(msg);
                        window.webkit.messageHandlers.ddcPostMessage.postMessage(str);
                    };
                    var orig = window.postMessage.bind(window);
                    window.postMessage = function(msg) {
                        nativePostMessage(msg);
                        orig(msg, '*');
                    };
                    if (window.parent && window.parent !== window) {
                        window.parent.postMessage = nativePostMessage;
                    }
                })();
                """,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
            userContentController.addUserScript(interceptScript)

            let ddcDelegate = DDCWebViewDelegate(callback: callback, window: window, userContentController: userContentController)
            userContentController.add(ddcDelegate, name: "ddcPostMessage")

            let config = WKWebViewConfiguration()
            config.userContentController = userContentController

            let webView = WKWebView(frame: CGRect(x: -9999, y: -9999, width: 1, height: 1), configuration: config)
            webView.navigationDelegate = ddcDelegate
            webView.uiDelegate = ddcDelegate
            ddcDelegate.webView = webView
            window.addSubview(webView)

            guard let url = URL(string: ddcUrl) else {
                ("[HyperDDC] openDDCWebView: invalid URL, aborting")
                ddcDelegate.invokeCallback("")
                return
            }

            webView.load(URLRequest(url: url))

            let timeoutInterval = timeoutMs.doubleValue / 1000.0
            let workItem = DispatchWorkItem { [weak ddcDelegate] in
                ("[HyperDDC] DDC timed out after %d ms", timeoutMs.intValue)
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

private class DDCWebViewDelegate: NSObject, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
    private let callback: RCTResponseSenderBlock
    private weak var window: UIWindow?
    // Strong reference to userContentController so it (and our message handler
    // registration) is not released when WKWebViewConfiguration is copied by WKWebView.
    private var userContentController: WKUserContentController?
    // Self-retain: keeps this delegate alive while the WKWebView's weak
    // navigationDelegate reference is the only external pointer to us.
    private var strongSelf: DDCWebViewDelegate?
    private var callbackInvoked = false
    private var ddcPageLoaded = false

    var webView: WKWebView?
    var timeoutWorkItem: DispatchWorkItem?

    init(callback: @escaping RCTResponseSenderBlock, window: UIWindow, userContentController: WKUserContentController) {
        self.callback = callback
        self.window = window
        self.userContentController = userContentController
        super.init()
        self.strongSelf = self  // prevent premature deallocation
    }

    func invokeCallback(_ url: String) {
        guard !callbackInvoked else {
            ("[HyperDDC] invokeCallback: already invoked, ignoring url=%@", url)
            return
        }
        callbackInvoked = true
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        if url.isEmpty {
            ("[HyperDDC] invokeCallback: empty url — DDC timed out or failed")
        } else {
            ("[HyperDDC] invokeCallback: redirectUrl=%@", url)
        }
        DispatchQueue.main.async { [weak self] in
            // guard let creates a local strong reference for the duration of this
            // block, so callback([url]) is safe even after strongSelf is released.
            guard let self = self else { return }
            self.webView?.stopLoading()
            self.webView?.navigationDelegate = nil
            self.webView?.uiDelegate = nil
            self.userContentController?.removeAllUserScripts()
            self.userContentController = nil
            self.webView?.removeFromSuperview()
            self.webView = nil
            self.strongSelf = nil  // release self-retain; local strong ref keeps us alive
            self.callback([url])
        }
    }

    // WKScriptMessageHandler — postMessage fallback
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let body = message.body as? String ?? ""
        ("[HyperDDC] postMessage received: %@", body)
        guard !callbackInvoked,
              let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let nextAction = json["next_action"] as? [String: Any],
              nextAction["type"] as? String == "redirect_to_url",
              let redirectUrl = nextAction["url"] as? String else {
            ("[HyperDDC] postMessage: no redirect_to_url action or already invoked, ignoring")
            return
        }
        ("[HyperDDC] postMessage: intercepting redirect_to_url=%@", redirectUrl)
        invokeCallback(redirectUrl)
    }

    // WKNavigationDelegate — mark the DDC page as started loading so subsequent
    // navigations (the stepUp redirect) can be intercepted in decidePolicyFor.
    // Using didStartProvisionalNavigation instead of didFinish ensures we catch
    // HTTP-redirect responses that arrive before the page fully loads.
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        ("[HyperDDC] didStartProvisionalNavigation: url=%@ ddcPageLoaded=%d", webView.url?.absoluteString ?? "nil", ddcPageLoaded ? 1 : 0)
        if !ddcPageLoaded {
            ddcPageLoaded = true
        }
    }

    // WKNavigationDelegate — primary interception: capture redirect after DDC completes.
    // Handles both same-frame navigation (targetFrame.isMainFrame == true) and
    // navigations where targetFrame is nil (e.g. anchor with target="_blank").
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

    // WKUIDelegate — intercept window.open() navigations after DDC completes.
    // On iOS, window.open() bypasses decidePolicyFor entirely and comes here instead.
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let url = navigationAction.request.url?.absoluteString ?? ""
        if ddcPageLoaded {
            invokeCallback(url)
        }
        return nil  // never create a visible new WebView
    }

    // WKNavigationDelegate — handle page load failures
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        invokeCallback("")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        invokeCallback("")
    }
}
