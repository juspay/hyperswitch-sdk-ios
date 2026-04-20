//
//  WidgetResponseRegistry.swift
//  Hyperswitch
//
//  Copyright © 2026 Hyperswitch. All rights reserved.
//

import Foundation

/**
 * WidgetResponseRegistry maintains a mapping of (rootTag, WidgetAction) -> callback
 * for direct dispatch of widget responses without using NotificationCenter.
 *
 * Each rootTag can have multiple handlers, one per WidgetAction. This allows
 * different actions (confirmPayment, paymentEvent, future updateIntent, etc.)
 * to coexist on the same widget with independent callback lifecycles.
 */
internal final class WidgetResponseRegistry {

    internal static let shared = WidgetResponseRegistry()

    /// Closure signature: (response: String, shouldRemoveView: Bool) -> Void
    private var handlers: [NSNumber: [WidgetAction: (NSDictionary, Bool) -> Void]] = [:]
    private let lock = NSLock()

    private init() {}

    /**
     * Register a handler for a specific (rootTag, action) pair.
     * Only one handler per (rootTag, action) — last one wins.
     * Thread-safe: acquires internal lock.
     */
    internal func register(rootTag: NSNumber, action: WidgetAction, handler: @escaping (NSDictionary, Bool) -> Void) {
        lock.lock()
        handlers[rootTag, default: [:]][action] = handler
        lock.unlock()
    }

    /**
     * Unregister a single action handler for a given rootTag.
     * Thread-safe: acquires internal lock.
     */
    internal func unregister(rootTag: NSNumber, action: WidgetAction) {
        lock.lock()
        handlers[rootTag]?.removeValue(forKey: action)
        if handlers[rootTag]?.isEmpty == true {
            handlers.removeValue(forKey: rootTag)
        }
        lock.unlock()
    }

    /**
     * Unregister all handlers for a given rootTag.
     * Should be called when the widget is deallocated.
     * Thread-safe: acquires internal lock.
     */
    internal func unregisterAll(rootTag: NSNumber) {
        lock.lock()
        handlers.removeValue(forKey: rootTag)
        lock.unlock()
    }

    /**
     * Dispatch a response to the handler registered for (rootTag, action).
     *
     * - Parameters:
     *   - rootTag: The React root tag identifying the target widget
     *   - action: The WidgetAction identifying which handler to invoke
     *   - response: The response payload as JSON string
     *   - shouldRemoveView: Whether this response triggers widget cleanup
     *
     * - Returns: true if a handler was found and called, false otherwise
     *
     * The handler is automatically unregistered after dispatch (one-shot semantics).
     * If you need persistent listeners, re-register after dispatch.
     * Thread-safe: acquires internal lock.
     */
    @discardableResult
    internal func dispatch(rootTag: NSNumber, action: WidgetAction, response: NSDictionary, shouldRemoveView: Bool) -> Bool {
        lock.lock()
        let handler = handlers[rootTag]?[action]
        if shouldRemoveView {
            handlers[rootTag]?.removeValue(forKey: action)
        }
        if handlers[rootTag]?.isEmpty == true {
            handlers.removeValue(forKey: rootTag)
        }
        lock.unlock()
        handler?(response, shouldRemoveView)
        return handler != nil
    }
}
