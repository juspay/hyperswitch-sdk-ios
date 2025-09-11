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
    
    internal static var shared: HyperHeadless?
    
    private var setNativeProps: RCTResponseSenderBlock?
    private var confirmWithDefault: RCTResponseSenderBlock?
    private var defaultPMData: ((NSDictionary?) -> Void)?
    
    internal var generateAReqParamsCallback: RCTResponseSenderBlock?
    internal var aReqParams: NSDictionary?
    internal var receiveChallengeParamsCallback: RCTResponseSenderBlock?
    
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
            if let data = rnMessage.data(using: .utf8) {
                do {
                    if let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        self.handleParsedResponse(responseDict)
                    }
                } catch let error as Any {
                    self.handleParsingError(error)
                }
            } else {
                let error = NSError(domain: "HyperHeadless", code: -1, userInfo: [NSLocalizedDescriptionKey: "Internal Error: Failed to parse response"])
                self.handleParsingError(error)
            }
        }
    }
    
    private func handleParsedResponse(_ responseDict: [String: Any]) {
        if let method = responseDict["method"] as? String {
            self.handleMethodBasedResponse(method: method, responseDict: responseDict)
        } else {
            // Method of unsupported format
        }
    }
    
    private func handleMethodBasedResponse(method: String, responseDict: [String: Any]) {
        let status = responseDict["status"] as? Bool ?? false
        
        switch method {
        case "initialiseSdkFunc":
            self.handleInitialiseSdk(responseDict: responseDict, status: status)
        
        case "generateChallenge":
            self.handleGenerateChallenge(responseDict: responseDict, status: status)
            
        default:
            print("-- HyperHeadless: Unknown method '\(method)'")
        }
    }
        
    private func handleInitialiseSdk(responseDict: [String: Any], status: Bool) {
        if status {
            AuthenticationSession.initialiseSdkCompletion?(AuthenticationStatus.success)
        } else {
            if let error = responseDict["error"] as? [String: Any] {
                AuthenticationSession.initialiseSdkCompletion?(AuthenticationStatus.failure(error))
            } else {
                // Method of unsupported format
            }
        }
    }

    private func handleGenerateChallenge(responseDict: [String: Any], status: Bool) {
        if let challengeReceiver = AuthenticationSession.challengeStatusReceiver {
            if status {
                if let data = responseDict["data"] as? [String: Any],
                   let doChallengeResult = data["doChallengeResult"] as? [String: Any],
                   let resultStatus = doChallengeResult["status"] as? String,
                   let message = doChallengeResult["message"] as? String {
                    self.parseAndCallReceiver(challengeReceiver, status: resultStatus, message: message)
                } else {
                    self.parseAndCallReceiver(challengeReceiver, status: "error", message: "Missing challenge result data")
                }
            } else {
                if let error = responseDict["error"] as? [String: Any],
                   let errorStatus = error["status"] as? String,
                   let errorMessage = error["message"] as? String {
                    
                    self.parseAndCallReceiver(challengeReceiver, status: errorStatus, message: errorMessage)
                } else {
                    self.parseAndCallReceiver(challengeReceiver, status: "error", message: "Unknown challenge generation error")
                }
            }
            
            AuthenticationSession.challengeStatusReceiver = nil
        }
    }
    
    private func parseAndCallReceiver(_ receiver: ChallengeStatusReceiver, status: String, message: String) {
        switch status {
        case "success":
            let completionEvent = CompletionEvent()
            receiver.completed(completionEvent)
        case "error":
            if message == "challenge cancelled by user" {
                receiver.cancelled()
            } else if message == "challenge timeout" {
                receiver.timedout()
            } else if message.contains("Protocol error") {
                let protocolError = ProtocolErrorEvent(errorMessage: message)
                receiver.protocolError(protocolError)
            } else if message.contains("Runtime error") {
                let errorCode = self.extractErrorCode(from: message)
                let runtimeError = RuntimeErrorEvent(errorMessage: message, errorCode: errorCode)
                receiver.runtimeError(runtimeError)
            } else {
                let runtimeError = RuntimeErrorEvent(errorMessage: message, errorCode: nil)
                receiver.runtimeError(runtimeError)
            }
        default:
            let runtimeError = RuntimeErrorEvent(errorMessage: "Unknown status: \(status) - \(message)", errorCode: nil)
            receiver.runtimeError(runtimeError)
        }
    }
    
    // TODO: sync the RN layer to emit challenge completion result in same format
    private func extractErrorCode(from message: String) -> String? {
        // Extract error code from runtime error message
        // Expected format: "Runtime error: <message>\nError code: <code>\n"
        let components = message.components(separatedBy: "\n")
        for component in components {
            if component.hasPrefix("Error code: ") {
                return String(component.dropFirst("Error code: ".count))
            }
        }
        return nil
    }
    
    private func handleParsingError(_ error: Any) {
        let errorResult = ["status": "error", "message": error]
        AuthenticationSession.initialiseSdkCompletion?(AuthenticationStatus.failure(errorResult))
    }
    
    /// Trigger the stored authentication parameter completion callback
    private func triggerAuthParametersCompletion() {
        guard let aReqParams = self.aReqParams,
              let completion = AuthenticationSession.authParametersCompletion else {
            return
        }
        
        if let authParams = AuthenticationRequestParameters(from: aReqParams) {
            DispatchQueue.main.async {
                completion(authParams)
            }
        } else {
            // Log error for debugging purposes
        }
        
        AuthenticationSession.authParametersCompletion = nil
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
            let threeDsSdkApiKey = AuthenticationSession.authConfiguration?.apiKey
            let props: [String: Any] = [
                "isAuthSession": true as Any,
                "clientSecret": AuthenticationSession.authIntentClientSecret as Any,
                "publishableKey": APIClient.shared.publishableKey as Any,
                "hyperParams": HyperParams.getHyperParams() as Any,
                "configuration": [
                    "netceteraSDKApiKey": threeDsSdkApiKey as Any,
                ] as Any
            ]
            rnCallback([props])
        }
    }

    @objc
    private func getAuthRequestParams(_ rnCallback: @escaping RCTResponseSenderBlock) {
        self.generateAReqParamsCallback = rnCallback
    }

    @objc
    private func sendAReqAndReceiveChallengeParams(_ rnMessage: NSDictionary, _ rnCallback: @escaping RCTResponseSenderBlock) {
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
