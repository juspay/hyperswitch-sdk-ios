//
//  NetceteraProvider.swift
//  AuthenticationSdk
//
//  Created by Shivam Nan on 02/09/25.
//

import Foundation

#if canImport(ThreeDS_SDK)
import ThreeDS_SDK

class NetceteraProvider: ThreeDSProvider {
    private let threeDS2Service: ThreeDS2Service = ThreeDS2ServiceSDK()
    
    func initialize(configuration: AuthenticationConfiguration?) throws {
        let configBuilder = ConfigurationBuilder()
        
        if let apiKey = configuration?.apiKey {
            try configBuilder.api(key: apiKey)
        }
        
        let configParams = configBuilder.configParameters()
        
        // TODO: implement netcetera configuration using AuthenticationConfiguration
        try threeDS2Service.initialize(
            configParams,
            locale: nil,
            uiCustomizationMap: nil
        )
    }
    
    func createSession() throws -> ThreeDSSessionProvider {
        return NetceteraSessionProvider(service: threeDS2Service)
    }
    
    func cleanup() {
        try? threeDS2Service.cleanup()
    }
}

class NetceteraSessionProvider: ThreeDSSessionProvider {
    private let service: ThreeDS2Service
    
    init(service: ThreeDS2Service) {
        self.service = service
    }
    
    func createTransaction(messageVersion: String, directoryServerId: String?, cardNetwork: String?) throws -> ThreeDSTransactionProvider {
        let transaction = try service.createTransaction(
            directoryServerId: directoryServerId ?? "",
            messageVersion: messageVersion
        )
        
        return NetceteraTransactionProvider(transaction: transaction)
    }
}

class NetceteraTransactionProvider: ThreeDSTransactionProvider {
    private let transaction: ThreeDS_SDK.Transaction
    
    init(transaction: ThreeDS_SDK.Transaction) {
        self.transaction = transaction
    }
    
    func getAuthenticationRequestParameters() throws -> AuthenticationRequestParameters {
        let netceteraParams = try transaction.getAuthenticationRequestParameters()
        
        return AuthenticationRequestParameters(
            sdkTransactionID: netceteraParams.getSDKTransactionId(),
            deviceData: netceteraParams.getDeviceData(),
            sdkEphemeralPublicKey: netceteraParams.getSDKEphemeralPublicKey(),
            sdkAppID: netceteraParams.getSDKAppID(),
            sdkReferenceNumber: netceteraParams.getSDKReferenceNumber(),
            messageVersion: netceteraParams.getMessageVersion()
        )
    }
    
    func doChallenge(viewController: UIViewController, challengeParameters: ChallengeParameters, challengeStatusReceiver: ChallengeStatusReceiver, timeOut: Int) throws {
        let netceteraChallengeParams = ThreeDS_SDK.ChallengeParameters(
            threeDSServerTransactionID: challengeParameters.threeDSServerTransactionID,
            acsTransactionID: challengeParameters.acsTransactionID,
            acsRefNumber: challengeParameters.acsRefNumber,
            acsSignedContent: challengeParameters.acsSignedContent
        )
        
        if let url = challengeParameters.threeDSRequestorAppURL {
            netceteraChallengeParams.setThreeDSRequestorAppURL(threeDSRequestorAppURL: url)
        }
        
        let netceteraChallengeStatusReceiver = NetceteraChallengeStatusAdapter(receiver: challengeStatusReceiver)
        
        try transaction.doChallenge(
            challengeParameters: netceteraChallengeParams,
            challengeStatusReceiver: netceteraChallengeStatusReceiver,
            timeOut: timeOut,
            inViewController: viewController
        )
    }
    
    // TODO: Implementation
    //    func getProgressView() throws -> ProgressDialog {
    //        <#code#>
    //    }
    
    func close() {
        try? transaction.close()
    }
}

// Adapter to convert Netcetera challenge status callbacks to our interface
class NetceteraChallengeStatusAdapter: NSObject, ThreeDS_SDK.ChallengeStatusReceiver {
    private let receiver: ChallengeStatusReceiver
    
    init(receiver: ChallengeStatusReceiver) {
        self.receiver = receiver
    }
    
    func completed(completionEvent: ThreeDS_SDK.CompletionEvent) {
        let ourEvent = CompletionEvent()
        receiver.completed(ourEvent)
    }
    
    func cancelled() {
        receiver.cancelled()
    }
    
    func timedout() {
        receiver.timedout()
    }
    
    func protocolError(protocolErrorEvent: ThreeDS_SDK.ProtocolErrorEvent) {
        let ourEvent = ProtocolErrorEvent(errorMessage: protocolErrorEvent.getErrorMessage().getErrorDescription())
        receiver.protocolError(ourEvent)
    }
    
    func runtimeError(runtimeErrorEvent: ThreeDS_SDK.RuntimeErrorEvent) {
        let ourEvent = RuntimeErrorEvent(
            errorMessage: runtimeErrorEvent.getErrorMessage(),
            errorCode: runtimeErrorEvent.getErrorCode()
        )
        receiver.runtimeError(ourEvent)
    }
}

#endif
