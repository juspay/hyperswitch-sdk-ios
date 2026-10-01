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

    @available(*, deprecated, renamed: "eventName")
    public var type: String { eventName }

    public var data: PaymentEventData? {
        PaymentEventData.from(type: eventName, payload: payload)
    }

    public init(eventName: String, payload: [String: Any]) {
        self.eventName = eventName
        self.payload = payload
    }

    @available(*, deprecated, renamed: "init(eventName:payload:)")
    public init(type: String, payload: [String: Any]) {
        self.init(eventName: type, payload: payload)
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

    /// `legacyListener` backs the deprecated subscribe builder and only sees change events.
    package func dispatch(type: String, payload: [String: Any], legacyListener: PaymentEventListener?) {
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
                legacyListener?.onPaymentEvent(event)
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

package enum SubscribedEvents {
    /* The bundle reads `configuration.subscribedEvents`; `subscriptionEvents`, the legacy
       `subscribedEvents` and the deprecated builder's `extra` all collapse into it. A configuration
       is created when there is none, so a widget built without one still gets its events. */
    package static func normalize(_ configuration: [String: Any]?, adding extra: [String]?) -> [String: Any]? {
        var merged: [String] = []
        for key in ["subscriptionEvents", "subscribedEvents"] {
            for name in configuration?[key] as? [String] ?? [] where !merged.contains(name) {
                merged.append(name)
            }
        }
        for name in extra ?? [] where !merged.contains(name) {
            merged.append(name)
        }
        guard configuration != nil || !merged.isEmpty else { return nil }
        var result = configuration ?? [:]
        result.removeValue(forKey: "subscriptionEvents")
        result["subscribedEvents"] = merged.isEmpty ? nil : merged
        return result
    }
}
