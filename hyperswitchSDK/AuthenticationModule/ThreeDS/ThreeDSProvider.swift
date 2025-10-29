//
//  ThreeDSProvider.swift
//  AuthenticationSdk
//
//  Created by Shivam Nan on 02/09/25.
//

import Foundation
import UIKit

public protocol ThreeDSProvider {
    func initialize(configuration: AuthenticationConfiguration?) async throws
    func createSession() throws -> ThreeDSSessionProvider
    func cleanup()
}

public protocol ThreeDSSessionProvider {
    func createTransaction(messageVersion: String, directoryServerId: String?, cardNetwork: String?) async throws -> ThreeDSTransactionProvider
}

public protocol ThreeDSTransactionProvider {
    func getAuthenticationRequestParameters() async throws -> AuthenticationRequestParameters
    func doChallenge(
        viewController: UIViewController,
        challengeParameters: ChallengeParameters,
        challengeStatusReceiver: ChallengeStatusReceiver,
        timeOut: Int) throws
    // TODO: Implementation
    //    func getProgressView() throws -> ProgressDialog
    func close()
}
