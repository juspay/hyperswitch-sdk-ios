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

/// Delivered to `onChange`; pattern-match on the typed payload for its fields.
public struct PaymentEvent: Sendable {
    public let payload: PaymentEventData
    public var eventName: PaymentEventType {
        switch payload {
        case .cardDetailsChange: return .cardDetailsChange
        case .paymentMethodChange: return .paymentMethodChange
        case .formStatusChange: return .formStatusChange
        case .billingDetailsChange: return .billingDetailsChange
        case .cvcStatusChange: return .cvcStatusChange
        }
    }

    public init(payload: PaymentEventData) {
        self.payload = payload
    }

    package init?(eventName: PaymentEventType, rawPayload: [String: Any]) {
        guard let payload = PaymentEventData.from(type: eventName, payload: rawPayload) else { return nil }
        self.init(payload: payload)
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
                guard let eventName = PaymentEventType(rawValue: type) else { return }
                guard let event = PaymentEvent(eventName: eventName, rawPayload: payload) else { return }
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
