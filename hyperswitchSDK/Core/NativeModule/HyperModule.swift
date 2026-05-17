//
//  HyperModule.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 07/03/24.
//

import Foundation
import React

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

    //React Native Wrapper Function
    @objc
    private func presentPaymentSheet(_ request: NSMutableDictionary, _ callBack: @escaping RCTResponseSenderBlock) {
        DispatchQueue.main.async {
            let paymentSheet = PaymentSheet(sdkAuthorization: "", configuration: PaymentSheet.Configuration())
            paymentSheet.presentWithParams(
                from: (UIApplication.shared.delegate?.window??.rootViewController)!,  //TODO: safely check this
                props: request as! [String: Any],
                completion: { result2 in
                    switch result2 {
                    case .completed(let data):
                        callBack([["status": "completed", "message": data]])
                    case .failed(let error as NSError):
                        callBack([
                            [
                                "status": "failed", "code": error.domain,
                                "message": "Payment failed: \(error.userInfo["message"] ?? "Failed")",
                            ]
                        ])
                    case .canceled(let data):
                        callBack([["status": "cancelled", "message": data]])
                    }
                }
            )
        }
    }

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
    private func onPaymentConfirmButtonClick(_ rootTag: NSNumber, _ payload: String, _ callback: @escaping RCTResponseSenderBlock) {
        resolveSubscribingTarget(rootTag) { target in
            if let widget = target as? PaymentWidget {
                widget.notifyConfirmButtonTriggered(payload: payload) { shouldProceed in
                    callback([shouldProceed])
                }
            } else if let sheet = target as? PaymentSheet {
                sheet.notifyConfirmButtonTriggered(payload: payload) { shouldProceed in
                    callback([shouldProceed])
                }
            } else {
                callback([true])
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
