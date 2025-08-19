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
    
    // Completion handler for AReq params response
    internal static var aReqParamsCompletion: ((String?, Error?) -> Void)?
    
    // Completion handler for receiveChallengeParams response
    internal static var receiveChallengeParamsCompletion: ((String?, Error?) -> Void)?
    
    // Completion handler for doChallenge response
    internal static var doChallengeCompletion: ((String?, Error?) -> Void)?
    
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
        return ["test", "init3ds", "generateAReqParams", "receiveChallengeParams", "doChallenge"]
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
                        // Check if this is an AReq params response
                        if let aReqParams = responseDict["aReqParams"] as? [String: Any] {
                            // Call the completion handler with the AReq params response
                            print("-- aReqParams response: ", aReqParams)
                            HyperHeadless.aReqParamsCompletion?(rnMessage, nil)
                        } else if let challengeResult = responseDict["challengeResult"] as? [String: Any] {
                            // Call the completion handler with the receiveChallengeParams response
                            print("-- receiveChallengeParams response: ", challengeResult)
                            HyperHeadless.receiveChallengeParamsCompletion?(rnMessage, nil)
                        } else if let doChallengeResult = responseDict["doChallengeResult"] as? [String: Any] {
                            // Call the completion handler with the doChallenge response
                            print("-- doChallenge response: ", doChallengeResult)
                            HyperHeadless.doChallengeCompletion?(rnMessage, nil)
                        } else {
                            // Handle other types of responses if needed
                            print("-- Received message from ReScript: \(rnMessage)")
                        }
                    }
                } catch {
                    // Call completion handler with error
                    HyperHeadless.aReqParamsCompletion?(nil, error)
                    HyperHeadless.receiveChallengeParamsCompletion?(nil, error)
                    HyperHeadless.doChallengeCompletion?(nil, error)
                }
            } else {
                let error = NSError(domain: "HyperHeadless", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse message"])
                HyperHeadless.aReqParamsCompletion?(nil, error)
                HyperHeadless.receiveChallengeParamsCompletion?(nil, error)
                HyperHeadless.doChallengeCompletion?(nil, error)
            }
        }
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
            let props: [String: Any] = [
                "clientSecret": PaymentSession.authSession?.authIntentClientSecret as Any,
                "publishableKey": APIClient.shared.publishableKey as Any,
            ]
            rnCallback([props])
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
    
    @objc
    private func initThreeDs(_ threeDsData: NSDictionary) {
        self.sendEvent(withName: "init3ds", body: threeDsData)
    }
    
    // Public method to emit init3ds event from other parts of the app
    internal func emitInit3DsEvent(threeDsSdkApiKey: String?, environment: String?) {
        let threeDsData: [String: Any] = [
            "paymentMethodData": [
                "threeDsSdkApiKey": threeDsSdkApiKey ?? "",
                "environment": environment ?? "sandbox"
            ].compactMapValues { $0 }
        ]
        
        DispatchQueue.main.async {
            self.sendEvent(withName: "init3ds", body: threeDsData)
        }
    }
    
    @objc
    private func generateAReqParams(_ aReqData: NSDictionary) {
        self.sendEvent(withName: "generateAReqParams", body: aReqData)
    }
    
    // Public method to emit generateAReqParams event from other parts of the app
    internal func emitGenerateAReqParamsEvent(messageVersion: String?, directoryServerId: String?, cardNetwork: String?) {
        let aReqData: [String: Any] = [
            "messageVersion": messageVersion ?? "",
            "directoryServerId": directoryServerId ?? "",
            "cardNetwork": cardNetwork as Any
        ]
        
        DispatchQueue.main.async {
            self.sendEvent(withName: "generateAReqParams", body: aReqData)
        }
    }
    
    // Public method to request AReq params with completion handler
    public func requestAReqParams(
        messageVersion: String? = nil,
        directoryServerId: String? = nil,
        cardNetwork: String? = nil,
        completion: @escaping (String?, Error?) -> Void
    ) {
        // Store the completion handler
        HyperHeadless.aReqParamsCompletion = completion
        
        // Emit the event to trigger AReq params generation
        emitGenerateAReqParamsEvent(
            messageVersion: messageVersion,
            directoryServerId: directoryServerId,
            cardNetwork: cardNetwork
        )
    }
    
    @objc
    private func receiveChallengeParams(_ challengeData: NSDictionary) {
        self.sendEvent(withName: "receiveChallengeParams", body: challengeData)
    }
    
    // Public method to emit receiveChallengeParams event from other parts of the app
    internal func emitReceiveChallengeParamsEvent(
        acsSignedContent: String?,
        acsTransactionId: String?,
        acsRefNumber: String?,
        threeDSServerTransId: String?,
        threeDSRequestorAppURL: String?
    ) {
        let challengeData: [String: Any] = [
            "acsSignedContent": acsSignedContent ?? "",
            "acsTransactionId": acsTransactionId ?? "",
            "acsRefNumber": acsRefNumber ?? "",
            "threeDSServerTransId": threeDSServerTransId ?? "",
            "threeDSRequestorAppURL": threeDSRequestorAppURL ?? ""
        ]
        
        DispatchQueue.main.async {
            self.sendEvent(withName: "receiveChallengeParams", body: challengeData)
        }
    }
    
    // Public method to request receiveChallengeParams with completion handler
    public func requestReceiveChallengeParams(
        acsSignedContent: String? = nil,
        acsTransactionId: String? = nil,
        acsRefNumber: String? = nil,
        threeDSServerTransId: String? = nil,
        threeDSRequestorAppURL: String? = nil,
        completion: @escaping (String?, Error?) -> Void
    ) {
        // Store the completion handler
        HyperHeadless.receiveChallengeParamsCompletion = completion
        
        // Emit the event to trigger receiveChallengeParams
        emitReceiveChallengeParamsEvent(
            acsSignedContent: acsSignedContent,
            acsTransactionId: acsTransactionId,
            acsRefNumber: acsRefNumber,
            threeDSServerTransId: threeDSServerTransId,
            threeDSRequestorAppURL: threeDSRequestorAppURL
        )
    }
    
    @objc
    private func doChallenge(_ challengeData: NSDictionary) {
        self.sendEvent(withName: "doChallenge", body: challengeData)
    }
    
    // Public method to emit doChallenge event from other parts of the app
    internal func emitDoChallengeEvent() {
        let challengeData: [String: Any] = [
            "action": "doChallenge"
        ]
        
        DispatchQueue.main.async {
            self.sendEvent(withName: "doChallenge", body: challengeData)
        }
    }
    
    // Public method to request doChallenge with completion handler
    public func requestDoChallenge(
        completion: @escaping (String?, Error?) -> Void
    ) {
        // Store the completion handler
        HyperHeadless.doChallengeCompletion = completion
        
        // Emit the event to trigger doChallenge
        emitDoChallengeEvent()
    }
}
