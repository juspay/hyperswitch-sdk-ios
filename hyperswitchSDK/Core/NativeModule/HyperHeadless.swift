//
//  HyperHeadless.swift
//  Hyperswitch
//
//  Created by Shivam Shashank on 06/03/24.
//

import Foundation
import WebKit
import React


@objc(HyperHeadless)
internal class HyperHeadless: RCTEventEmitter {
    
    internal static var shared:HyperHeadless?
    
    private var setNativeProps: RCTResponseSenderBlock?
    private var confirmWithDefault: RCTResponseSenderBlock?
    private var defaultPMData: ((NSDictionary?) -> Void)?
    
    internal override init() {
        super.init()
        HyperHeadless.shared = self
    }
    
    @objc
    internal override static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    @objc 
    internal override func supportedEvents() -> [String] {
        return ["test"]
    }
    
    @objc 
    private func confirm(data: [String: Any]) {
        self.sendEvent(withName: "test", body: data)
    }
    
    @objc
    private func sendMessageToNative(_ rnMessage: String) {}
    
    @objc
    private func initialisePaymentSession (_ rnCallback: @escaping RCTResponseSenderBlock) {
        DispatchQueue.main.async {
            if PaymentSession.headlessCompletion != nil, !PaymentSession.isPresented {
                let hyperParams = HyperParams.getHyperParams()
                
                let props: [String: Any] = [
                    "clientSecret": PaymentSession.paymentIntentClientSecret as Any,
                    "publishableKey": APIClient.shared.publishableKey as Any,
                    "hyperParams": hyperParams,
                    "customBackendUrl": APIClient.shared.customBackendUrl as Any,
                    "customLogUrl": APIClient.shared.customLogUrl as Any,
                    "customParams": APIClient.shared.customParams as Any
                ]
                rnCallback([props])
            }
        }
    }
    
    @objc
    private func getPaymentSession(_ rnMessage: NSDictionary, _ rnMessage2: NSDictionary, _ rnMessage3: NSArray, _ rnCallback: @escaping RCTResponseSenderBlock) {
        PaymentSession.getPaymentSession(getPaymentMethodData: rnMessage, getPaymentMethodData2: rnMessage2, getPaymentMethodDataArray: rnMessage3, callback: rnCallback)
    }
    
    @objc
    private func exitHeadless(_ rnMessage: String) {
        PaymentSession.exitHeadless(rnMessage: rnMessage)
    }
    
}
