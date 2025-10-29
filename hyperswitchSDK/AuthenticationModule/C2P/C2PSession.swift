//
//  C2PSession.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 30/10/25.
//

public class ClickToPaySession {
    private let request3DSAuthentication: Bool

    init(request3DSAuthentication: Bool) {
        self.request3DSAuthentication = request3DSAuthentication
    }

    func isCustomerPresent(email: String) async throws -> Bool {
        return false
    }

    func getUserType() async throws -> ClickToPayUserStatus {
        return .recognizedCardsPresent
    }

}

public enum ClickToPayUserStatus: String, CaseIterable {
    case recognizedCardsPresent
    case triggeredCustomerAuthentication
    case noCardsPresent
}
