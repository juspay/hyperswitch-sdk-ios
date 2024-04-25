//
//  HyperModule.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 07/03/24.
//

import Foundation
import React

@objc(HyperModule)
class HyperModule: RCTEventEmitter {
    
    let applePayPaymentHandler = ApplePayHandler()
    let expressCheckoutHandler = ExpressCheckoutLauncher()
    public static var shared:HyperModule?
    var paymentSheetViewController:UIViewController?
    
    override init() {
        super.init()
        HyperModule.shared = self
    }
    
    @objc
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    @objc override func supportedEvents() -> [String] {
        return ["confirm", "confirmEC"]
    }
    
    @objc func confirm(data: [String: Any]) {
        self.sendEvent(withName: "confirm", body: data)
    }
    // MARK: WIP
    //    @objc func confirmEC(data: [String: Any]) {
    //        self.sendEvent(withName: "confirmEC", body: data)
    //    }
    
    @objc
    func sendMessageToNative(_ rnMessage: String) {}
    
    //React Native Wrapper Function
    @objc
    func presentPaymentSheet(_ request: NSMutableDictionary, _ callBack: @escaping RCTResponseSenderBlock) -> Void {
        DispatchQueue.main.async {
            let paymentSheet = PaymentSheet(paymentIntentClientSecret: "", configuration: PaymentSheet.Configuration())
            paymentSheet.presentWithParams(
                from: (UIApplication.shared.delegate?.window??.rootViewController)!,
                props: request as! [String : Any],
                completion: { result2 in
                    switch result2 {
                    case .completed(let data):
                        callBack([["status": "completed", "message": data]])
                    case .failed(let error as NSError):
                        callBack([["status": "failed", "code": error.domain, "message": "Payment failed: \(error.userInfo["message"] ?? "Failed")"]])
                    case .canceled(let data):
                        callBack([["status": "cancelled", "message": data]])
                    }
                }
            )
        }
    }
    
    @objc
    func launchWidgetPaymentSheet(_ request: NSMutableDictionary, _ callback: @escaping RCTResponseSenderBlock) -> Void {
        expressCheckoutHandler.launchPaymentSheet(paymentResult: request,callBack: callback)
    }
    
    @objc
    func launchApplePay (_ rnMessage: String, _ rnCallback: @escaping RCTResponseSenderBlock) {
        applePayPaymentHandler.startPayment(rnMessage: rnMessage, rnCallback: rnCallback)
    }
    
    @objc
    func exitPaymentsheet(_ reactTag: NSNumber, _ rnMessage: String, _ reset: Bool) {
        exitSheet(rnMessage)
    }
    
    @objc
    func exitWidgetPaymentsheet(_ reactTag: NSNumber, _ rnMessage: String, _ reset: Bool) {
        exitSheet(rnMessage)
    }
    
    @objc
    func exitCardForm(_ rnMessage: String) {
        var response: String?
        var error: NSError?
        
        if let data = rnMessage.data(using: .utf8) {
            do {
                if let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                    let status = jsonDictionary["status"]
                    
                    if (status == "failed" || status == "requires_payment_method") {
                        error = NSError(domain: (jsonDictionary["code"] ?? "") != "" ? jsonDictionary["code"]! : "UNKNOWN_ERROR", code: 0, userInfo: ["message" : jsonDictionary["message"] ?? "An error has occurred."])
                    } else {
                        response = status
                    }
                    RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(response: response, error: error)
                } else {
                    RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(response: "failed", error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message" : "An error has occurred."]))
                }
            } catch {
                RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(response: "failed", error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message" : "An error has occurred."]))
            }
        } else {
            RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(response: "failed", error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message" : "An error has occurred."]))
        }
    }
    
    
    func exitSheet(_ rnMessage: String) {
        var response: String?
        var error: NSError?
        
        if let data = rnMessage.data(using: .utf8) {
            do {
                if let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                    let status = jsonDictionary["status"]
                    
                    if (status == "failed" || status == "requires_payment_method") {
                        error = NSError(domain: (jsonDictionary["code"] ?? "") != "" ? jsonDictionary["code"]! : "UNKNOWN_ERROR", code: 0, userInfo: ["message" : jsonDictionary["message"] ?? "An error has occurred."])
                    } else {
                        response = status
                    }
                    RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(response: response, error: error)
                } else {
                    RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(response: "failed", error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message" : "An error has occurred."]))
                }
            } catch {
                RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(response: "failed", error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message" : "An error has occurred."]))
            }
        } else {
            RNViewManager.sharedInstance.responseHandler?.didReceiveResponse(response: "failed", error: NSError(domain: "UNKNOWN_ERROR", code: 0, userInfo: ["message" : "An error has occurred."]))
        }
        DispatchQueue.main.async {
            if let view = RNViewManager.sharedInstance.rootView {
                let reactNativeVC: UIViewController? = view.reactViewController()
                reactNativeVC?.dismiss(animated: false, completion: nil)
            }
        }
    }
}

