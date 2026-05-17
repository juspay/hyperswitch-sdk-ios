//
//  PaymentSheet.swift
//  Hyperswitch
//
//  Created by Balaganesh on 09/12/22.
//

import Foundation

/// PaymentSheet is a class that handles the presentation and management of a payment sheet interface.
public class PaymentSheet {

    /// The initializer method that sets up the payment sheet with the required parameters.
    internal required init(sdkAuthorization: String, configuration: Configuration) {
        self.sdkAuthorization = sdkAuthorization
        self.configuration = configuration
    }

    /// The configuration object that holds the settings for the payment sheet.
    internal let configuration: Configuration?
    internal let sdkAuthorization: String
    internal var completion: ((PaymentResult) -> Void)?
    internal var subscribedEvents: [String] = []
    internal var paymentEventListener: PaymentEventListener?
    internal var shouldProceedWithPaymentCallback: ((String, @escaping (Bool) -> Void) -> Void)?

    private var onConfirmButtonTriggered: ((String, @escaping (Bool) -> Void) -> Void)?

    public func setOnConfirmButtonTriggered(_ callback: @escaping (String, @escaping (Bool) -> Void) -> Void) {
        self.onConfirmButtonTriggered = callback
    }

    internal func notifyConfirmButtonTriggered(payload: String, callback: @escaping (Bool) -> Void) {
        if(self.onConfirmButtonTriggered == nil){
            callback(true)
        }else{
            self.onConfirmButtonTriggered?(payload, callback)
        }
    }
}
