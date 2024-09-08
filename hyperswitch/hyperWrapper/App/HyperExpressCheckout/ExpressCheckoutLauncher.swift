//
//  ExpressCheckoutLauncher.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 21/02/24.
//
import Foundation
import WebKit

@frozen public enum ExpressCheckoutResult {
    case completed(data: String)
    case canceled(data: String)
    case failed(error: Error)
}

public class ExpressCheckoutLauncher {
    
    init(){}
    
    static var configuration: PaymentSheet.Configuration?
    static var intentClientSecret: String?
    static var completion: ((ExpressCheckoutResult) -> ())?
    static var themes: String?
    static var defaultView: Bool?
    
    
    public convenience init(paymentIntentClientSecret: String, configuration: PaymentSheet.Configuration, themes: String? = nil, defaultView: Bool? = nil, completion: @escaping ((ExpressCheckoutResult) -> ())) {
        
        self.init()
        
        ExpressCheckoutLauncher.configuration = configuration
        ExpressCheckoutLauncher.intentClientSecret = paymentIntentClientSecret
        ExpressCheckoutLauncher.themes = themes
        ExpressCheckoutLauncher.defaultView = defaultView
        ExpressCheckoutLauncher.completion = completion
        
        let props: [String : Any] = [
            "publishableKey": APIClient.shared.publishableKey as Any,
            "clientSecret": paymentIntentClientSecret,
            "paymentMethodType": "expressCheckout",
            "paymentMethodData": "",
            "confirm": false
        ]
//        HyperModule.shared?.confirmEC(data: props) //MARK: WIP
    }
    
    
    public func launchPaymentSheet(paymentResult: NSMutableDictionary, callBack: @escaping RCTResponseSenderBlock) {
        
        DispatchQueue.main.async {
            
            RNViewManager.sharedInstance.responseHandler = self
            
            let hyperParams = [
                "appId" : Bundle.main.bundleIdentifier,
                "sdkVersion" : "0.1.6",
                "country" : NSLocale.current.regionCode,
                "ip": nil,
                "user-agent": WKWebView().value(forKey: "userAgent"),
                "launchTime": Int(Date().timeIntervalSince1970 * 1000)
            ]
            
            let props: [String : Any] = [
                "type":"widgetPayment",
                "clientSecret": ExpressCheckoutLauncher.intentClientSecret as Any,
                "publishableKey": APIClient.shared.publishableKey as Any,
                "customBackendUrl": APIClient.shared.customBackendUrl as Any,
                "customParamas": APIClient.shared.customParams as Any
            ]
            
            let rootView =  RNViewManager.sharedInstance.viewForModule("hyperSwitch", initialProperties: ["props": props]);
            
            rootView.backgroundColor = UIColor.clear
            
            let paymentSheetViewController = UIViewController()
            paymentSheetViewController.modalPresentationStyle = .overFullScreen
            paymentSheetViewController.view = rootView
            
            RCTPresentedViewController()!.present(paymentSheetViewController, animated: false)
        }
    }
    
}

extension ExpressCheckoutLauncher: RNResponseHandler {
    func didReceiveResponse(response: String?, error: Error?) {
        
        if let completion = ExpressCheckoutLauncher.completion {
            if let error = error {
                completion(.failed(error: error))
            }
            else if (response == "cancelled"){
                completion(.canceled(data: "cancelled"))
            }
            else {
                completion(.completed(data: response ?? "failed"))
            }
        }
    }
}

extension ExpressCheckoutLauncher {
    public func confirm() {
        
        ExpressCheckoutLauncher.completion = ExpressCheckoutLauncher.completion
        RNViewManager.sharedInstance.responseHandler = self
        
        var props: [String : Any] = [
            "publishableKey": APIClient.shared.publishableKey as Any,
            "clientSecret": ExpressCheckoutLauncher.intentClientSecret as Any,
            "paymentMethodType": "expressCheckout",
            "paymentMethodData": "",
            "confirm": true
        ]
//        HyperModule.shared?.confirmEC(data: props) //MARK: WIP
    }
}
