//
//  PaymentSheet+Events.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 07/05/26.
//

import Foundation

extension PaymentSheet {
    internal func dispatchPaymentEvent(type: String, payload: [String: Any]) {
        guard let listener = paymentEventListener else { return }
        let event = PaymentEvent(type: type, payload: payload)
        if Thread.isMainThread {
            listener.onPaymentEvent(event)
        } else {
            DispatchQueue.main.async { listener.onPaymentEvent(event) }
        }
    }

    public func shouldProceedWithPayment(_ callback: @escaping (String, @escaping (Bool) -> Void) -> Void) {
        self.shouldProceedWithPaymentCallback = callback
    }

    internal func handleShouldProceedWithPayment(payload: String, callback: @escaping (Bool) -> Void) {
        if self.shouldProceedWithPaymentCallback == nil {
            callback(true)
        } else {
            self.shouldProceedWithPaymentCallback?(payload, callback)
        }
    }
}
