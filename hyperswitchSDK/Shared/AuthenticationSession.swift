//
//  AuthenticationSession.swift
//  hyperswitch
//
//  Created by Shivam Nan on 18/08/25.
//

import Foundation

public struct AuthenticationConfiguration {
    public let apiKey: String?
    public let environment: String?
    
    public init(apiKey: String? = nil, environment: String? = "sandbox") {
        self.apiKey = apiKey
        self.environment = environment
    }
}

public class AuthenticationSession {
    internal var authIntentClientSecret: String
    internal var authConfiguration: AuthenticationConfiguration?
    
    internal init(authIntentClientSecret: String, authConfiguration: AuthenticationConfiguration? = nil) {
        self.authIntentClientSecret = authIntentClientSecret
        self.authConfiguration = authConfiguration
    }
    
    public func createTransaction(messageVersion: String, directoryServerId: String?, cardNetwork: String?) -> Transaction{
        return Transaction(messageVersion: messageVersion, directoryServerId: directoryServerId, cardNetwork: cardNetwork)
    }
}

public class AuthenticationRequestParameters {
    final public let sdkTransactionID: String
    final public let deviceData: String
    final public let sdkEphemeralPublicKey: String
    final public let sdkAppID: String
    final public let sdkReferenceNumber: String
    final public let messageVersion: String
    
    public init(sdkTransactionID: String, deviceData: String, sdkEphemeralPublicKey: String, sdkAppID: String, sdkReferenceNumber: String, messageVersion: String) {
        self.sdkTransactionID = sdkTransactionID
        self.deviceData = deviceData
        self.sdkEphemeralPublicKey = sdkEphemeralPublicKey
        self.sdkAppID = sdkAppID
        self.sdkReferenceNumber = sdkReferenceNumber
        self.messageVersion = messageVersion
    }
}


public class ChallengeParameters {
    public var threeDSServerTransactionID: String
    public var acsTransactionID: String
    public var acsRefNumber: String
    public var acsSignedContent: String
    public var threeDSRequestorAppURL: String
    
    init(threeDSServerTransactionID: String, acsTransactionID: String, acsRefNumber: String, acsSignedContent: String, threeDSRequestorAppURL: String) {
        self.threeDSServerTransactionID = threeDSServerTransactionID
        self.acsTransactionID = acsTransactionID
        self.acsRefNumber = acsRefNumber
        self.acsSignedContent = acsSignedContent
        self.threeDSRequestorAppURL = threeDSRequestorAppURL
    }
}


public protocol ChallengeStatusReceiver {
    // TODO: add (_ completionEvent: CompletionEvent)
    func completed()
    
    func cancelled()
    
    func timedout()
    // TODO: add (_ protocolErrorEvent: ProtocolErrorEvent)
    func protocolError()
    
    // TODO: add (_ runtimeErrorEvent: RuntimeErrorEvent)
    func runtimeError()
}


public class Transaction {
    private var messageVersion: String
    private var directoryServerId: String?
    private var cardNetwork: String?
    private weak var authSession: AuthenticationSession?
    
    public init(messageVersion: String, directoryServerId: String? = nil, cardNetwork: String? = nil) {
        self.messageVersion = messageVersion
        self.directoryServerId = directoryServerId
        self.cardNetwork = cardNetwork
    }
    
    internal init(messageVersion: String, directoryServerId: String? = nil, authSession: AuthenticationSession) {
        self.messageVersion = messageVersion
        self.directoryServerId = directoryServerId
        self.authSession = authSession
    }
    
