//
//  HyperswitchChallengeManager.swift
//  HyperswitchNetcetera3ds
//
//  Created by Shivam Nan on 14/05/24.
//

import Foundation
import ThreeDS_SDK


class HyperswitchChallengeManager: ChallengeStatusReceiver {
    var postChallengeCallback: RCTResponseSenderBlock?
    var map: [String: Any] = [:]
    
    func setPostHSChallengeCallback(_ callback: @escaping RCTResponseSenderBlock) {
        self.postChallengeCallback = callback
    }
    
    func completed(completionEvent: CompletionEvent) {
        // Handle successful or unsuccessful completion of challenge flow
        map["status"] = "success";
        map["message"] = "challenge completed successfully";
        postChallengeCallback?([map]);
    }
    
    func cancelled() {
        // Handle challenge canceled by the user
        map["status"] = "error";
        map["message"] = "challenge cancelled by user";
        postChallengeCallback?([map]);
    }
    
    func timedout() {
        // Handle challenge timeout
        map["status"] = "error";
        map["message"] = "challenge timeout";
        postChallengeCallback?([map]);
    }
    
    func protocolError(protocolErrorEvent: ProtocolErrorEvent) {
        // Handle protocol error that has been send by the ACS
        var message: String = "";
        let errorMessage = protocolErrorEvent.getErrorMessage()
        
        if !errorMessage.getErrorDescription().isEmpty {
            message.append("Description: \(errorMessage.getErrorDescription())\n")
        }
        
        if !errorMessage.getErrorCode().isEmpty {
            message.append("Error code: \(errorMessage.getErrorCode())\n")
        }
        
        if let errorDetails = errorMessage.getErrorDetail(), !errorDetails.isEmpty {
            message.append("Details: \(errorDetails)\n")
        }
        
        if !errorMessage.getErrorComponent().isEmpty {
            message.append("Component: \(errorMessage.getErrorComponent())\n")
        }
        
        if !errorMessage.getErrorMessageType().isEmpty {
            message.append("Error message type: \(errorMessage.getErrorMessageType())\n")
        }
        
        if !errorMessage.getMessageVersionNumber().isEmpty {
            message.append("Version number: \(errorMessage.getMessageVersionNumber())\n")
        }
        
        map["status"] = "error";
        map["message"] = message;
        postChallengeCallback?([map]);
    }
    
    func runtimeError(runtimeErrorEvent: RuntimeErrorEvent) {
        // Handle error that has occurred in the SDK at runtime
        var message: String = "";
        message.append("Description: \(runtimeErrorEvent.getErrorMessage())\n")
        
        if let errorCode = runtimeErrorEvent.getErrorCode() {
            message.append("Error code: \(errorCode)\n")
        }
        
        map["status"] = "error";
        map["message"] = message;
        postChallengeCallback?([map]);
    }
}


