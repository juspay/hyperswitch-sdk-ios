//
//  TridentProvider.swift
//  AuthenticationSdk
//
//  Created by Shivam Nan on 02/09/25.
//

import Foundation
import HyperswitchAuthentication
internal import Trident
import UIKit

// Trident declares types of the same names; unqualified, these are HyperswitchAuthentication's.
typealias AuthenticationRequestParameters = HyperswitchAuthentication.AuthenticationRequestParameters
typealias ChallengeParameters = HyperswitchAuthentication.ChallengeParameters
typealias ChallengeStatusReceiver = HyperswitchAuthentication.ChallengeStatusReceiver
typealias CompletionEvent = HyperswitchAuthentication.CompletionEvent
typealias ProtocolErrorEvent = HyperswitchAuthentication.ProtocolErrorEvent
typealias RuntimeErrorEvent = HyperswitchAuthentication.RuntimeErrorEvent
typealias Transaction = HyperswitchAuthentication.Transaction

/// How HyperswitchAuthentication finds this provider when the app links the
/// HyperswitchAuthenticationTrident3DS product.
@objc(HyperswitchTridentThreeDSProvider)
final class TridentProviderEntry: NSObject, ThreeDSProviderEntry {
    static func makeProvider() -> ThreeDSProvider {
        TridentProvider()
    }
}

//class Logger: TridentLoggerDelegate {
//    public func trackEvent(withLevel level: String, label: String, value: [String : Any], category: String, subcategory: String) {
//        print("## Trident Event: \(label) \(value) \(category) \(subcategory)")
//    }
//}

class TridentProvider: ThreeDSProvider {
    private lazy var tridentSdk: Trident.TridentSDK = TridentSDK()

    func initialize(configuration: AuthenticationConfiguration?) async throws {
        // TODO: Implement configuration for trident
        try tridentSdk.initialize(
            configParameters: ConfigParameters(),
            locale: nil,
            uiCustomization: UICustomization(),
            certificateDelegate: nil
        )
    }

    func createSession() throws -> ThreeDSSessionProvider {
        return TridentSessionProvider(service: tridentSdk)
    }

    func cleanup() {
    }
}

class TridentSessionProvider: ThreeDSSessionProvider {
    private let service: Trident.TridentSDK

    init(service: Trident.TridentSDK) {
        self.service = service
    }

    func createTransaction(
        messageVersion: String,
        directoryServerId: String?,
        cardNetwork: String?
    ) async throws -> ThreeDSTransactionProvider {
        let _directoryServerId = try service.getDirectoryServerId(cardNetwork: cardNetwork?.uppercased(with: .autoupdatingCurrent) ?? "")

        let transaction = try service.createTransaction(
            directoryServerId: _directoryServerId,
            messageVersion: messageVersion
        )
        return TridentTransactionProvider(transaction: transaction)
    }
}

class TridentTransactionProvider: ThreeDSTransactionProvider {
    private let transaction: Trident.Transaction

    init(transaction: Trident.Transaction) {
        self.transaction = transaction
    }

    func getAuthenticationRequestParameters() async throws -> AuthenticationRequestParameters {
        let aReqParams = try transaction.getAuthenticationRequestParameters()

        return AuthenticationRequestParameters(
            sdkTransactionID: aReqParams.sdkTransactionID,
            deviceData: aReqParams.deviceData,
            sdkEphemeralPublicKey: aReqParams.sdkEphemeralPublicKey,
            sdkAppID: aReqParams.sdkAppID,
            sdkReferenceNumber: aReqParams.sdkReferenceNumber,
            messageVersion: aReqParams.messageVersion,
            sdkEncryptedData: nil
        )
    }

    func doChallenge(
        viewController: UIViewController,
        challengeParameters: ChallengeParameters,
        challengeStatusReceiver: ChallengeStatusReceiver,
        timeOut: Int
    ) throws {
        let tridentChallengeParams = Trident.ChallengeParameters()

        tridentChallengeParams.threeDSServerTransactionID = challengeParameters.threeDSServerTransactionID
        tridentChallengeParams.acsTransactionID = challengeParameters.acsTransactionID
        tridentChallengeParams.acsRefNumber = challengeParameters.acsRefNumber
        tridentChallengeParams.acsSignedContent = challengeParameters.acsSignedContent

        if let url = challengeParameters.threeDSRequestorAppURL {
            tridentChallengeParams.threeDSRequestorAppURL = url
        }

        let tridentChallengeStatusReceiver = TridentChallengeStatusAdapter(receiver: challengeStatusReceiver)

        try transaction.doChallenge(
            viewController: viewController,
            challengeParameters: tridentChallengeParams,
            challengeStatusReceiver: tridentChallengeStatusReceiver,
            timeOut: timeOut
        )
    }

    // TODO: Implementation
    //    func getProgressView() throws -> ProgressDialog {
    //        <#code#>
    //    }

    func close() {
        transaction.close()
    }
}

// Adapter to convert Trident challenge status callbacks to our interface
class TridentChallengeStatusAdapter: Trident.ChallengeStatusReceiver {
    private let receiver: ChallengeStatusReceiver

    init(receiver: ChallengeStatusReceiver) {
        self.receiver = receiver
    }

    func completed(_ completionEvent: Trident.CompletionEvent) {
        let ourEvent = CompletionEvent()
        receiver.completed(ourEvent)
    }

    func cancelled() {
        receiver.cancelled()
    }

    func timedout() {
        receiver.timedout()
    }

    func protocolError(_ protocolErrorEvent: Trident.ProtocolErrorEvent) {
        let ourEvent = ProtocolErrorEvent(errorMessage: protocolErrorEvent.getErrorMessage().getErrorDescription())
        receiver.protocolError(ourEvent)
    }

    func runtimeError(_ runtimeErrorEvent: Trident.RuntimeErrorEvent) {
        let ourEvent = RuntimeErrorEvent(
            errorMessage: runtimeErrorEvent.getErrorMessage(),
            errorCode: runtimeErrorEvent.getErrorCode()
        )
        receiver.runtimeError(ourEvent)
    }
}
