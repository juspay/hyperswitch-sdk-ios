//
//  PaymentEventSubscriptionBuilder.swift
//  Hyperswitch
//
//  Created by Harshit Srivastava on 21/04/26.
//

import Foundation

public final class PaymentEventSubscriptionBuilder {
    private var handlers: [PaymentEventType: (PaymentEvent) -> Void] = [:]

    public init() {}

    public func on(_ eventType: PaymentEventType, _ handler: @escaping (PaymentEvent) -> Void) {
        handlers[eventType] = handler
    }

    internal func build() -> (subscription: PaymentEventSubscription, listener: PaymentEventListener) {
        let dispatch: [String: (PaymentEvent) -> Void] = Dictionary(
            uniqueKeysWithValues: handlers.map { ($0.key.rawValue, $0.value) }
        )
        let subscription = PaymentEventSubscription(eventTypes: Array(handlers.keys))
        let listener = PaymentEventListener { event in
            dispatch[event.type]?(event)
        }
        return (subscription, listener)
    }
}

public struct PaymentEventSubscription: Sendable {
    public let eventTypes: [PaymentEventType]

    public func isSubscribed(_ rawType: String) -> Bool {
        eventTypes.contains { $0.rawValue == rawType }
    }

    public func subscribedEventStrings() -> [String] {
        eventTypes.map(\.rawValue)
    }
}

internal struct PaymentEventListener {
    let onPaymentEvent: (PaymentEvent) -> Void
}
