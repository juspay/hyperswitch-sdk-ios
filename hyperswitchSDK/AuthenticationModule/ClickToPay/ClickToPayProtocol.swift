//
//  ClickToPayProtocol.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 08/12/25.
//

import Foundation

// MARK: - Public Protocol

/// Public protocol defining the Click to Pay session interface
public protocol ClickToPaySession {
    /// Check if a customer has an existing Click to Pay profile
    func isCustomerPresent(request: CustomerPresenceRequest) async throws -> CustomerPresenceResponse

    /// Get the user type and card status
    func getUserType() async throws -> CardsStatusResponse

    /// Get list of recognized cards for the user
    func getRecognizedCards() async throws -> [RecognizedCard]

    /// Validate customer authentication with OTP
    func validateCustomerAuthentication(otpValue: String) async throws -> [RecognizedCard]

    /// Sign out of Click to Pay Session
    func signOut() async throws -> SignOutResponse

    /// Checkout with a selected card
    func checkoutWithCard(request: CheckoutRequest) async throws -> CheckoutResponse

    /// Close the Click to Pay session and release all resources.
    /// This method should be called when the session is no longer needed.
    /// After calling close(), the session cannot be used again.
    func close() async
}
