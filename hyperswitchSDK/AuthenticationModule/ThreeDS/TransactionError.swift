//
//  TransactionError.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 30/10/25.
//

import Foundation

public enum TransactionError: Error, LocalizedError {
    case authReqParamGenerationFailed(String, Error?)
    case transactionCreationFailed(String, Error?)
    case challengeFailed(String, Error?)

    public var errorDescription: String? {
        switch self {
        case .authReqParamGenerationFailed(let message, let underlyingError):
            return "AReqParams Collection Failed: \(message). \(String(describing: underlyingError))"
        case .transactionCreationFailed(let message, let underlyingError):
            return "Transaction Creation Failed: \(message). \(String(describing: underlyingError))"
        case .challengeFailed(let message, let underlyingError):
            return "Challenge Failed: \(message). \(String(describing: underlyingError))"
        }
    }
}
