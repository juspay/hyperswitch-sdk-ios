//
//  AuthenticationError.swift
//  AuthenticationSdk
//
//  Created by Shivam Nan on 02/09/25.
//

import Foundation

public enum TransactionError: Error, LocalizedError {
    case transactionCreationFailed(String, Error?)
    case challengeFailed(String, Error?)
    
    public var errorDescription: String? {
        switch self {
        case .transactionCreationFailed(let message, let underlyingError):
            return "Transaction Creation Failed: \(message). \(String(describing: underlyingError))"
        case .challengeFailed(let message, let underlyingError):
            return "Challenge Failed: \(message). \(String(describing: underlyingError))"
        }
    }
}

public enum AuthenticationError: Error, LocalizedError {
    case noProviderAvailable(String)
    case preferredProviderUnavailable(String)
    case sessionNotInitialized(String)
    case providerInitializationFailed(String, Error?)
    case transactionCreationFailed(String, Error?)
    case challengeFailed(String, Error?)
    
    public var errorDescription: String? {
        switch self {
        case .noProviderAvailable(let message):
            return "No 3DS Provider Available: \(message)"
        case .preferredProviderUnavailable(let message):
            return "Preferred Provider Unavailable: \(message)"
        case .sessionNotInitialized(let message):
            return "Session Not Initialized: \(message)"
        case .providerInitializationFailed(let message, let underlyingError):
            return "Provider Initialization Failed: \(message). Underlying error: \(underlyingError?.localizedDescription ?? "Unknown")"
        case .transactionCreationFailed(let message, let underlyingError):
            return "Transaction Creation Failed: \(message). Underlying error: \(underlyingError?.localizedDescription ?? "Unknown")"
        case .challengeFailed(let message, let underlyingError):
            return "Challenge Failed: \(message). Underlying error: \(underlyingError?.localizedDescription ?? "Unknown")"
        }
    }
}
