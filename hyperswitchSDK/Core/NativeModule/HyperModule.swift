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
    internal static var shared:HyperModule?
    
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
        return ["confirm", "confirmEC"]
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
    private func presentPaymentSheet(_ request: NSMutableDictionary, _ callBack: @escaping RCTResponseSenderBlock) -> Void {
        DispatchQueue.main.async {
            let paymentSheet = PaymentSheet(paymentIntentClientSecret: "", configuration: PaymentSheet.Configuration())
            paymentSheet.presentWithParams(
                from: (UIApplication.shared.delegate?.window??.rootViewController)!, //TODO: safely check this
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
    private func launchWidgetPaymentSheet(_ request: NSMutableDictionary, _ callback: @escaping RCTResponseSenderBlock) -> Void {
        expressCheckoutHandler.launchPaymentSheet(paymentResult: request,callBack: callback)
    }
    
    @objc
    private func onAddPaymentMethod(_ rnMessage: String) -> Void {
        PaymentMethodManagementWidget.onAddPaymentMethod?()
    }
    
    @objc
    private func launchApplePay (_ rnMessage: String, _ rnCallback: @escaping RCTResponseSenderBlock) {
        applePayPaymentHandler.startPayment(rnMessage: rnMessage, rnCallback: rnCallback, presentCallback: self.presentCallback)
    }
    
    @objc
    private func startApplePay (_ rnMessage: String, _ rnCallback: @escaping RCTResponseSenderBlock) {
        rnCallback([])
    }
    
    @objc
    private func presentApplePay (_ rnMessage: String, _ rnCallback: @escaping RCTResponseSenderBlock) {
        self.presentCallback = rnCallback
    }
    
    @objc
    private func exitPaymentsheet(_ reactTag: NSNumber, _ rnMessage: String, _ reset: Bool) {
        exitSheet(rnMessage)
    }
    
    @objc
    private func exitWidgetPaymentsheet(_ reactTag: NSNumber, _ rnMessage: String, _ reset: Bool) {
        exitSheet(rnMessage)
    }
    
    @objc
    private func exitPaymentMethodManagement(_ reactTag: NSNumber, _ rnMessage: String, _ reset: Bool) {
        exitSheet(rnMessage)
    }
    
    @objc
    private func exitCardForm(_ rnMessage: String) {
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
    
    @objc(getInstalledUpiApps:resolver:rejecter:)
    private func getInstalledUpiApps(_ knownAppsJson: String,
    resolver resolve: @escaping RCTPromiseResolveBlock,
     rejecter reject: @escaping RCTPromiseRejectBlock) {
        
        var installedApps: [[String: String]] = []
        
        print("[UPI] Received JSON:", knownAppsJson)
        
        guard let jsonData = knownAppsJson.data(using: .utf8),
              let knownApps = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: String]] else {
            print("[UPI] Failed to parse JSON")
            resolve(installedApps)
            return
        }
        
        print("[UPI] Successfully parsed \(knownApps.count) apps")
        
        for app in knownApps {
            guard let appName = app["appName"],
                  let urlScheme = app["urlScheme"] else {
                print("[UPI] Skipping app - missing appName or urlScheme")
                continue
            }
            
            // Ensure the URL scheme is properly formatted
            // If it already contains "://", use it as is, otherwise append "://"
            let formattedScheme: String
            if urlScheme.contains("://") {
                formattedScheme = urlScheme
            } else {
                formattedScheme = "\(urlScheme)://"
            }
            
            guard let url = URL(string: formattedScheme) else {
                print("[UPI] Invalid URL for \(appName): \(formattedScheme)")
                continue
            }
            
            print("[UPI] Checking \(appName) with URL: \(url)")
            
            if UIApplication.shared.canOpenURL(url) {
                print("[UPI] ✓ Found installed app: \(appName)")
                installedApps.append([
//                    "packageName": "",
                    "appName": appName
                ])
            } else {
                print("[UPI] ✗ App not installed: \(appName)")
            }
        }
         
        print("[UPI] Total installed apps found: \(installedApps.count)")
        resolve(installedApps)
    }
    
    @objc(openUpiApp:upiUri:resolver:rejecter:)
    private func openUpiApp(_ packageName: String?, _ upiUri: String, _ resolve: @escaping RCTPromiseResolveBlock, _ reject: @escaping RCTPromiseRejectBlock) {
//        print("[UPI] Opening UPI app with URI: \(upiUri)")
//        if let pkg = packageName {
//            print("[UPI] Package name (ignored on iOS): \(pkg)")
//        }
        
        guard let url = URL(string: upiUri) else {
            print("[UPI] Invalid URI: \(upiUri)")
            reject("INVALID_URI", "The provided UPI URI is invalid", nil)
            return
        }
        
        print("[UPI] Opening URL: \(url)")
        UIApplication.shared.open(url, options: [:]) { success in
            print("[UPI] Open result: \(success)")
            resolve(success)
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

