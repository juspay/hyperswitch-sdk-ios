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
}
