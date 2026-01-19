//
//  CardinalProvider.swift
//  hyperswitch
//
//  Created by Shivam Nan on 20/10/25.
//

import Foundation

#if canImport(CardinalMobile)
import CardinalMobile

class CardinalProvider: ThreeDSProvider {
    private var cardinalService: CardinalServiceProtocol?
    private var cardinalConfig: CardinalSessionConfiguration?

    func initialize(configuration: AuthenticationConfiguration?) async throws {
        self.cardinalService = CardinalService()
        self.cardinalConfig = CardinalSessionConfiguration()

        let _env: CardinalSessionEnvironment = switch configuration?.environment {
        case .production:
                .production
        case .sandbox:
                .staging
        default:
                .staging
        }

        self.cardinalConfig?.deploymentEnvironment = _env
        self.cardinalConfig?.sdkMaxTimeout = 10
        self.cardinalConfig?.cardinalDatacenter = Cardinal

        guard let cardinalService = self.cardinalService,
              let cardinalConfig = self.cardinalConfig,
              let configuration = configuration,
              let jwtToken = configuration.apiKey else {
            let errorMessage: String
            if self.cardinalService == nil {
                errorMessage = "Cardinal service is not found"
            } else {
                errorMessage = "Required jwt token is missing, add under apiKey in AuthenticationConfiguration"
            }
            throw AuthenticationError.providerInitializationFailed(errorMessage, nil)
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            cardinalService.jwtInitialize(jwtString: jwtToken, configParameters: cardinalConfig) { sdkTransactionId in
                continuation.resume()
            } error: { error in
                let errorDesc = error?.errorDescription ?? "Unknown error"
                let errorCode = error?.errorCode ?? "Unknown error-code"
                let authError = AuthenticationError.providerInitializationFailed(
                    "Cardinal JWT initialization failed: \(errorCode) \(errorDesc)",
                    nil
                )
                continuation.resume(throwing: authError)
            }
        }

        /**
         Visa recommends after you complete the initialize() call getWarnings() on cardinal session to get a list of all the Warnings detected by the SDK. For more information go to Security Guidance for iOS
         */
        // TODO: let warnings = cardinalService.getWarnings()
    }

    func createSession() throws -> ThreeDSSessionProvider {
        if let cardinalService = self.cardinalService {
            return CardinalSessionProvider(service: cardinalService)
        } else {
            throw AuthenticationError.sessionNotInitialized("No session available")
        }
    }

    func cleanup() {
        if let cardinalService = self.cardinalService {
            cardinalService.cleanup();
        }
    }
}

class CardinalSessionProvider: ThreeDSSessionProvider {
    private let cardinalService: CardinalServiceProtocol

    init(service: CardinalServiceProtocol) {
        self.cardinalService = service
    }

    func createTransaction(messageVersion: String, directoryServerId: String?, cardNetwork: String?) async throws -> any ThreeDSTransactionProvider {
        guard let cardNetwork = cardNetwork else {
            throw TransactionError.transactionCreationFailed("missing card network, card network is required for Cardinal transactions", nil)
        }

        return CardinalTransactionProvider(service: cardinalService, messageVersion: messageVersion, cardNetwork: cardNetwork)
    }
}

class CardinalTransactionProvider: ThreeDSTransactionProvider {
    private let cardinalService: CardinalServiceProtocol
    private let messageVersion: String
    private let cardNetwork: String

    init(service: CardinalServiceProtocol, messageVersion: String, cardNetwork: String) {
        self.cardinalService = service
        self.messageVersion = messageVersion
        self.cardNetwork = cardNetwork
    }

    func getAuthenticationRequestParameters() async throws -> AuthenticationRequestParameters {
        var error: CardinalError?
        let cardinalEncryptedData = self.cardinalService.getAuthentication(cardBrand: self.cardNetwork, messageVersion: self.messageVersion, error: &error)

        if let error = error {
            throw TransactionError.authReqParamGenerationFailed("\(error.errorCode) \(error.errorDescription)", nil)
        } else {
            return AuthenticationRequestParameters(
                sdkTransactionID: nil,
                deviceData: cardinalEncryptedData,
                sdkEphemeralPublicKey: nil,
                sdkAppID: nil,
                sdkReferenceNumber: nil,
                messageVersion: nil
            )
        }
    }

    func doChallenge(viewController: UIViewController, challengeParameters: ChallengeParameters, challengeStatusReceiver: any ChallengeStatusReceiver, timeOut: Int) throws {
        let cardinalChallengeParams = CardinalChallengeParameters()

        cardinalChallengeParams.threeDSServerTransactionId = challengeParameters.threeDSServerTransactionID
        cardinalChallengeParams.acsTransactionId = challengeParameters.acsTransactionID
        cardinalChallengeParams.acsReferenceNumber = challengeParameters.acsRefNumber
        cardinalChallengeParams.acsSignedContent = challengeParameters.acsSignedContent
        if let threeDSRequestorAppURL = challengeParameters.threeDSRequestorAppURL {
            cardinalChallengeParams.threeDSRequestorAppURL = threeDSRequestorAppURL
        }

        let cardinalChallengeTimeout: Int32 = 10
        var cardinalError: CardinalError? = nil
        let cardinalChallengeStatusReceiver = CardinalChallengeStatusAdapter(receiver: challengeStatusReceiver)

        cardinalService.doChallengewithChallengeParameters(
            challengeParameters: cardinalChallengeParams,
            challengeStatusReceiver: cardinalChallengeStatusReceiver,
            timeOut: cardinalChallengeTimeout,
            error: &cardinalError
        )


        if let error = cardinalError {
            throw TransactionError.challengeFailed("Cardinal doChallenge failed with error: \(error.errorCode) \(error.errorDescription)", nil)
        }
    }

    func close() {
        cardinalService.cleanup();
    }
}


// Adapter to convert Cardinal challenge status callbacks to our interface
class CardinalChallengeStatusAdapter: NSObject, CardinalMobile.ChallengeStatusReceiver {
    private let receiver: ChallengeStatusReceiver

    init(receiver: ChallengeStatusReceiver) {
        self.receiver = receiver
    }

    func completed(_ completionEvent: CardinalMobile.CompletionEvent) {
        let ourEvent = CompletionEvent()
        receiver.completed(ourEvent)
    }

    func cancelled() {
        receiver.cancelled()
    }

    func timedout() {
        receiver.timedout()
    }

    func protocolError(_ protocolErrorEvent: CardinalMobile.ProtocolErrorEvent) {
        let ourEvent = ProtocolErrorEvent(errorMessage: protocolErrorEvent.getErrorMessage().getErrorDescription())
        receiver.protocolError(ourEvent)
    }

    func runtimeError(_ runtimeErrorEvent: CardinalMobile.RuntimeErrorEvent) {
        let ourEvent = RuntimeErrorEvent(
            errorMessage: runtimeErrorEvent.getErrorMessage(),
            errorCode: runtimeErrorEvent.getErrorCode()
        )
        receiver.runtimeError(ourEvent)
    }
}


#endif
