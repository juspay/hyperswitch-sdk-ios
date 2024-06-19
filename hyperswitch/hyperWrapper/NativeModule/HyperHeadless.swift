//
//  HyperHeadless.swift
//  Hyperswitch
//
//  Created by Shivam Shashank on 06/03/24.
//

import Foundation
import React


@objc(HyperHeadless)
class HyperHeadless: RCTEventEmitter {
    
    public static var shared:HyperHeadless?
    
    public var setNativeProps: RCTResponseSenderBlock?
    public var confirmWithDefault: RCTResponseSenderBlock?
    public var defaultPMData: ((NSDictionary?) -> Void)?
    
    override init() {
        super.init()
        HyperHeadless.shared = self
    }
    
    @objc
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    @objc override func supportedEvents() -> [String] {
        return ["test"]
    }
    
    @objc func confirm(data: [String: Any]) {
        self.sendEvent(withName: "test", body: data)
    }
    
    @objc
    func sendMessageToNative(_ rnMessage: String) {}
    
    @objc
    func initialisePaymentSession (_ rnCallback: @escaping RCTResponseSenderBlock) {
        DispatchQueue.main.async {
            if PaymentSession.shared?.completion != nil {
                let hyperParams = [
                    "appId": Bundle.main.bundleIdentifier,
                    "ip": nil,
                    "user-agent": WKWebView().value(forKey: "userAgent"),
                    "launchTime": Int(Date().timeIntervalSince1970 * 1000)
                ]
                
                let props: [String: Any] = [
                    "clientSecret": PaymentSession.clientSecret as Any,
                    "publishableKey": APIClient.shared.publishableKey as Any,
                    "hyperParams": hyperParams,
                    "customBackendUrl": APIClient.shared.customBackendUrl as Any,
                ]
                rnCallback([props])
            }
        }
    }
    
    @objc
    func getPaymentSession(_ rnMessage: NSDictionary, _ rnMessage2: NSDictionary, _ rnMessage3: NSArray, _ rnCallback: @escaping RCTResponseSenderBlock) {
        PaymentSession.shared?.getPaymentSession(getPaymentMethodData: rnMessage, getPaymentMethodData2: rnMessage2, getPaymentMethodDataArray: rnMessage3, callback: rnCallback)
    }
    
    @objc
    func exitHeadless(_ rnMessage: String) {
        PaymentSession.shared?.exitHeadless(rnMessage: rnMessage)
    }
    
}
