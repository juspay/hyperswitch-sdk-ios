//
//  VaultStateStore.swift
//  HyperswitchVault
//
//  Latest known state of each mounted vault field (keyed by surface root tag),
//  pushed from JS via HyperVaultModule, consumed by HyperswitchCollect.
//

import Foundation

internal final class VaultStateStore {

    static let shared = VaultStateStore()

    private let lock = NSLock()
    private var states: [NSNumber: VaultFieldState] = [:]
    private var listeners: [NSNumber: (VaultFieldState) -> Void] = [:]

    /*
     * FieldType-keyed channel fed by HyperVaultModule.updateVaultFieldStates:
     * the aggregated, redacted states pushed by the JS vault package. Each
     * native field subscribes by its field type ("card_number", "exp_date",
     * "cvc", ...), so one shared JS runtime can serve several field surfaces
     * while each native view receives only its own field's state.
     */
    private var typeStates: [String: VaultFieldState] = [:]
    private var typeListeners: [String: (VaultFieldState) -> Void] = [:]

    private init() {}

    func update(rootTag: NSNumber, json: String) {
        guard let state = VaultFieldState.parse(json) else { return }
        let callback: ((VaultFieldState) -> Void)? = withLock {
            states[rootTag] = state
            return listeners[rootTag]
        }
        callback?(state)
    }

    func state(for rootTag: NSNumber) -> VaultFieldState? {
        withLock { states[rootTag] }
    }

    func remove(rootTag: NSNumber) {
        withLock {
            states.removeValue(forKey: rootTag)
            listeners.removeValue(forKey: rootTag)
        }
    }

    /// Fires with the current + all future states of the given surface.
    func subscribe(rootTag: NSNumber, onChange: @escaping (VaultFieldState) -> Void) {
        let existing = withLock { () -> VaultFieldState? in
            listeners[rootTag] = onChange
            return states[rootTag]
        }
        if let existing = existing { onChange(existing) }
    }

    // MARK: - FieldType-keyed channel (redacted states from the JS vault package)

    /// Applies one aggregated push ([{fieldType, bin, isEmpty, isValid,
    /// isRequired, isFocused, isTokenized, ...}]). No raw card data.
    func updateFieldStates(_ json: String) {
        guard let data = json.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return }
        for obj in array {
            guard let fieldType = obj["fieldType"] as? String,
                  let state = VaultFieldState.parse(obj)
            else { continue }
            let callback: ((VaultFieldState) -> Void)? = withLock {
                typeStates[fieldType] = state
                return typeListeners[fieldType]
            }
            callback?(state)
        }
    }

    func state(forType fieldType: String) -> VaultFieldState? {
        withLock { typeStates[fieldType] }
    }

    /// Fires with the current + all future states of the given field type.
    func subscribe(fieldType: String, onChange: @escaping (VaultFieldState) -> Void) {
        let existing = withLock { () -> VaultFieldState? in
            typeListeners[fieldType] = onChange
            return typeStates[fieldType]
        }
        if let existing = existing { onChange(existing) }
    }

    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}
