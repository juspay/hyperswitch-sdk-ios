//
//  AuthenticationSession.swift
//  hyperswitch
//
//  Created by Shivam Nan on 18/08/25.
//

import Foundation

public struct AuthenticationConfiguration {
    public let apiKey: String?
    
    public init(apiKey: String? = nil) {
        self.apiKey = apiKey
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
    final public let sdkEphemeralPublicKey: Any
    final public let sdkAppID: String
    final public let sdkReferenceNumber: String
    final public let messageVersion: String
    
    public init(sdkTransactionID: String, deviceData: String, sdkEphemeralPublicKey: Any, sdkAppID: String, sdkReferenceNumber: String, messageVersion: String) {
        self.sdkTransactionID = sdkTransactionID
        self.deviceData = deviceData
        self.sdkEphemeralPublicKey = sdkEphemeralPublicKey
        self.sdkAppID = sdkAppID
        self.sdkReferenceNumber = sdkReferenceNumber
        self.messageVersion = messageVersion
    }
    
    /// Convenience initializer to create AuthenticationRequestParameters from NSDictionary
    convenience init?(from dictionary: NSDictionary) {
        guard let sdkTransactionID = dictionary["sdkTransId"] as? String,
              let deviceData = dictionary["deviceData"] as? String,
              let sdkEphemeralPublicKey = dictionary["sdkEphemeralKey"],
              let sdkAppID = dictionary["sdkAppId"] as? String,
              let sdkReferenceNumber = dictionary["sdkReferenceNo"] as? String,
              let messageVersion = dictionary["messageVersion"] as? String else {
            return nil
        }
        
        self.init(
            sdkTransactionID: sdkTransactionID,
            deviceData: deviceData,
            sdkEphemeralPublicKey: sdkEphemeralPublicKey,
            sdkAppID: sdkAppID,
            sdkReferenceNumber: sdkReferenceNumber,
            messageVersion: messageVersion
        )
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
        let props: [String: Any] = [
            "messageVersion": self.messageVersion,
            "directoryServerId": self.directoryServerId as Any,
            "cardNetwork": self.cardNetwork as Any
        ]
        
        // Store the completion callback in HyperHeadless for automatic invocation when aReqParams are available
        HyperHeadless.shared?.authParametersCompletion = completion
        
        // Trigger the native parameter generation
        HyperHeadless.shared?.generateAReqParamsCallback?([props])
    }
    
    public func doChallenge(
        challengeParameters: ChallengeParameters,
        challengeStatusReceiver: ChallengeStatusReceiver,
        timeOut: Int
    ) {
        let props: [String: Any] = [
            "acsSignedContent": challengeParameters.acsSignedContent,
            "acsTransactionId": challengeParameters.acsTransactionID,
            "acsRefNumber": challengeParameters.acsRefNumber,
            "threeDSServerTransId": challengeParameters.threeDSServerTransactionID,
            "threeDSRequestorAppURL": challengeParameters.threeDSRequestorAppURL
        ]
        
        HyperHeadless.shared?.receiveChallengeParamsCallback?([props])
    }
}
