//
//  AuthenticationSession.swift
//  hyperswitch
//
//  Created by Shivam Nan on 18/08/25.
//

import Foundation

public class AuthenticationSession {
    internal static var authIntentClientSecret: String?
    internal static var authConfiguration: AuthenticationConfiguration?
    
    internal static var initialiseSdkCompletion: ((AuthenticationStatus) -> Void)?
    internal static var authParametersCompletion: ((AuthenticationRequestParameters) -> Void)?
    internal static var challengeStatusReceiver: ChallengeStatusReceiver?
    
    public init(publishableKey: String, customBackendUrl: String? = nil, customParams: [String : Any]? = nil, customLogUrl: String? = nil) {
        APIClient.shared.publishableKey = publishableKey
        APIClient.shared.customBackendUrl = customBackendUrl
        APIClient.shared.customLogUrl = customLogUrl
        APIClient.shared.customParams = customParams
        
#if canImport(HyperOTA)
        OTAServices.shared.initialize(publishableKey: publishableKey)
        LogManager.initialize(publishableKey: publishableKey)
#endif
        
        RNHeadlessManager.sharedInstance.reinvalidateBridge()
        let _ = RNHeadlessManager.sharedInstance.viewForModule("dummy", initialProperties: [:])
    }
    
    public func initThreeDsSession(authIntentClientSecret: String, configuration: AuthenticationConfiguration? = nil, completion: @escaping ((AuthenticationStatus) -> Void)) {
        AuthenticationSession.initialiseSdkCompletion = completion
        
        AuthenticationSession.authIntentClientSecret = authIntentClientSecret
        AuthenticationSession.authConfiguration = configuration
    }
    
    public func createTransaction(messageVersion: String, directoryServerId: String?, cardNetwork: String?) -> Transaction {
        return Transaction(messageVersion: messageVersion, directoryServerId: directoryServerId, cardNetwork: cardNetwork)
    }
}

public struct AuthenticationConfiguration {
    public let apiKey: String?
    public let environment: ThreeDSEnvironment?
    public let uiCustomization: AuthenticationSession.UICustomization?
    
    public init(apiKey: String? = nil) {
        self.apiKey = apiKey
        self.environment = ThreeDSEnvironment.sandbox
        self.uiCustomization = nil
    }
}

public enum ThreeDSEnvironment {
    case sandbox
    case production
}

public enum AuthenticationStatus {
    case success
    case failure([String: Any])
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
