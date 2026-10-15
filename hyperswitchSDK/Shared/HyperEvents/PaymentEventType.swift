//
//  PaymentEventType.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 21/04/26.
//

import Foundation

/// Events a merchant can list in `Configuration.subscriptionEvents`; nothing is emitted for the rest.
public enum PaymentEventType: String, CaseIterable, Codable, Sendable {
    case cardDetailsChange
    case paymentMethodChange
    case formStatusChange
    case billingDetailsChange
    case cvcStatusChange
}

/// Delivered to `onChange`; switch on `eventName`, read `data` for the typed payload.
public struct PaymentEvent {
    public let eventName: String
    public let payload: [String: Any]

    public var data: PaymentEventData? {
        PaymentEventData.from(type: eventName, payload: payload)
    }

    public init(eventName: String, payload: [String: Any]) {
        self.eventName = eventName
        self.payload = payload
    }

}

/// Event handlers of one element (or sheet), read when each event arrives. Lifecycle events
/// (`ready`, `focus`, `blur`) never reach `onChange`.
package final class PaymentEventHub {
    package init() {}

    package var onChange: ((PaymentEvent) -> Void)?
    /// `ready` fires once, possibly before a handler is set; a handler set later still runs.
    package var onReady: (() -> Void)? {
        didSet { if readyFired { onReady?() } }
    }
    package var onFocus: (() -> Void)?
    package var onBlur: (() -> Void)?
    private var readyFired = false

    package func dispatch(type: String, payload: [String: Any]) {
        let deliver = { [weak self] in
            guard let self = self else { return }
            switch type {
            case "ready":
                self.readyFired = true
                self.onReady?()
            case "focus": self.onFocus?()
            case "blur": self.onBlur?()
            default:
                let event = PaymentEvent(eventName: type, payload: payload)
                self.onChange?(event)
            }
        }
        if Thread.isMainThread {
            deliver()
        } else {
            DispatchQueue.main.async(execute: deliver)
        }
    }
}