    public func getAuthenticationRequestParameters(completion: @escaping (AuthenticationRequestParameters) -> Void) {
        // Request AReq params with completion handler
        HyperHeadless.shared?.requestAReqParams(
            messageVersion: messageVersion,
            directoryServerId: directoryServerId,
            cardNetwork: cardNetwork
        ) { [weak self] (response: String?, error: Error?) in
            
            if let error = error {
                print("Error getting AReq params: \(error.localizedDescription)")
                // Return default parameters with messageVersion
                let defaultParams = AuthenticationRequestParameters(
                    sdkTransactionID: "",
                    deviceData: "",
                    sdkEphemeralPublicKey: "",
                    sdkAppID: "",
                    sdkReferenceNumber: "",
                    messageVersion: self?.messageVersion ?? ""
                )
                completion(defaultParams)
                return
            }
            
            guard let response = response,
                  let data = response.data(using: String.Encoding.utf8),
                  let responseDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let aReqParamsDict = responseDict["aReqParams"] as? [String: Any] else {
                print("Failed to parse AReq params response")
                let defaultParams = AuthenticationRequestParameters(
                    sdkTransactionID: "",
                    deviceData: "",
                    sdkEphemeralPublicKey: "",
                    sdkAppID: "",
                    sdkReferenceNumber: "",
                    messageVersion: self?.messageVersion ?? ""
                )
                completion(defaultParams)
                return
            }
            
            // Extract parameters from the response
            let sdkTransactionID = aReqParamsDict["sdkTransId"] as? String ?? ""
            let deviceData = aReqParamsDict["deviceData"] as? String ?? ""
            let sdkAppID = aReqParamsDict["sdkAppId"] as? String ?? ""
            let sdkReferenceNumber = aReqParamsDict["sdkReferenceNo"] as? String ?? ""
            let messageVersion = aReqParamsDict["messageVersion"] as? String ?? self?.messageVersion ?? ""
            
            // Convert sdkEphemeralKey to JSON string
            var sdkEphemeralPublicKey = ""
            if let ephemeralKey = aReqParamsDict["sdkEphemeralKey"] {
                // Check if ephemeralKey is already a string
                if let keyString = ephemeralKey as? String {
                    sdkEphemeralPublicKey = keyString
                } else if JSONSerialization.isValidJSONObject(ephemeralKey) {
                    // Only serialize if it's a valid JSON object
                    if let ephemeralKeyData = try? JSONSerialization.data(withJSONObject: ephemeralKey, options: []),
                       let ephemeralKeyString = String(data: ephemeralKeyData, encoding: .utf8) {
                        sdkEphemeralPublicKey = ephemeralKeyString
                    }
                } else {
                    // If it's not a valid JSON object, convert to string representation
                    sdkEphemeralPublicKey = String(describing: ephemeralKey)
                }
            }
            
            // Create the authentication request parameters
            let authParams = AuthenticationRequestParameters(
                sdkTransactionID: sdkTransactionID,
                deviceData: deviceData,
                sdkEphemeralPublicKey: sdkEphemeralPublicKey,
                sdkAppID: sdkAppID,
                sdkReferenceNumber: sdkReferenceNumber,
                messageVersion: messageVersion
            )
            
            completion(authParams)
        }
    }
    
    public func doChallenge(
        challengeParameters: ChallengeParameters,
        challengeStatusReceiver: ChallengeStatusReceiver,
        timeOut: Int
    ) {
        // Step 1: Send challenge parameters to the ReScript side
        HyperHeadless.shared?.requestReceiveChallengeParams(
            acsSignedContent: challengeParameters.acsSignedContent,
            acsTransactionId: challengeParameters.acsTransactionID,
            acsRefNumber: challengeParameters.acsRefNumber,
            threeDSServerTransId: challengeParameters.threeDSServerTransactionID,
            threeDSRequestorAppURL: challengeParameters.threeDSRequestorAppURL.isEmpty ? nil : challengeParameters.threeDSRequestorAppURL
        ) { [weak self] (response: String?, error: Error?) in
            
            if let error = error {
                print("Error in receiveChallengeParams: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    challengeStatusReceiver.runtimeError()
                }
                return
            }
            
            guard let response = response,
                  let data = response.data(using: String.Encoding.utf8),
                  let responseDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                print("Failed to parse receiveChallengeParams response")
                DispatchQueue.main.async {
                    challengeStatusReceiver.protocolError()
                }
                return
            }
            
            // Check the status of receiveChallengeParams
            let status = responseDict["status"] as? String ?? "failed"
            if status != "success" {
                print("receiveChallengeParams failed with status: \(status)")
                DispatchQueue.main.async {
                    challengeStatusReceiver.protocolError()
                }
                return
            }
            
            // Step 2: If receiveChallengeParams was successful, proceed with doChallenge
            self?.performDoChallenge(challengeStatusReceiver: challengeStatusReceiver)
        }
    }
    
    private func performDoChallenge(challengeStatusReceiver: ChallengeStatusReceiver) {
        HyperHeadless.shared?.requestDoChallenge { (response: String?, error: Error?) in
            
            if let error = error {
                print("Error in doChallenge: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    challengeStatusReceiver.runtimeError()
                }
                return
            }
            
            guard let response = response,
                  let data = response.data(using: String.Encoding.utf8),
                  let responseDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                print("Failed to parse doChallenge response")
                DispatchQueue.main.async {
                    challengeStatusReceiver.protocolError()
                }
                return
            }
            
            // Parse the challenge result
            let status = responseDict["status"] as? String ?? "failed"
            let message = responseDict["message"] as? String ?? ""
            
            DispatchQueue.main.async {
                switch status.lowercased() {
                case "success", "completed":
                    challengeStatusReceiver.completed()
                case "cancelled", "canceled":
                    challengeStatusReceiver.cancelled()
                case "timeout", "timedout":
                    challengeStatusReceiver.timedout()
                case "protocol_error", "protocolerror":
                    challengeStatusReceiver.protocolError()
                default:
                    print("Unknown challenge status: \(status), message: \(message)")
                    challengeStatusReceiver.runtimeError()
                }
            }
        }
    }
}
