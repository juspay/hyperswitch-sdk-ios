//
//  HyperEventEmitter.swift
//  Hyperswitch
//

import Foundation

internal final class HyperEventEmitter {
    internal static let shared = HyperEventEmitter()

    private let lock = NSLock()
    private var _listener: PaymentEventListener?
    private var _subscription: PaymentEventSubscription?

    private init() {}

    internal func setEventListener(_ listener: PaymentEventListener?, subscription: PaymentEventSubscription?) {
        lock.lock()
        defer { lock.unlock() }
        _listener = listener
        _subscription = subscription
    }

    internal func clear() {
        lock.lock()
        defer { lock.unlock() }
        _listener = nil
        _subscription = nil
    }

    internal func subscribedEvents() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return _subscription?.subscribedEventStrings() ?? []
    }

    internal func emit(eventType: String, payload: [String: Any]) {
        lock.lock()
        let listener = _listener
        let isSubscribed = _subscription?.isSubscribed(eventType) ?? false
        lock.unlock()
        guard isSubscribed, let listener else { return }
        let event = PaymentEvent(type: eventType, payload: payload)
        if Thread.isMainThread {
            listener.onPaymentEvent(event)
        } else {
            DispatchQueue.main.async { listener.onPaymentEvent(event) }
        }
    }
}
