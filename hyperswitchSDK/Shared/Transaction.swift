//
//  Transaction.swift
//  hyperswitch
//
//  Created by Shivam Nan on 01/09/25.
//

import Foundation

public class Transaction {
    private var messageVersion: String
    private var directoryServerId: String?
    private var cardNetwork: String?
    private weak var authSession: AuthenticationSession?
    
    init(messageVersion: String, directoryServerId: String? = nil, cardNetwork: String? = nil) {
        self.messageVersion = messageVersion
        self.directoryServerId = directoryServerId
        self.cardNetwork = cardNetwork
    }
    
    public func getAuthenticationRequestParameters(completion: @escaping (AuthenticationRequestParameters) -> Void) {
        let props: [String: Any] = [
            "messageVersion": self.messageVersion,
            "directoryServerId": self.directoryServerId as Any,
            "cardNetwork": self.cardNetwork as Any
        ]
        
        AuthenticationSession.authParametersCompletion = completion
        
        HyperHeadless.shared?.generateAReqParamsCallback?([props])
    }
    
    public func doChallenge(
        challengeParameters: ChallengeParameters,
        challengeStatusReceiver: ChallengeStatusReceiver,
        timeOut: Int
    ) {
        let props: [String: Any] = [
            "acsSignedContent": challengeParameters.acsSignedContent,
            "acsTransactionId": challengeParameters.acsTransactionId,
            "acsRefNumber": challengeParameters.acsRefNumber,
            "threeDSServerTransId": challengeParameters.threeDSServerTransactionId,
            "threeDSRequestorAppURL": challengeParameters.threeDSRequestorAppURL
        ]
        
        AuthenticationSession.challengeStatusReceiver = challengeStatusReceiver
        
        HyperHeadless.shared?.receiveChallengeParamsCallback?([props])
    }
}

public class ChallengeParameters {
    public var threeDSServerTransactionId: String
    public var acsTransactionId: String
    public var acsRefNumber: String
    public var acsSignedContent: String
    public var threeDSRequestorAppURL: String?
    
    init(threeDSServerTransactionId: String, acsTransactionId: String, acsRefNumber: String, acsSignedContent: String, threeDSRequestorAppURL: String? = nil) {
        self.threeDSServerTransactionId = threeDSServerTransactionId
        self.acsTransactionId = acsTransactionId
        self.acsRefNumber = acsRefNumber
        self.acsSignedContent = acsSignedContent
        self.threeDSRequestorAppURL = threeDSRequestorAppURL
    }
}

public class CompletionEvent {
    public init() {}
}

public class ProtocolErrorEvent {
    private let errorMessage: String
    
    public init(errorMessage: String) {
        self.errorMessage = errorMessage
    }
    
    public func getErrorMessage() -> String {
        return errorMessage
    }
}

public class RuntimeErrorEvent {
    private let errorMessage: String
    private let errorCode: String?
    
    public init(errorMessage: String, errorCode: String? = nil) {
        self.errorMessage = errorMessage
        self.errorCode = errorCode
    }
    
    public func getErrorMessage() -> String {
        return errorMessage
    }
    
    public func getErrorCode() -> String? {
        return errorCode
    }
}

public protocol ChallengeStatusReceiver {
    func completed(_ completionEvent: CompletionEvent)
    
    func cancelled()
    
    func timedout()
    
    func protocolError(_ protocolErrorEvent: ProtocolErrorEvent)
    
    func runtimeError(_ runtimeErrorEvent: RuntimeErrorEvent)
}
