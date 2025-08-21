//
//  HyperHeadless.swift
//  Hyperswitch
//
//  Created by Shivam Shashank on 06/03/24.
//

import Foundation
import React
import WebKit


@objc(HyperHeadless)
internal class HyperHeadless: RCTEventEmitter {
    
    internal static var shared:HyperHeadless?
    
    private var setNativeProps: RCTResponseSenderBlock?
    private var confirmWithDefault: RCTResponseSenderBlock?
    private var defaultPMData: ((NSDictionary?) -> Void)?
    
    // Completion handler for doChallenge response
    internal static var doChallengeCompletion: ((String?, Error?) -> Void)?
    
    // Storage for authentication parameter completion callback
    internal var authParametersCompletion: ((AuthenticationRequestParameters) -> Void)?
    
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
    private func sendMessageToNative(_ rnMessage: String) {
        DispatchQueue.main.async {
            // Parse the JSON response from ReScript side
            if let data = rnMessage.data(using: .utf8) {
                do {
                    if let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        if let doChallengeResult = responseDict["doChallengeResult"] as? [String: Any] {
                            HyperHeadless.doChallengeCompletion?(rnMessage, nil)
                        } else if let errorResponse = responseDict["error"] as? [String: Any] {
                            print("-- errorResponse: ", errorResponse)
                        }
                    }
                } catch {
                    HyperHeadless.doChallengeCompletion?(nil, error)
                }
            } else {
                let error = NSError(domain: "HyperHeadless", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse message"])
                HyperHeadless.doChallengeCompletion?(nil, error)
            }
        }
    }
    
    // MARK: - Authentication Parameters Completion Handling
    
    /// Trigger the stored authentication parameter completion callback
    private func triggerAuthParametersCompletion() {
        guard let aReqParams = self.aReqParams,
              let completion = self.authParametersCompletion else {
            return
        }
        
        // Try to create AuthenticationRequestParameters from the stored aReqParams
        if let authParams = AuthenticationRequestParameters(from: aReqParams) {
            // Success - trigger the completion with the parameters on main queue
            DispatchQueue.main.async {
                completion(authParams)
            }
        } else {
            // Log error for debugging purposes
            print("HyperHeadless: Failed to parse aReqParams into AuthenticationRequestParameters")
        }
        
        // Always clear the completion after attempting to call it to prevent memory leaks
        self.authParametersCompletion = nil
    }
    
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
    private func initialiseAuthSession (_ rnCallback: @escaping RCTResponseSenderBlock) {
        DispatchQueue.main.async {
            let apiKey = PaymentSession.authSession?.authConfiguration?.apiKey
            let props: [String: Any] = [
                "isAuthSession": true as Any,
                "clientSecret": PaymentSession.authSession?.authIntentClientSecret as Any,
                "publishableKey": APIClient.shared.publishableKey as Any,
                "hyperParams": HyperParams.getHyperParams() as Any,
                "configuration": [
                    "netceteraSDKApiKey": apiKey as Any,
                ] as Any
            ]
            rnCallback([props])
        }
    }

    internal var generateAReqParamsCallback: RCTResponseSenderBlock?

    @objc
    private func getMessageVersion(_ rnCallback: @escaping RCTResponseSenderBlock) {
        self.generateAReqParamsCallback = rnCallback
    }

    internal var aReqParams: NSDictionary?
    internal var receiveChallengeParamsCallback: RCTResponseSenderBlock?

    @objc
    private func getChallengeParams(_ rnMessage: NSDictionary, _ rnCallback: @escaping RCTResponseSenderBlock) {
        self.aReqParams = rnMessage["aReqParams"] as? NSDictionary
        
        self.receiveChallengeParamsCallback = rnCallback
        
        // Trigger the stored authentication parameter completion callback
        triggerAuthParametersCompletion()
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
