//
//  PaymentSheet.swift
//  Hyperswitch
//
//  Created by Balaganesh on 09/12/22.
//

import Foundation

/// PaymentSheetResult is an enum that represents the possible outcomes of a payment sheet operation.
@frozen public enum PaymentSheetResult {
    case completed(data: String)
    case canceled(data: String)
    case failed(error: Error)
}

/// PaymentSheet is a class that handles the presentation and management of a payment sheet interface.
public class PaymentSheet {
    
    /// The initializer method that sets up the payment sheet with the required parameters.
    internal required init(paymentIntentClientSecret: String, configuration: Configuration) {
        self.intentClientSecret = paymentIntentClientSecret
        self.configuration = configuration
    }
    
    /// The configuration object that holds the settings for the payment sheet.
    internal let configuration: Configuration?
    internal let intentClientSecret: String
    internal var completion: ((PaymentSheetResult) -> ())?
}
