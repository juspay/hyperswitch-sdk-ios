//
//  Transaction.swift
//  AuthenticationSdk
//
//  Created by Shivam Nan on 01/09/25.
//

import Foundation
import UIKit

public final class Transaction {
    private let messageVersion: String
    private let directoryServerId: String?
    private let cardNetwork: String?
    private let transactionProvider: ThreeDSTransactionProvider
    
    init(messageVersion: String, directoryServerId: String? = nil, cardNetwork: String? = nil, transactionProvider: ThreeDSTransactionProvider) {
        self.messageVersion = messageVersion
        self.directoryServerId = directoryServerId
        self.cardNetwork = cardNetwork
        self.transactionProvider = transactionProvider
    }
    
    public func getAuthenticationRequestParameters() async throws -> AuthenticationRequestParameters {
        return try await transactionProvider.getAuthenticationRequestParameters()
    }
    
    public func doChallenge(
        viewController: UIViewController,
        challengeParameters: ChallengeParameters,
        challengeStatusReceiver: ChallengeStatusReceiver,
        timeOut: Int
    ) throws {
        try transactionProvider.doChallenge(
            viewController: viewController,
            challengeParameters: challengeParameters,
            challengeStatusReceiver: challengeStatusReceiver,
            timeOut: timeOut
        )
    }
    
    public func getProgressView() throws -> ProgressDialog {
        // Return a default ProgressDialog since getProgressView is not available in the provider protocol
        // TODO: implementation
        return ProgressDialog()
    }
    
    public func close() {
        transactionProvider.close()
    }
}

public class ProgressDialog {
    public func start() {}
    public func stop() {}
}

public class AuthenticationRequestParameters {
    final public let sdkTransactionID: String?
    final public let deviceData: String?
    final public let sdkEphemeralPublicKey: String?
    final public let sdkAppID: String?
    final public let sdkReferenceNumber: String?
    final public let messageVersion: String?
    
    init(
        sdkTransactionID: String?,
        deviceData: String?,
        sdkEphemeralPublicKey: String?,
        sdkAppID: String?,
        sdkReferenceNumber: String?,
        messageVersion: String?
    ) {
        self.deviceData = deviceData
        self.sdkTransactionID = sdkTransactionID
        self.sdkEphemeralPublicKey = sdkEphemeralPublicKey
        self.sdkAppID = sdkAppID
        self.sdkReferenceNumber = sdkReferenceNumber
        self.messageVersion = messageVersion
    }
}

public class ChallengeParameters {
    public let threeDSServerTransactionID: String
    public let acsTransactionID: String
    public let acsRefNumber: String
    public let acsSignedContent: String
    public let threeDSRequestorAppURL: String?
    
    public init(threeDSServerTransactionID: String, acsTransactionID: String, acsRefNumber: String, acsSignedContent: String, threeDSRequestorAppURL: String? = nil) {
        self.threeDSServerTransactionID = threeDSServerTransactionID
        self.acsTransactionID = acsTransactionID
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
