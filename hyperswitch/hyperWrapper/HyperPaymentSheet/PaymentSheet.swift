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
    
    /// The configuration object that holds the settings for the payment sheet.
    public let configuration: Configuration?
    
    /// The initializer method that sets up the payment sheet with the required parameters.
    public required init(paymentIntentClientSecret: String, configuration: Configuration, themes: String? = nil, defaultView: Bool? = nil) {
        self.intentClientSecret = paymentIntentClientSecret
        self.configuration = configuration
        self.themes = themes
        self.defaultView = defaultView
    }
    
    let intentClientSecret: String
    var completion: ((PaymentSheetResult) -> ())?
    
    let themes: String?
    let defaultView: Bool?
}

/// An extension that conforms to the RNResponseHandler protocol, which handles the response from the payment sheet operation.
extension PaymentSheet: RNResponseHandler {
    func didReceiveResponse(response: String?, error: Error?) {
        if let completion = completion {
            if let error = error {
                completion(.failed(error: error))
            }
            else if (response == "cancelled"){
                completion(.canceled(data: "cancelled"))
            }
            else {
                completion(.completed(data: response ?? "failed"))
            }
        }
    }
}

