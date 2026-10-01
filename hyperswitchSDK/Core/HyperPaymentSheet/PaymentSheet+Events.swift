//
//  PaymentSheet+Events.swift
//  hyperswitch
//
//  Created by Harshit Srivastava on 07/05/26.
//

import Foundation
import HyperswitchShared

extension PaymentSheet {
    internal func dispatchPaymentEvent(type: String, payload: [String: Any]) {
        events.dispatch(type: type, payload: payload, legacyListener: paymentEventListener)
    }

    public func shouldProceedWithPayment(_ callback: @escaping (PaymentRequestData, @escaping (Bool) -> Void) -> Void) {
        self.shouldProceedWithPaymentCallback = callback
    }

    internal func handleShouldProceedWithPayment(payload: String, callback: @escaping (Bool) -> Void) {
        if self.shouldProceedWithPaymentCallback == nil {
            callback(true)
        } else {
            if let data = payload.data(using: .utf8),
                let paymentRequestData = try? JSONDecoder().decode(PaymentRequestData.self, from: data)
            {
                shouldProceedWithPaymentCallback?(paymentRequestData, callback)
            }
        }
    }
}
