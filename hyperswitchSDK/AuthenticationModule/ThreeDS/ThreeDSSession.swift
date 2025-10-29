//
//  ThreeDSSession.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 29/10/25.
//

public class ThreeDSSession {
    private let sessionProvider: ThreeDSSessionProvider
    
    init(sessionProvider: ThreeDSSessionProvider) {
        self.sessionProvider = sessionProvider
    }
    
    public func createTransaction(messageVersion: String, directoryServerId: String?, cardNetwork: String?) async throws -> Transaction {
        let transactionProvider = try await sessionProvider.createTransaction(
            messageVersion: messageVersion,
            directoryServerId: directoryServerId,
            cardNetwork: cardNetwork
        )
        
        return Transaction(
            messageVersion: messageVersion,
            directoryServerId: directoryServerId,
            cardNetwork: cardNetwork,
            transactionProvider: transactionProvider
        )
    }
}
